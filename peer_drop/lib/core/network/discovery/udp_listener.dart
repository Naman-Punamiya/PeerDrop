import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:peer_drop/core/network/exception/network_exceptions.dart';

class UdpPacket {
  final InternetAddress senderAddress;
  final int senderPort;
  final List<int> packetDataPayload;

  const UdpPacket({
    required this.senderAddress,
    required this.senderPort,
    required this.packetDataPayload,
  });
}

class UdpListener {
  final int listeningUdpPort;
  RawDatagramSocket? _listeningSocket;
  StreamController<UdpPacket>? _incomingPacketStreamController;

  UdpListener({int? listeningPort}) : listeningUdpPort = listeningPort ?? int.parse(dotenv.env['UDP_PORT']!);

  Stream<UdpPacket> get packets {
    _incomingPacketStreamController ??= StreamController<UdpPacket>.broadcast();
    return _incomingPacketStreamController!.stream;
  }

  Future<void> start() async {
    await stop();
    _incomingPacketStreamController = StreamController<UdpPacket>.broadcast();

    try {
      _listeningSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        listeningUdpPort,
        reuseAddress: true,
      );

      _listeningSocket!.listen(
        (RawSocketEvent socketEvent) {
          if (socketEvent == RawSocketEvent.read) {
            final socketInstance = _listeningSocket;
            if (socketInstance == null) return;
            final receivedDatagram = socketInstance.receive();
            if (receivedDatagram == null) return;

            final receivedPacket = UdpPacket(
              senderAddress: receivedDatagram.address,
              senderPort: receivedDatagram.port,
              packetDataPayload: receivedDatagram.data,
            );

            final controllerInstance = _incomingPacketStreamController;
            if (controllerInstance != null && !controllerInstance.isClosed) {
              controllerInstance.add(receivedPacket);
            }
          }
        },
        onError: (dynamic socketError) {},
        onDone: () {},
        cancelOnError: false,
      );
    } catch (caughtError) {
      throw DiscoveryException('Failed to start UDP listener on port $listeningUdpPort', caughtError);
    }
  }

  Future<void> stop() async {
    _listeningSocket?.close();
    _listeningSocket = null;
    await _incomingPacketStreamController?.close();
    _incomingPacketStreamController = null;
  }
}
