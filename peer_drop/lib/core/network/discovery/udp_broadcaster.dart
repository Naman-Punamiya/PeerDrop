import 'dart:convert';
import 'dart:io';

import 'package:peer_drop/core/network/models/device_info.dart';

class UdpBroadcaster {
  Future<void> startBroadcasting() async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;
    final device = DeviceInfo(
      id: "12345",
      name: "Naman's Laptop",
      deviceType: "Windows",
      ip: "192.168.1.10",
      port: 5050,
    );
    final jsonString = jsonEncode(device.toJson());
    final data = utf8.encode(jsonString);
    socket.send(data, InternetAddress("255.255.255.255"), 5050);
  }
}
