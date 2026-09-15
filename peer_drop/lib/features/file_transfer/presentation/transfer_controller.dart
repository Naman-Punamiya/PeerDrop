import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/network_utils.dart';
import '../../connection/data/tcp_client.dart';
import '../../connection/data/tcp_server.dart';
import '../../connection/domain/protocol_message.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../discovery/domain/peer_device.dart';
import '../../history/domain/transfer_record.dart';
import '../../history/presentation/history_controller.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/file_receiver.dart';
import '../data/file_sender.dart';
import '../data/filesystem_service.dart';
import '../domain/transfer_metadata.dart';
import '../domain/transfer_state.dart';

final filesystemServiceProvider = Provider<FilesystemService>((ref) {
  final settingsAsync = ref.watch(settingsControllerProvider);
  final downloadDir = settingsAsync.valueOrNull?.downloadDirectory ?? '';
  return FilesystemService(downloadDirectory: downloadDir);
});

final incomingRequestProvider = StateProvider<FileTransferRequestPayload?>((ref) => null);
final incomingSocketProvider = StateProvider<Socket?>((ref) => null);
final incomingPeerProvider = StateProvider<HandshakeMessage?>((ref) => null);

final transferControllerProvider = StateNotifierProvider<TransferController, TransferState>((ref) {
  final tcpServer = ref.watch(tcpServerProvider);
  final filesystem = ref.watch(filesystemServiceProvider);
  final historyController = ref.watch(historyControllerProvider.notifier);
  final settings = ref.watch(settingsControllerProvider).valueOrNull;

  final controller = TransferController(
    ref: ref,
    filesystemService: filesystem,
    historyController: historyController,
    localDeviceId: settings?.deviceId ?? '',
    localDeviceName: settings?.deviceName ?? '',
  );

  if (tcpServer != null) {
    controller.bindServer(tcpServer);
  }

  return controller;
});

class TransferController extends StateNotifier<TransferState> {
  final Ref ref;
  final FilesystemService filesystemService;
  final HistoryController historyController;
  final String localDeviceId;
  final String localDeviceName;

  FileSender? _activeSender;
  FileReceiver? _activeReceiver;
  TcpClient? _activeClient;

  TransferController({
    required this.ref,
    required this.filesystemService,
    required this.historyController,
    required this.localDeviceId,
    required this.localDeviceName,
  }) : super(TransferState.idleState);

  void bindServer(TcpServer server) {
    server.onMessageReceived = _handleServerMessage;
    server.onPeerDisconnected = (socket, deviceId) {
      if (state.isActive && state.direction == TransferDirection.receive) {
        // Only cancel if transfer was still transferring or requesting chunks.
        // If it is verifying or completed, let the verification finish!
        if (state.status == TransferStatus.transferring || state.status == TransferStatus.requesting) {
          _activeReceiver?.cancel();
        }
      }
    };
  }

  /// Handles incoming messages received by local TCP Server
  void _handleServerMessage(
    Socket socket,
    HandshakeMessage peerInfo,
    RawProtocolMessage message,
  ) {
    if (message.type == MessageType.fileTransferRequest) {
      final json = message.payloadAsJson;
      if (json != null) {
        final request = FileTransferRequestPayload.fromJson(json);
        if (request != null) {
          AppLogger.info('Incoming file request: ${request.filename} (${request.fileSize} bytes) from ${peerInfo.deviceName}', tag: 'TransferController');

          // Initialize receiver
          _activeReceiver = FileReceiver(
            socket: socket,
            peerInfo: peerInfo,
            filesystemService: filesystemService,
            onStateChange: _handleReceiverStateChange,
          );

          // Update UI for incoming prompt
          ref.read(incomingRequestProvider.notifier).state = request;
          ref.read(incomingSocketProvider.notifier).state = socket;
          ref.read(incomingPeerProvider.notifier).state = peerInfo;

          state = TransferState(
            transferId: request.transferId,
            filename: request.filename,
            fileSize: request.fileSize,
            status: TransferStatus.waitingForAcceptance,
            direction: TransferDirection.receive,
            peerDeviceId: peerInfo.deviceId,
            peerDeviceName: peerInfo.deviceName,
            peerPlatform: peerInfo.platform,
            expectedSha256: request.sha256,
            startedAt: DateTime.now(),
          );
        }
      }
      return;
    }

    // Pass data / completion messages to active receiver
    _activeReceiver?.handleMessage(message);
  }

