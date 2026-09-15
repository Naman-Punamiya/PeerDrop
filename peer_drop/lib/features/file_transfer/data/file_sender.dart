import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/file_utils.dart';
import '../../connection/data/message_framing.dart';
import '../../connection/data/tcp_client.dart';
import '../../connection/domain/protocol_message.dart';
import '../domain/transfer_metadata.dart';
import '../domain/transfer_state.dart';

typedef ProgressCallback = void Function(
  int bytesSent,
  int totalBytes,
  double speedBytesPerSecond,
);

typedef StateCallback = void Function(TransferState state);

class FileSender {
  final TcpClient client;
  final TransferFileMetadata metadata;
  final String localDeviceId;
  final String localDeviceName;
  final ProgressCallback? onProgress;
  final StateCallback? onStateChange;

  bool _isCancelled = false;
  String? _transferId;

  FileSender({
    required this.client,
    required this.metadata,
    required this.localDeviceId,
    required this.localDeviceName,
    this.onProgress,
    this.onStateChange,
  });

  /// Executes the full sender lifecycle.
  Future<void> startTransfer() async {
    _isCancelled = false;
    _transferId = const Uuid().v4();
    final file = File(metadata.path);

    if (!await file.exists()) {
      throw TransferException('File does not exist: ${metadata.path}');
    }

    final fileSize = await file.length();
    if (fileSize <= 0) {
      throw const TransferException('File is empty (0 bytes). PeerDrop transfers non-empty files.');
    }

    AppLogger.info('Starting transfer for ${metadata.name} ($fileSize bytes)...', tag: 'FileSender');

    _updateState(TransferState(
      transferId: _transferId,
      filename: metadata.name,
      filePath: metadata.path,
      fileSize: fileSize,
      bytesTransferred: 0,
      status: TransferStatus.requesting,
      direction: TransferDirection.send,
      peerDeviceId: client.remotePeerInfo?.deviceId,
      peerDeviceName: client.remotePeerInfo?.deviceName,
      peerPlatform: client.remotePeerInfo?.platform,
      startedAt: DateTime.now(),
    ));

    // 1. Calculate SHA-256
    AppLogger.info('Calculating SHA-256 for ${metadata.name}...', tag: 'FileSender');
    final sha256Hash = await FileUtils.calculateSha256(file);
    if (_isCancelled) return;

    // 2. Set up peer response listener BEFORE sending request to prevent missing early response
    final responseCompleter = Completer<bool>();
    StreamSubscription<RawProtocolMessage>? sub;

    sub = client.messageStream.listen((msg) {
      if (msg.type == MessageType.fileTransferAccept) {
        final json = msg.payloadAsJson;
        if (json?['transferId'] == _transferId) {
          if (!responseCompleter.isCompleted) {
            responseCompleter.complete(true);
          }
        }
      } else if (msg.type == MessageType.fileTransferReject) {
        final json = msg.payloadAsJson;
        if (json?['transferId'] == _transferId) {
          if (!responseCompleter.isCompleted) {
            responseCompleter.complete(false);
          }
        }
      } else if (msg.type == MessageType.fileTransferCancel) {
        final json = msg.payloadAsJson;
        if (json?['transferId'] == _transferId) {
          if (!responseCompleter.isCompleted) {
            responseCompleter.completeError(const TransferException('Transfer was cancelled by receiver'));
          }
        }
      }
    });

    // 3. Send Transfer Request
    final request = FileTransferRequestPayload(
      transferId: _transferId!,
      filename: metadata.name,
      fileSize: fileSize,
      mimeType: metadata.mimeType,
      sha256: sha256Hash,
      senderDeviceId: localDeviceId,
      senderDeviceName: localDeviceName,
    );

    client.sendJson(MessageType.fileTransferRequest, request.toJson());
    AppLogger.info('Sent file transfer request for ${metadata.name}', tag: 'FileSender');

    _updateState(TransferState(
      transferId: _transferId,
      filename: metadata.name,
      filePath: metadata.path,
      fileSize: fileSize,
      bytesTransferred: 0,
      status: TransferStatus.waitingForAcceptance,
      direction: TransferDirection.send,
      peerDeviceId: client.remotePeerInfo?.deviceId,
      peerDeviceName: client.remotePeerInfo?.deviceName,
      peerPlatform: client.remotePeerInfo?.platform,
      expectedSha256: sha256Hash,
      startedAt: DateTime.now(),
    ));

    // 4. Await peer response (Accept, Reject, Cancel)
    try {
      final accepted = await responseCompleter.future.timeout(
        AppConstants.transferRequestTimeout,
        onTimeout: () {
          throw const TransferException('Transfer request timed out waiting for receiver approval');
        },
      );

      if (!accepted) {
        AppLogger.info('Transfer rejected by receiver', tag: 'FileSender');
        _updateState(TransferState(
          transferId: _transferId,
          filename: metadata.name,
          filePath: metadata.path,
          fileSize: fileSize,
          bytesTransferred: 0,
          status: TransferStatus.rejected,
          direction: TransferDirection.send,
          peerDeviceId: client.remotePeerInfo?.deviceId,
          peerDeviceName: client.remotePeerInfo?.deviceName,
          peerPlatform: client.remotePeerInfo?.platform,
          expectedSha256: sha256Hash,
          completedAt: DateTime.now(),
        ));
        return;
      }

      // 4. Receiver accepted, start streaming
      AppLogger.info('Transfer accepted! Starting chunk streaming for ${metadata.name}', tag: 'FileSender');
      _updateState(TransferState(
        transferId: _transferId,
        filename: metadata.name,
        filePath: metadata.path,
        fileSize: fileSize,
        bytesTransferred: 0,
        status: TransferStatus.transferring,
        direction: TransferDirection.send,
        peerDeviceId: client.remotePeerInfo?.deviceId,
        peerDeviceName: client.remotePeerInfo?.deviceName,
        peerPlatform: client.remotePeerInfo?.platform,
        expectedSha256: sha256Hash,
        startedAt: DateTime.now(),
      ));

      await _streamFileChunks(file, fileSize, sha256Hash);
    } finally {
      await sub.cancel();
    }
  }

