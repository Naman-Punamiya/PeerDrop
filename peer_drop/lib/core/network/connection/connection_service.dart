import 'dart:convert';
import 'dart:io';

import 'package:peer_drop/core/network/connection/handshake_message.dart';
import 'package:peer_drop/core/network/connection/network_protocol.dart';
import 'package:peer_drop/core/network/models/device_info.dart';

class ConnectionService {
  Socket? _socket;

  Future<void> connect({required DeviceInfo device}) async {
    if (_socket != null) {
      await disconnect();
    }
    try {
      _socket = await Socket.connect(
        device.ip,
        device.connectionPort,
        timeout: const Duration(seconds: 5),
      );
      await _sendHandshake(
        deviceId: device.id,
        deviceName: device.name,
        deviceType: device.platform,
      );
    } catch (e) {
      _socket?.destroy();
      _socket = null;
      rethrow;
    }
  }

  Future<void> _sendHandshake({
    required String deviceId,
    required String deviceName,
    required String deviceType,
  }) async {
    if (_socket == null) {
      throw StateError('Socket is not connected');
    }

    final handshake = HandshakeMessage(
      type: NetworkProtocol.handshake,
      version: NetworkProtocol.version,
      deviceId: deviceId,
      deviceName: deviceName,
      deviceType: deviceType,
    );

    final message = '${jsonEncode(handshake.toJson())}\n';

    _socket!.write(message);
  }

  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
  }

  bool get isConnected => _socket != null;
}