  /// Accept incoming file transfer
  Future<void> acceptIncomingTransfer() async {
    final request = ref.read(incomingRequestProvider);
    if (request == null || _activeReceiver == null) return;

    // Clear incoming modal state
    ref.read(incomingRequestProvider.notifier).state = null;

    await _activeReceiver!.acceptTransfer(request);
  }

  /// Reject incoming file transfer
  void rejectIncomingTransfer([String? reason]) {
    final request = ref.read(incomingRequestProvider);
    if (request != null && _activeReceiver != null) {
      _activeReceiver!.rejectTransfer(request, reason: reason);
    }

    ref.read(incomingRequestProvider.notifier).state = null;
    ref.read(incomingSocketProvider.notifier).state = null;
    ref.read(incomingPeerProvider.notifier).state = null;
  }

  /// Sends a selected file to a target peer
  Future<void> sendFile({
    required PeerDevice peer,
    required TransferFileMetadata metadata,
  }) async {
    if (state.isActive) {
      throw const TransferException('A transfer is already active');
    }

    try {
      _activeClient?.dispose();
      _activeClient = TcpClient(
        remoteIp: peer.ipAddress,
        remotePort: peer.tcpPort,
        localDeviceId: localDeviceId,
        localDeviceName: localDeviceName,
        platform: NetworkUtils.getPlatformName(),
      );

      state = TransferState(
        filename: metadata.name,
        filePath: metadata.path,
        fileSize: metadata.size,
        status: TransferStatus.requesting,
        direction: TransferDirection.send,
        peerDeviceId: peer.deviceId,
        peerDeviceName: peer.deviceName,
        peerPlatform: peer.platform,
        startedAt: DateTime.now(),
      );

      // Connect and handshake
      await _activeClient!.connect();

      _activeSender = FileSender(
        client: _activeClient!,
        metadata: metadata,
        localDeviceId: localDeviceId,
        localDeviceName: localDeviceName,
        onStateChange: _handleSenderStateChange,
      );

      await _activeSender!.startTransfer();
    } catch (e, st) {
      AppLogger.error('Failed to send file', tag: 'TransferController', error: e, stackTrace: st);
      state = state.copyWith(
        status: TransferStatus.failed,
        errorMessage: e.toString(),
        completedAt: DateTime.now(),
      );
      _recordHistory(state);
    }
  }

  /// Cancel current transfer (sender or receiver)
  void cancelCurrentTransfer() {
    if (_activeSender != null) {
      _activeSender!.cancel();
    } else if (_activeReceiver != null) {
      _activeReceiver!.cancel();
    }
  }

  void _handleSenderStateChange(TransferState newState) {
    state = newState;
    if (newState.isCompleted || newState.isFailed || newState.isCancelled || newState.isRejected) {
      _recordHistory(newState);
      _cleanupSender();
    }
  }

  void _handleReceiverStateChange(TransferState newState) {
    state = newState;
    if (newState.isCompleted || newState.isFailed || newState.isCancelled || newState.isRejected) {
      _recordHistory(newState);
      _cleanupReceiver();
    }
  }

  void _recordHistory(TransferState finalState) {
    if (finalState.filename == null) return;
    final record = TransferRecord.fromTransferState(finalState);
    historyController.addRecord(record);
  }

  void _cleanupSender() {
    _activeSender = null;
    _activeClient?.dispose();
    _activeClient = null;
  }

  void _cleanupReceiver({bool isDisposing = false}) {
    _activeReceiver = null;
    if (!isDisposing) {
      try {
        ref.read(incomingRequestProvider.notifier).state = null;
        ref.read(incomingSocketProvider.notifier).state = null;
        ref.read(incomingPeerProvider.notifier).state = null;
      } catch (_) {}
    }
  }

  void resetToIdle() {
    state = TransferState.idleState;
  }

  @override
  void dispose() {
    _cleanupSender();
    _cleanupReceiver(isDisposing: true);
    super.dispose();
  }
}
