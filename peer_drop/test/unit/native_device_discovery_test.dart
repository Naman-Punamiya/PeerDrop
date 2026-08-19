import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:peer_drop/core/network/discovery/native_device_discovery.dart';
import 'package:peer_drop/core/network/discovery/udp_broadcaster.dart';
import 'package:peer_drop/core/network/discovery/udp_listener.dart';
import 'package:peer_drop/core/network/models/device_info.dart';
import 'package:peer_drop/core/network/protocol/discovery_message.dart';
import 'package:peer_drop/core/network/protocol/protocol_constants.dart';

class FakeUdpListener implements UdpListener {
  final StreamController<UdpPacket> _packetStreamController = StreamController<UdpPacket>.broadcast();

  @override
  int get listeningUdpPort => 50505;

  @override
  Stream<UdpPacket> get packets => _packetStreamController.stream;

  void emitPacket(UdpPacket udpPacket) {
    _packetStreamController.add(udpPacket);
  }

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {
    await _packetStreamController.close();
  }
}

class FakeUdpBroadcaster implements UdpBroadcaster {
  @override
  DeviceInfo? get configuredDeviceInfo => null;

  @override
  DeviceInfo? get deviceInfo => null;

  @override
  int get targetUdpPort => 50505;

  @override
  int get udpPort => 50505;

  @override
  int get targetTcpPort => 50506;

  @override
  int get tcpPort => 50506;

  @override
  Duration get broadcastIntervalDuration => const Duration(seconds: 3);

  @override
  Duration get interval => const Duration(seconds: 3);

  @override
  Future<void> start({DeviceInfo? targetDeviceInfo}) async {}

  @override
  Future<void> startBroadcasting() async {}

  @override
  Future<void> broadcastOnce([DeviceInfo? targetDeviceInfo]) async {}

  @override
  Future<void> broadcastPayload(List<int> byteDataPayload) async {}

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}

void main() {
  group('NativeDeviceDiscovery Unit Tests', () {
    late FakeUdpListener fakeListener;
    late FakeUdpBroadcaster fakeBroadcaster;
    late DeviceInfo localDeviceInformation;
    late NativeDeviceDiscovery nativeDiscoveryInstance;

    setUp(() {
      fakeListener = FakeUdpListener();
      fakeBroadcaster = FakeUdpBroadcaster();
      localDeviceInformation = DeviceInfo(
        id: 'self-id',
        name: 'My Computer',
        platform: 'Windows',
        ip: '192.168.1.100',
        discoveryPort: 50505,
        connectionPort: 50506,
      );
      nativeDiscoveryInstance = NativeDeviceDiscovery(
        broadcaster: fakeBroadcaster,
        listener: fakeListener,
        localDeviceInfo: localDeviceInformation,
        timeout: const Duration(milliseconds: 500),
      );
    });

    tearDown(() async {
      await nativeDiscoveryInstance.stop();
    });

    test('ignores self packets', () async {
      await nativeDiscoveryInstance.start();

      final selfDiscoveryMessage = DiscoveryMessage.fromDevice(
        messageType: ProtocolConstants.discover,
        deviceInformation: localDeviceInformation,
      );

      final selfUdpPacket = UdpPacket(
        senderAddress: InternetAddress('192.168.1.100'),
        senderPort: 50505,
        packetDataPayload: selfDiscoveryMessage.encode().codeUnits,
      );

      var hasEmittedDeviceList = false;
      nativeDiscoveryInstance.devices.listen((_) {
        hasEmittedDeviceList = true;
      });

      fakeListener.emitPacket(selfUdpPacket);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(hasEmittedDeviceList, isFalse);
    });

    test('adds remote device and deduplicates on repeat packets', () async {
      await nativeDiscoveryInstance.start();

      final remoteDeviceInformation = DeviceInfo(
        id: 'remote-1',
        name: 'Peer Phone',
        platform: 'Android',
        ip: '192.168.1.101',
        discoveryPort: 50505,
        connectionPort: 50506,
      );

      final remoteDiscoveryMessage = DiscoveryMessage.fromDevice(
        messageType: ProtocolConstants.discover,
        deviceInformation: remoteDeviceInformation,
      );

      final remoteUdpPacket = UdpPacket(
        senderAddress: InternetAddress('192.168.1.101'),
        senderPort: 50505,
        packetDataPayload: remoteDiscoveryMessage.encode().codeUnits,
      );

      List<DeviceInfo> latestDiscoveredDevicesList = [];
      nativeDiscoveryInstance.devices.listen((updatedList) {
        latestDiscoveredDevicesList = updatedList;
      });

      fakeListener.emitPacket(remoteUdpPacket);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(latestDiscoveredDevicesList.length, equals(1));
      expect(latestDiscoveredDevicesList.first.id, equals('remote-1'));
      expect(latestDiscoveredDevicesList.first.name, equals('Peer Phone'));

      fakeListener.emitPacket(remoteUdpPacket);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(latestDiscoveredDevicesList.length, equals(1));
    });
  });
}
