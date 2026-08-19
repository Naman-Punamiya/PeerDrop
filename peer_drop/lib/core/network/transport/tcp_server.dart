import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:peer_drop/core/network/exception/network_exceptions.dart';

class TcpServer {
  final int listeningTcpPort;
  ServerSocket? _boundServerSocket;
  StreamController<Socket>? _incomingTcpConnectionStreamController;

  TcpServer({int? port}) : listeningTcpPort = port ?? int.parse(dotenv.env['TCP_PORT']!);

  int get tcpPort => listeningTcpPort;
  bool get isRunning => _boundServerSocket != null;

  Stream<Socket> get incomingConnections {
    _incomingTcpConnectionStreamController ??= StreamController<Socket>.broadcast();
    return _incomingTcpConnectionStreamController!.stream;
  }

  Future<void> start() async {
    if (_boundServerSocket != null) return;
    _incomingTcpConnectionStreamController ??= StreamController<Socket>.broadcast();

    try {
      _boundServerSocket = await ServerSocket.bind(InternetAddress.anyIPv4, listeningTcpPort);

      _boundServerSocket!.listen(
        (Socket connectedClientSocket) {
          final activeStreamController = _incomingTcpConnectionStreamController;
          if (activeStreamController != null && !activeStreamController.isClosed) {
            activeStreamController.add(connectedClientSocket);
          } else {
            connectedClientSocket.destroy();
          }
        },
        onError: (dynamic serverSocketError) {},
        onDone: () {},
        cancelOnError: false,
      );
    } catch (caughtException) {
      throw ConnectionException('Failed to start TCP server on port $listeningTcpPort', caughtException);
    }
  }

  Future<void> stop() async {
    final activeServerSocket = _boundServerSocket;
    _boundServerSocket = null;
    await activeServerSocket?.close();

    await _incomingTcpConnectionStreamController?.close();
    _incomingTcpConnectionStreamController = null;
  }
}
