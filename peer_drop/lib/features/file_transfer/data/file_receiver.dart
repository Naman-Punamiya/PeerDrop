import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import '../../../core/logging/app_logger.dart';
import '../../connection/data/message_framing.dart';
import '../../connection/domain/protocol_message.dart';
import '../domain/transfer_state.dart';
import 'filesystem_service.dart';

typedef ReceiverStateCallback = void Function(TransferState state);

class FileReceiver {
  final Socket socket;
  final HandshakeMessage peerInfo;
  final FilesystemService filesystemService;
  final ReceiverStateCallback? onStateChange;

  IncomingFileSession? _session;
  FileTransferRequestPayload? _currentRequest;
  bool _isCancelled = false;
  int _expectedFileSize = 0;
  int _bytesReceived = 0;
  final Stopwatch _stopwatch = Stopwatch();
  DateTime _lastProgressUpdate = DateTime.now();
  Future<void> _messageQueue = Future.value();

  Digest? _computedDigest;
  ChunkedConversionSink<List<int>>? _hashSink;

  FileReceiver({
    required this.socket,
    required this.peerInfo,
    required this.filesystemService,
    this.onStateChange,
  });

  /// Handles incoming protocol message for file reception sequentially
  Future<void> handleMessage(RawProtocolMessage message) {
    final op = _messageQueue.then((_) => _processMessage(message));
    _messageQueue = op;
    return op;
  }

  Future<void> _processMessage(RawProtocolMessage message) async {
    switch (message.type) {
      case MessageType.fileTransferStart:
        _handleTransferStart(message);
        break;

      case MessageType.fileTransferData:
        await _handleTransferData(message);
        break;

      case MessageType.fileTransferComplete:
        await _handleTransferComplete(message);
        break;

      case MessageType.fileTransferCancel:
        await _handleTransferCancel(message);
        break;

      case MessageType.fileTransferError:
        await _handleTransferError(message);
        break;
    }
  }

  /// Called when user accepts the transfer
  Future<void> acceptTransfer(FileTransferRequestPayload request) async {
    _currentRequest = request;
    _expectedFileSize = request.fileSize;
    _bytesReceived = 0;
    _isCancelled = false;
    _stopwatch.reset();

    // Initialize streaming SHA-256 hasher for zero-overhead on-the-fly verification
    _computedDigest = null;
    final outputSink = ChunkedConversionSink<Digest>.withCallback((digests) {
      if (digests.isNotEmpty) {
        _computedDigest = digests.first;
      }
    });
    _hashSink = sha256.startChunkedConversion(outputSink);

    AppLogger.info('Accepting transfer for ${request.filename} from ${peerInfo.deviceName}...', tag: 'FileReceiver');

    try {
      _session = await filesystemService.prepareIncomingFile(request.filename);

      _updateState(TransferState(
        transferId: request.transferId,
        filename: request.filename,
        filePath: _session!.file.path,
        fileSize: request.fileSize,
        bytesTransferred: 0,
        status: TransferStatus.accepted,
        direction: TransferDirection.receive,
        peerDeviceId: peerInfo.deviceId,
        peerDeviceName: peerInfo.deviceName,
        peerPlatform: peerInfo.platform,
        expectedSha256: request.sha256,
        startedAt: DateTime.now(),
      ));

      // Send accept message
      socket.add(MessageSerializer.frameJson(MessageType.fileTransferAccept, {
        'transferId': request.transferId,
      }));
      try {
        await socket.flush();
      } catch (_) {}
    } catch (e, st) {
      AppLogger.error('Failed to accept transfer', tag: 'FileReceiver', error: e, stackTrace: st);
      rejectTransfer(request, reason: 'Storage error: $e');
    }
  }

  /// Called when user rejects the transfer
  void rejectTransfer(FileTransferRequestPayload request, {String? reason}) {
    AppLogger.info('Rejecting transfer for ${request.filename} from ${peerInfo.deviceName}', tag: 'FileReceiver');

    try {
      _hashSink?.close();
    } catch (_) {}

    try {
      socket.add(MessageSerializer.frameJson(MessageType.fileTransferReject, {
        'transferId': request.transferId,
        'reason': reason ?? 'User rejected the transfer',
      }));
      socket.flush();
    } catch (_) {}

    _updateState(TransferState(
      transferId: request.transferId,
      filename: request.filename,
      fileSize: request.fileSize,
      status: TransferStatus.rejected,
      direction: TransferDirection.receive,
      peerDeviceId: peerInfo.deviceId,
      peerDeviceName: peerInfo.deviceName,
      peerPlatform: peerInfo.platform,
      errorMessage: reason,
      completedAt: DateTime.now(),
    ));
  }

