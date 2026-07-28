import 'dart:convert';
import 'dart:io';

import 'package:peer_drop/core/network/discovery/discovery_service.dart';
import 'package:peer_drop/core/network/models/device_info.dart';

class UdpListener {

  final DiscoveryService discoveryService;
  
  UdpListener(this.discoveryService);

  Future<void> startListening() async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 5050);
    socket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        final datagram = socket.receive();
        if (datagram == null) return;
        final message = utf8.decode(datagram.data);
        final json = jsonDecode(message);
        final device = DeviceInfo.fromJson(json);
        discoveryService.addOrUpdateDevice(device);
        print(device.name);
        print(device.deviceType);
        print(device.ip);
      }
    });
  }
}
