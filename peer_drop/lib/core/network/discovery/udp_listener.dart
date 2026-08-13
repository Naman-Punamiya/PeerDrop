// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:peer_drop/core/network/discovery/discovery_service.dart';
import 'package:peer_drop/core/network/models/device_info.dart';

class UdpListener {
  final DiscoveryService discoveryService;
  final String myDeviceId;
  RawDatagramSocket? _socket;

  UdpListener(this.discoveryService, this.myDeviceId);

  Future<void> startListening() async {
    stopListening(); // Stop any existing listener socket

    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        5050,
        reuseAddress: true,
      );
      print('[DISCOVERY] Listener started on 0.0.0.0:5050');

      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram == null) return;

          try {
            final message = utf8.decode(datagram.data);
            print('[DISCOVERY] Packet received from ${datagram.address.address}:${datagram.port}');

            final json = jsonDecode(message) as Map<String, dynamic>;
            var device = DeviceInfo.fromJson(json);
            print('[DISCOVERY] Received device ID: ${device.id} (${device.name})');

            // Fallback to datagram remote address if payload IP is missing, loopback, or internal emulator IP
            if (device.ip.isEmpty || device.ip == '127.0.0.1' || device.ip.startsWith('10.0.2.')) {
              device = device.copyWith(ip: datagram.address.address);
            }

            if (device.id.isEmpty || device.id == myDeviceId) {
              print('[DISCOVERY] Ignoring own device packet (ID: ${device.id})');
              return;
            }

            print('[DISCOVERY] New/updated remote device packet validated: ${device.name} (${device.ip})');
            discoveryService.addOrUpdateDevice(device);
          } catch (e) {
            print('[DISCOVERY] Error decoding UDP datagram: $e');
          }
        }
      });
    } catch (e) {
      print('[DISCOVERY] Failed to bind UDP listener on port 5050: $e');
    }
  }

  void stopListening() {
    _socket?.close();
    _socket = null;
    print('[DISCOVERY] Listener stopped');
  }
}

