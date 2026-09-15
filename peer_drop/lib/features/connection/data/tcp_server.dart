import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/protocol_message.dart';
import 'message_framing.dart';

typedef ServerMessageHandler = void Function(
  Socket socket,
  HandshakeMessage peerInfo,
  RawProtocolMessage message,
);

typedef ServerConnectionHandler = void Function(
  Socket socket,
  HandshakeMessage peerInfo,
);

typedef ServerDisconnectionHandler = void Function(
  Socket socket,
  String? peerDeviceId,
);

class TcpServer {
  final int port;
  final String localDeviceId;
  final String localDeviceName;
  final String platform;

  ServerSocket? _serverSocket;
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  final Map<Socket, _PeerConnection> _activeConnections = {};

  ServerMessageHandler? onMessageReceived;
  ServerConnectionHandler? onPeerConnected;
  ServerDisconnectionHandler? onPeerDisconnected;

  TcpServer({
    required this.port,
    required this.localDeviceId,
    required this.localDeviceName,
    required this.platform,
    this.onMessageReceived,
    this.onPeerConnected,
    this.onPeerDisconnected,
  });

  Future<void> start() async {
    if (_isRunning) return;

    try {
      _serverSocket = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        port,
        shared: false,
      );
      _isRunning = true;
      AppLogger.info('TCP Server listening on port $port', tag: 'TcpServer');

      _serverSocket!.listen(
        _handleIncomingConnection,
        onError: (err, st) {
          AppLogger.error('TCP Server socket error', tag: 'TcpServer', error: err, stackTrace: st);
        },
        onDone: () {
          AppLogger.info('TCP Server socket closed', tag: 'TcpServer');
          _isRunning = false;
        },
      );
    } catch (e, st) {
      _isRunning = false;
      AppLogger.error('Failed to start TCP Server on port $port', tag: 'TcpServer', error: e, stackTrace: st);
      rethrow;
    }
  }

  void _handleIncomingConnection(Socket socket) {
    String remoteAddr = 'unknown';
    try {
      remoteAddr = '${socket.remoteAddress.address}:${socket.remotePort}';
    } catch (_) {}

    AppLogger.info('Incoming TCP connection from $remoteAddr', tag: 'TcpServer');
    try {
      socket.setOption(SocketOption.tcpNoDelay, true);
    } catch (_) {}

    final framer = MessageFramer();
    final conn = _PeerConnection(socket: socket, framer: framer);
    _activeConnections[socket] = conn;

    // Handshake timeout
    final handshakeTimer = Timer(AppConstants.handshakeTimeout, () {
      if (!conn.handshakeCompleted) {
        AppLogger.warning('Handshake timed out from $remoteAddr', tag: 'TcpServer');
        _closeSocket(socket);
      }
    });

    socket.listen(
      (data) {
        try {
          final messages = framer.processBytes(Uint8List.fromList(data));
          for (final msg in messages) {
            _handleMessage(socket, conn, msg, handshakeTimer);
          }
        } catch (e, st) {
          AppLogger.error('Error processing TCP data from $remoteAddr', tag: 'TcpServer', error: e, stackTrace: st);
          _closeSocket(socket);
        }
      },
      onError: (err) {
        AppLogger.warning('Socket error on client $remoteAddr: $err', tag: 'TcpServer');
        handshakeTimer.cancel();
        _handleDisconnect(socket);
      },
      onDone: () {
        AppLogger.info('Client disconnected: $remoteAddr', tag: 'TcpServer');
        handshakeTimer.cancel();
        _handleDisconnect(socket);
      },
      cancelOnError: true,
    );
  }

  void _handleMessage(
    Socket socket,
    _PeerConnection conn,
    RawProtocolMessage message,
    Timer handshakeTimer,
  ) {
    if (!conn.handshakeCompleted) {
      if (message.type == MessageType.hello) {
        final json = message.payloadAsJson;
        if (json != null) {
          final peerHandshake = HandshakeMessage.fromJson(json);
          if (peerHandshake != null) {
            conn.peerInfo = peerHandshake;
            conn.handshakeCompleted = true;
            handshakeTimer.cancel();

            AppLogger.info('Handshake accepted from ${peerHandshake.deviceName} (${peerHandshake.platform})', tag: 'TcpServer');

            // Send HELLO_ACK
            final ack = HandshakeMessage(
              deviceId: localDeviceId,
              deviceName: localDeviceName,
              platform: platform,
            );
            socket.add(MessageSerializer.frameJson(MessageType.helloAck, ack.toJson()));
            try {
              socket.flush();
            } catch (_) {}

            onPeerConnected?.call(socket, peerHandshake);
            return;
          }
        }
      }

      // If first message is not a valid HELLO, reject
      AppLogger.warning('Invalid handshake attempt from ${socket.remoteAddress.address}', tag: 'TcpServer');
      _closeSocket(socket);
      return;
    }

    // Handshake completed, dispatch message
    if (conn.peerInfo != null) {
      onMessageReceived?.call(socket, conn.peerInfo!, message);
    }
  }

  void _handleDisconnect(Socket socket) {
    final conn = _activeConnections.remove(socket);
    if (conn != null) {
      onPeerDisconnected?.call(socket, conn.peerInfo?.deviceId);
    }
    _closeSocket(socket);
  }

  void _closeSocket(Socket socket) {
    try {
      socket.destroy();
    } catch (_) {}
  }

  void sendTo(Socket socket, Uint8List framedMessage) {
    try {
      socket.add(framedMessage);
      socket.flush();
    } catch (e) {
      AppLogger.error('Failed to send bytes to socket', tag: 'TcpServer', error: e);
    }
  }

  Future<void> stop() async {
    _isRunning = false;
    for (final socket in _activeConnections.keys.toList()) {
      _closeSocket(socket);
    }
    _activeConnections.clear();

    try {
      await _serverSocket?.close();
      _serverSocket = null;
      AppLogger.info('TCP Server stopped', tag: 'TcpServer');
    } catch (e) {
      AppLogger.warning('Error closing TCP Server: $e', tag: 'TcpServer');
    }
  }
}

class _PeerConnection {
  final Socket socket;
  final MessageFramer framer;
  HandshakeMessage? peerInfo;
  bool handshakeCompleted = false;

  _PeerConnection({
    required this.socket,
    required this.framer,
  });
}
