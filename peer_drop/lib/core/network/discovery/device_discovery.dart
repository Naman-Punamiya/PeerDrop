import '../models/device_info.dart';

abstract interface class DeviceDiscovery {
  Stream<List<DeviceInfo>> get devices;

  Future<void> start();

  Future<void> stop();
}