import '../models/device_info.dart';

abstract interface class NetworkTransport {
  bool get isConnected;

  Stream<List<int>> get incomingData;

  Future<void> connect(DeviceInfo device);

  Future<void> send(List<int> data);

  Future<void> disconnect();
}
