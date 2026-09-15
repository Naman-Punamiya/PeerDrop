import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/protocol_message.dart';
import 'message_framing.dart';

class TcpClient {
  final String remoteIp;
  final int remotePort;
  final String localDeviceId;
  final String localDeviceName;
  final String platform;

  Socket? _socket;
  StreamSubscription<Uint8List>? _subscription;
  final MessageFramer _framer = MessageFramer();

  final _messageController = StreamController<RawProtocolMessage>.broadcast();
  Stream<RawProtocolMessage> get messageStream => _messageController.stream;

  HandshakeMessage? _remotePeerInfo;
  HandshakeMessage? get remotePeerInfo => _remotePeerInfo;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  TcpClient({
    required this.remoteIp,
    required this.remotePort,
    required this.localDeviceId,
    required this.localDeviceName,
    required this.platform,
  });

  /// Connects to the remote peer and completes the handshake.
  Future<HandshakeMessage> connect() async {
    if (_isConnected && _socket != null) {
      if (_remotePeerInfo != null) return _remotePeerInfo!;
    }

    AppLogger.info('Connecting to TCP peer at $remoteIp:$remotePort...', tag: 'TcpClient');

    try {
      _socket = await Socket.connect(
        remoteIp,
        remotePort,
        timeout: AppConstants.connectionTimeout,
      );
      try {
        _socket!.setOption(SocketOption.tcpNoDelay, true);
      } catch (_) {}

      final completer = Completer<HandshakeMessage>();
      _framer.reset();

      _subscription = _socket!.listen(
        (data) {
          try {
            final messages = _framer.processBytes(Uint8List.fromList(data));
            for (final msg in messages) {
              if (!completer.isCompleted) {
                if (msg.type == MessageType.helloAck) {
                  final json = msg.payloadAsJson;
                  if (json != null) {
                    final handshake = HandshakeMessage.fromJson(json);
                    if (handshake != null) {
                      _remotePeerInfo = handshake;
                      _isConnected = true;
                      AppLogger.info('Connected to peer: ${handshake.deviceName} (${handshake.platform})', tag: 'TcpClient');
                      completer.complete(handshake);
                      continue;
                    }
                  }
                  completer.completeError(const HandshakeException('Invalid HELLO_ACK received from peer'));
                  disconnect();
                  return;
                } else {
                  completer.completeError(const HandshakeException('Expected HELLO_ACK but received different message type'));
                  disconnect();
                  return;
                }
              }

              // After handshake, route all messages to the stream
              if (!_messageController.isClosed) {
                _messageController.add(msg);
              }
            }
          } catch (e, st) {
            AppLogger.error('Error in TCP client data processing', tag: 'TcpClient', error: e, stackTrace: st);
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
            disconnect();
          }
        },
        onError: (err) {
          AppLogger.warning('TCP Client connection error: $err', tag: 'TcpClient');
          if (!completer.isCompleted) {
            completer.completeError(ConnectionException('TCP Client socket error: $err'));
          }
          disconnect();
        },
        onDone: () {
          AppLogger.info('TCP Client socket closed by peer', tag: 'TcpClient');
          if (!completer.isCompleted) {
            completer.completeError(const ConnectionException('TCP Connection closed before handshake finished'));
          }
          disconnect();
        },
        cancelOnError: true,
      );

      // Send local HELLO handshake
      final hello = HandshakeMessage(
        deviceId: localDeviceId,
        deviceName: localDeviceName,
        platform: platform,
      );
      sendJson(MessageType.hello, hello.toJson());

      // Timeout guard for handshake
      return await completer.future.timeout(
        AppConstants.handshakeTimeout,
        onTimeout: () {
          disconnect();
          throw const HandshakeException('Handshake timed out waiting for HELLO_ACK');
        },
      );
    } catch (e, st) {
      AppLogger.error('Failed to connect to $remoteIp:$remotePort', tag: 'TcpClient', error: e, stackTrace: st);
      disconnect();
      if (e is AppException) rethrow;
      throw ConnectionException('Connection failed: $e', e);
    }
  }

  void send(Uint8List framedData) {
    if (_socket == null) {
      throw const ConnectionException('Cannot send data: socket is not connected');
    }
    _socket!.add(framedData);
  }

  void sendJson(int messageType, Map<String, dynamic> json) {
    send(MessageSerializer.frameJson(messageType, json));
    flush();
  }

  void sendEmpty(int messageType) {
    send(MessageSerializer.frameEmpty(messageType));
    flush();
  }

  Future<void> flush() async {
    try {
      await _socket?.flush();
    } catch (_) {}
  }

  void disconnect() {
    _isConnected = false;
    _subscription?.cancel();
    _subscription = null;
    try {
      _socket?.destroy();
      _socket = null;
    } catch (_) {}
    _remotePeerInfo = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
