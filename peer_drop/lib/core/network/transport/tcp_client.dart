import 'dart:async';
import 'dart:io';

import '../exception/network_exceptions.dart';
import '../models/device_info.dart';
import 'network_transport.dart';

class TcpClient implements NetworkTransport {
  Socket? _activeTcpSocket;
  StreamController<List<int>>? _incomingByteStreamController;
  StreamSubscription<List<int>>? _tcpSocketSubscription;

  @override
  bool get isConnected => _activeTcpSocket != null;

  @override
  Stream<List<int>> get incomingData {
    _incomingByteStreamController ??= StreamController<List<int>>.broadcast();
    return _incomingByteStreamController!.stream;
  }

  @override
  Future<void> connect(DeviceInfo targetDeviceInfo, {Duration timeout = const Duration(seconds: 5)}) async {
    if (isConnected) {
      await disconnect();
    }

    _incomingByteStreamController ??= StreamController<List<int>>.broadcast();

    try {
      _activeTcpSocket = await Socket.connect(
        targetDeviceInfo.ip,
        targetDeviceInfo.connectionPort,
        timeout: timeout,
      );

      _tcpSocketSubscription = _activeTcpSocket!.listen(
        (List<int> incomingByteChunk) {
          final activeController = _incomingByteStreamController;
          if (activeController != null && !activeController.isClosed) {
            activeController.add(incomingByteChunk);
          }
        },
        onError: (dynamic socketError) {
          disconnect();
        },
        onDone: () {
          disconnect();
        },
        cancelOnError: false,
      );
    } on SocketException catch (socketException) {
      await disconnect();
      throw ConnectionException('Failed to connect to ${targetDeviceInfo.name} (${targetDeviceInfo.ip}:${targetDeviceInfo.connectionPort})', socketException);
    } on TimeoutException catch (timeoutException) {
      await disconnect();
      throw NetworkTimeoutException('Connection timed out connecting to ${targetDeviceInfo.name}', timeoutException);
    } catch (unexpectedError) {
      await disconnect();
      throw ConnectionException('Unexpected error connecting to ${targetDeviceInfo.name}', unexpectedError);
    }
  }

  @override
  Future<void> send(List<int> byteDataPayload) async {
    final activeSocket = _activeTcpSocket;
    if (activeSocket == null) {
      throw const ConnectionException('Cannot send data: TCP client is not connected');
    }

    try {
      activeSocket.add(byteDataPayload);
      await activeSocket.flush();
    } catch (sendException) {
      throw ConnectionException('Failed to send data over TCP socket', sendException);
    }
  }

  @override
  Future<void> disconnect() async {
    await _tcpSocketSubscription?.cancel();
    _tcpSocketSubscription = null;

    final socketToClose = _activeTcpSocket;
    _activeTcpSocket = null;
    if (socketToClose != null) {
      try {
        await socketToClose.close();
        socketToClose.destroy();
      } catch (closeException) {}
    }

    await _incomingByteStreamController?.close();
    _incomingByteStreamController = null;
  }
}