  void _handleTransferStart(RawProtocolMessage msg) {
    _stopwatch.start();
    _lastProgressUpdate = DateTime.now();

    if (_currentRequest != null && _session != null) {
      _updateState(TransferState(
        transferId: _currentRequest!.transferId,
        filename: _currentRequest!.filename,
        filePath: _session!.file.path,
        fileSize: _expectedFileSize,
        bytesTransferred: 0,
        status: TransferStatus.transferring,
        direction: TransferDirection.receive,
        peerDeviceId: peerInfo.deviceId,
        peerDeviceName: peerInfo.deviceName,
        peerPlatform: peerInfo.platform,
        expectedSha256: _currentRequest!.sha256,
        startedAt: DateTime.now(),
      ));
    }
  }

  Future<void> _handleTransferData(RawProtocolMessage msg) async {
    if (_session == null || _isCancelled) return;

    final chunk = FileChunkData.decode(msg.payload);
    if (chunk == null) {
      AppLogger.warning('Received malformed chunk data payload', tag: 'FileReceiver');
      return;
    }

    if (chunk.transferId != _currentRequest?.transferId) {
      AppLogger.warning('Received chunk for unknown transfer ID: ${chunk.transferId}', tag: 'FileReceiver');
      return;
    }

    // Stream hash on-the-fly
    _hashSink?.add(chunk.data);

    await _session!.writeChunk(chunk.data);
    _bytesReceived += chunk.data.length;

    final now = DateTime.now();
    if (now.difference(_lastProgressUpdate).inMilliseconds >= 100 || _bytesReceived >= _expectedFileSize) {
      _lastProgressUpdate = now;
      final elapsedSeconds = _stopwatch.elapsedMilliseconds / 1000.0;
      final speed = elapsedSeconds > 0 ? (_bytesReceived / elapsedSeconds) : 0.0;

      _updateState(TransferState(
        transferId: _currentRequest!.transferId,
        filename: _currentRequest!.filename,
        filePath: _session!.file.path,
        fileSize: _expectedFileSize,
        bytesTransferred: _bytesReceived,
        speedBytesPerSecond: speed,
        status: TransferStatus.transferring,
        direction: TransferDirection.receive,
        peerDeviceId: peerInfo.deviceId,
        peerDeviceName: peerInfo.deviceName,
        peerPlatform: peerInfo.platform,
        expectedSha256: _currentRequest!.sha256,
        startedAt: DateTime.now(),
      ));

      // Yield to Dart event loop so Flutter UI paints at 60 FPS without frame drops
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> _handleTransferComplete(RawProtocolMessage msg) async {
    if (_session == null || _currentRequest == null || _isCancelled) return;

    AppLogger.info('Received FILE_TRANSFER_COMPLETE. Verifying SHA-256 for ${_currentRequest!.filename}...', tag: 'FileReceiver');

    _updateState(TransferState(
      transferId: _currentRequest!.transferId,
      filename: _currentRequest!.filename,
      filePath: _session!.file.path,
      fileSize: _expectedFileSize,
      bytesTransferred: _bytesReceived,
      status: TransferStatus.verifying,
      direction: TransferDirection.receive,
      peerDeviceId: peerInfo.deviceId,
      peerDeviceName: peerInfo.deviceName,
      peerPlatform: peerInfo.platform,
      expectedSha256: _currentRequest!.sha256,
    ));

    // Yield so the verifying UI state renders immediately
    await Future<void>.delayed(Duration.zero);

    try {
      await _session!.close();

      // Finalize on-the-fly hash instantly without disk re-reading
      _hashSink?.close();
      final actualSha256 = _computedDigest?.toString() ?? '';
      final json = msg.payloadAsJson;
      final expectedSha256 = (json?['sha256'] as String?)?.isNotEmpty == true
          ? json!['sha256'] as String
          : _currentRequest!.sha256;

      if (expectedSha256.isEmpty || actualSha256.toLowerCase() == expectedSha256.toLowerCase()) {
        AppLogger.info('SHA-256 verified instantly! File: ${_session!.file.path}', tag: 'FileReceiver');

        // Send ACK back to sender before marking completed
        try {
          socket.add(MessageSerializer.frameJson(MessageType.fileTransferCompleteAck, {
            'transferId': _currentRequest!.transferId,
            'status': 'ok',
          }));
          await socket.flush();
        } catch (e) {
          AppLogger.warning('Failed to send complete ACK to sender: $e', tag: 'FileReceiver');
        }

        _updateState(TransferState(
          transferId: _currentRequest!.transferId,
          filename: _currentRequest!.filename,
          filePath: _session!.file.path,
          fileSize: _expectedFileSize,
          bytesTransferred: _expectedFileSize,
          status: TransferStatus.completed,
          direction: TransferDirection.receive,
          peerDeviceId: peerInfo.deviceId,
          peerDeviceName: peerInfo.deviceName,
          peerPlatform: peerInfo.platform,
          expectedSha256: expectedSha256,
          actualSha256: actualSha256,
          completedAt: DateTime.now(),
        ));
      } else {
        AppLogger.error('SHA-256 checksum mismatch! Expected $expectedSha256, got $actualSha256', tag: 'FileReceiver');
        await _session!.abortAndCleanup();

        // Notify sender of checksum error
        try {
          socket.add(MessageSerializer.frameJson(MessageType.fileTransferError, {
            'transferId': _currentRequest!.transferId,
            'error': 'Checksum verification failed',
          }));
          await socket.flush();
        } catch (_) {}

        _updateState(TransferState(
          transferId: _currentRequest!.transferId,
          filename: _currentRequest!.filename,
          fileSize: _expectedFileSize,
          bytesTransferred: _bytesReceived,
          status: TransferStatus.failed,
          direction: TransferDirection.receive,
          peerDeviceId: peerInfo.deviceId,
          peerDeviceName: peerInfo.deviceName,
          peerPlatform: peerInfo.platform,
          expectedSha256: expectedSha256,
          actualSha256: actualSha256,
          errorMessage: 'Checksum verification failed (SHA-256 mismatch)',
          completedAt: DateTime.now(),
        ));
      }
    } catch (e, st) {
      AppLogger.error('Error during file completion verification', tag: 'FileReceiver', error: e, stackTrace: st);
      await _session?.abortAndCleanup();

      try {
        socket.add(MessageSerializer.frameJson(MessageType.fileTransferError, {
          'transferId': _currentRequest?.transferId ?? '',
          'error': 'Verification error: $e',
        }));
        await socket.flush();
      } catch (_) {}

      _updateState(TransferState(
        transferId: _currentRequest?.transferId,
        filename: _currentRequest?.filename,
        fileSize: _expectedFileSize,
        status: TransferStatus.failed,
        direction: TransferDirection.receive,
        peerDeviceId: peerInfo.deviceId,
        peerDeviceName: peerInfo.deviceName,
        peerPlatform: peerInfo.platform,
        errorMessage: 'Verification failed: $e',
        completedAt: DateTime.now(),
      ));
    }
  }

  Future<void> cancel() async {
    if (_isCancelled) return;
    _isCancelled = true;

    AppLogger.info('Receiver cancelling transfer', tag: 'FileReceiver');

    if (_currentRequest != null) {
      try {
        socket.add(MessageSerializer.frameJson(MessageType.fileTransferCancel, {
          'transferId': _currentRequest!.transferId,
        }));
      } catch (_) {}
    }

    await _session?.abortAndCleanup();

    _updateState(TransferState(
      transferId: _currentRequest?.transferId,
      filename: _currentRequest?.filename,
      fileSize: _expectedFileSize,
      status: TransferStatus.cancelled,
      direction: TransferDirection.receive,
      peerDeviceId: peerInfo.deviceId,
      peerDeviceName: peerInfo.deviceName,
      peerPlatform: peerInfo.platform,
      completedAt: DateTime.now(),
    ));
  }

  Future<void> _handleTransferCancel(RawProtocolMessage msg) async {
    _isCancelled = true;
    AppLogger.info('Sender cancelled the transfer', tag: 'FileReceiver');
    await _session?.abortAndCleanup();

    _updateState(TransferState(
      transferId: _currentRequest?.transferId,
      filename: _currentRequest?.filename,
      fileSize: _expectedFileSize,
      status: TransferStatus.cancelled,
      direction: TransferDirection.receive,
      peerDeviceId: peerInfo.deviceId,
      peerDeviceName: peerInfo.deviceName,
      peerPlatform: peerInfo.platform,
      errorMessage: 'Cancelled by sender',
      completedAt: DateTime.now(),
    ));
  }

  Future<void> _handleTransferError(RawProtocolMessage msg) async {
    final json = msg.payloadAsJson;
    final error = json?['error'] as String? ?? 'Remote error occurred';
    AppLogger.error('Remote error during transfer: $error', tag: 'FileReceiver');
    await _session?.abortAndCleanup();

    _updateState(TransferState(
      transferId: _currentRequest?.transferId,
      filename: _currentRequest?.filename,
      fileSize: _expectedFileSize,
      status: TransferStatus.failed,
      direction: TransferDirection.receive,
      peerDeviceId: peerInfo.deviceId,
      peerDeviceName: peerInfo.deviceName,
      peerPlatform: peerInfo.platform,
      errorMessage: error,
      completedAt: DateTime.now(),
    ));
  }

  void _updateState(TransferState state) {
    onStateChange?.call(state);
  }
}
