// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:peer_drop/core/network/models/device_info.dart';
import 'package:peer_drop/core/network/utils/network_utils.dart';

class UdpBroadcaster {
  Timer? _timer;
  RawDatagramSocket? _socket;
  final String deviceId;
  final String deviceName;
  final String deviceType;

  UdpBroadcaster({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
  });

  Future<void> startBroadcasting() async {
    dispose(); // Cleanup existing timer and socket if any

    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );
      _socket!.broadcastEnabled = true;
      print('[DISCOVERY] My device ID: $deviceId');
      print('[DISCOVERY] UDP Broadcaster initialized on local socket port ${_socket!.port}');

      await broadcastOnce();

      _timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => broadcastOnce(),
      );
    } catch (e) {
      print('[DISCOVERY] Broadcaster failed to bind socket: $e');
    }
  }

  Future<void> broadcastOnce() async {
    if (_socket == null) return;

    final localIp = await NetworkUtils.getLocalIpAddress();
    print('[DISCOVERY] Local interface/IP: $localIp');

    final device = DeviceInfo(
      id: deviceId,
      name: deviceName,
      deviceType: deviceType,
      ip: localIp,
      port: 5050,
      lastSeenMs: DateTime.now().millisecondsSinceEpoch,
    );

    final message = jsonEncode(device.toJson());
    final data = utf8.encode(message);

    final broadcastTargets = await NetworkUtils.getBroadcastAddresses();
    for (final target in broadcastTargets) {
      try {
        print('[DISCOVERY] Broadcast destination: ${target.address}:5050');
        _socket!.send(data, target, 5050);
      } catch (e) {
        print('[DISCOVERY] Broadcast send error to ${target.address}: $e');
      }
    }

    print('[DISCOVERY] Broadcast sent from $localIp ($deviceName, ID: $deviceId)');
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _socket?.close();
    _socket = null;
    print('[DISCOVERY] Broadcaster stopped');
  }
}