  /// Streams file in 64 KB chunks over TCP
  Future<void> _streamFileChunks(File file, int fileSize, String sha256Hash) async {
    final raf = await file.open(mode: FileMode.read);
    int sequenceNumber = 0;
    int bytesSent = 0;
    final stopwatch = Stopwatch()..start();

    // Signal transfer start
    client.sendJson(MessageType.fileTransferStart, {'transferId': _transferId});

    final buffer = Uint8List(AppConstants.defaultChunkSize);
    DateTime lastProgressUpdate = DateTime.now();

    try {
      while (bytesSent < fileSize && !_isCancelled) {
        final bytesRead = await raf.readInto(buffer);
        if (bytesRead <= 0) break;

        final chunkData = FileChunkData(
          transferId: _transferId!,
          sequenceNumber: sequenceNumber++,
          data: Uint8List.sublistView(buffer, 0, bytesRead),
        );

        final framedData = MessageSerializer.frame(
          MessageType.fileTransferData,
          chunkData.encode(),
        );

        client.send(framedData);
        bytesSent += bytesRead;

        final now = DateTime.now();
        if (now.difference(lastProgressUpdate).inMilliseconds >= 100 || bytesSent == fileSize) {
          lastProgressUpdate = now;
          final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000.0;
          final speed = elapsedSeconds > 0 ? (bytesSent / elapsedSeconds) : 0.0;

          onProgress?.call(bytesSent, fileSize, speed);
          _updateState(TransferState(
            transferId: _transferId,
            filename: metadata.name,
            filePath: metadata.path,
            fileSize: fileSize,
            bytesTransferred: bytesSent,
            speedBytesPerSecond: speed,
            status: TransferStatus.transferring,
            direction: TransferDirection.send,
            peerDeviceId: client.remotePeerInfo?.deviceId,
            peerDeviceName: client.remotePeerInfo?.deviceName,
            peerPlatform: client.remotePeerInfo?.platform,
            expectedSha256: sha256Hash,
            startedAt: DateTime.now(),
          ));
        }

        // Always yield to the Flutter UI event loop so UI stays completely smooth and responsive
        await Future.delayed(Duration.zero);
      }

      if (_isCancelled) {
        AppLogger.info('Transfer cancelled during streaming', tag: 'FileSender');
        client.sendJson(MessageType.fileTransferCancel, {'transferId': _transferId});
        _updateState(TransferState(
          transferId: _transferId,
          filename: metadata.name,
          filePath: metadata.path,
          fileSize: fileSize,
          bytesTransferred: bytesSent,
          status: TransferStatus.cancelled,
          direction: TransferDirection.send,
          peerDeviceId: client.remotePeerInfo?.deviceId,
          peerDeviceName: client.remotePeerInfo?.deviceName,
          peerPlatform: client.remotePeerInfo?.platform,
          completedAt: DateTime.now(),
        ));
        return;
      }

      // Flush socket and send completion message
      await client.flush();
      client.sendJson(MessageType.fileTransferComplete, {
        'transferId': _transferId,
        'sha256': sha256Hash,
      });

      _updateState(TransferState(
        transferId: _transferId,
        filename: metadata.name,
        filePath: metadata.path,
        fileSize: fileSize,
        bytesTransferred: fileSize,
        status: TransferStatus.verifying,
        direction: TransferDirection.send,
        peerDeviceId: client.remotePeerInfo?.deviceId,
        peerDeviceName: client.remotePeerInfo?.deviceName,
        peerPlatform: client.remotePeerInfo?.platform,
        expectedSha256: sha256Hash,
      ));

      AppLogger.info('Sent FILE_TRANSFER_COMPLETE for ${metadata.name}, awaiting receiver verification ACK...', tag: 'FileSender');

      // Await completion ACK from receiver
      final completeCompleter = Completer<bool>();
      final completeSub = client.messageStream.listen((msg) {
        if (msg.type == MessageType.fileTransferCompleteAck) {
          final json = msg.payloadAsJson;
          if (json?['transferId'] == _transferId) {
            if (!completeCompleter.isCompleted) {
              completeCompleter.complete(true);
            }
          }
        } else if (msg.type == MessageType.fileTransferError) {
          final json = msg.payloadAsJson;
          if (json?['transferId'] == _transferId) {
            if (!completeCompleter.isCompleted) {
              completeCompleter.completeError(TransferException(json?['error'] as String? ?? 'Receiver reported verification error'));
            }
          }
        } else if (msg.type == MessageType.fileTransferCancel) {
          final json = msg.payloadAsJson;
          if (json?['transferId'] == _transferId) {
            if (!completeCompleter.isCompleted) {
              completeCompleter.completeError(const TransferException('Receiver cancelled transfer during verification'));
            }
          }
        }
      });

      try {
        await completeCompleter.future.timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw const TransferException('Timed out waiting for receiver verification acknowledgment');
          },
        );

        _updateState(TransferState(
          transferId: _transferId,
          filename: metadata.name,
          filePath: metadata.path,
          fileSize: fileSize,
          bytesTransferred: fileSize,
          status: TransferStatus.completed,
          direction: TransferDirection.send,
          peerDeviceId: client.remotePeerInfo?.deviceId,
          peerDeviceName: client.remotePeerInfo?.deviceName,
          peerPlatform: client.remotePeerInfo?.platform,
          expectedSha256: sha256Hash,
          actualSha256: sha256Hash,
          completedAt: DateTime.now(),
        ));

        // Yield slightly so OS network stack finishes before socket close
        await Future.delayed(const Duration(milliseconds: 100));

        AppLogger.info('Transfer completed successfully and acknowledged by receiver for ${metadata.name}!', tag: 'FileSender');
      } finally {
        await completeSub.cancel();
      }
    } finally {
      try {
        await raf.close();
      } catch (_) {}
    }
  }

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    if (_transferId != null) {
      try {
        client.sendJson(MessageType.fileTransferCancel, {'transferId': _transferId});
      } catch (_) {}
    }
    _updateState(TransferState(
      transferId: _transferId,
      filename: metadata.name,
      filePath: metadata.path,
      fileSize: metadata.size,
      status: TransferStatus.cancelled,
      direction: TransferDirection.send,
      peerDeviceId: client.remotePeerInfo?.deviceId,
      peerDeviceName: client.remotePeerInfo?.deviceName,
      peerPlatform: client.remotePeerInfo?.platform,
      completedAt: DateTime.now(),
    ));
  }

  void _updateState(TransferState state) {
    onStateChange?.call(state);
  }
}
