import 'package:flutter/material.dart';
import 'package:peer_drop/core/network/models/device_info.dart';

class DiscoveryService with ChangeNotifier {
  final Map<String, DeviceInfo> _devices = {};
  List<DeviceInfo> get devices => _devices.values.toList();
  void addOrUpdateDevice(DeviceInfo device) {
    // if (device.id == myDeviceId) {
      // return;
    // }
    _devices[device.id] = device;
    notifyListeners();
  }
}
