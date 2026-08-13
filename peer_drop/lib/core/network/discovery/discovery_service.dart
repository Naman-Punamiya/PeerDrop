// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:peer_drop/core/network/models/device_info.dart';

class DiscoveryService with ChangeNotifier {
  final Map<String, DeviceInfo> _devices = {};
  Timer? _cleanupTimer;

  DiscoveryService() {
    _cleanupTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _cleanupOfflineDevices(),
    );
  }

  List<DeviceInfo> get devices => _devices.values.toList();

  void addOrUpdateDevice(DeviceInfo device) {
    final updatedDevice = device.copyWith(
      lastSeenMs: DateTime.now().millisecondsSinceEpoch,
    );

    final isNew = !_devices.containsKey(device.id);
    _devices[device.id] = updatedDevice;

    if (isNew) {
      print('[DISCOVERY] New device discovered: ${device.name} (${device.ip})');
    } else {
      print('[DISCOVERY] Device updated: ${device.name} (${device.ip})');
    }

    print('[DISCOVERY] DiscoveryService device count: ${_devices.length}');
    notifyListeners();
  }

  void _cleanupOfflineDevices() {
    final now = DateTime.now().millisecondsSinceEpoch;
    const offlineThresholdMs = 12000; // 12 seconds timeout

    final keysToRemove = <String>[];
    _devices.forEach((id, device) {
      if (device.lastSeenMs != null && (now - device.lastSeenMs!) > offlineThresholdMs) {
        keysToRemove.add(id);
      }
    });

    if (keysToRemove.isNotEmpty) {
      for (final id in keysToRemove) {
        final removed = _devices.remove(id);
        print('[DISCOVERY] Device offline, removed: ${removed?.name} ($id)');
      }
      print('[DISCOVERY] DiscoveryService device count: ${_devices.length}');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    super.dispose();
  }
}

