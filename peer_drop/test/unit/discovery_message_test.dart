import 'package:flutter_test/flutter_test.dart';
import 'package:peer_drop/core/network/models/device_info.dart';
import 'package:peer_drop/core/network/protocol/discovery_message.dart';
import 'package:peer_drop/core/network/protocol/protocol_constants.dart';

void main() {
  group('DiscoveryMessage Unit Tests', () {
    test('encode and decode DiscoveryMessage correctly', () {
      final sampleDeviceInformation = DeviceInfo(
        id: 'test-device-123',
        name: 'Test Phone',
        platform: 'Android',
        ip: '192.168.1.50',
        discoveryPort: 50505,
        connectionPort: 50506,
      );

      final discoveryMessageInstance = DiscoveryMessage.fromDevice(
        messageType: ProtocolConstants.discover,
        deviceInformation: sampleDeviceInformation,
      );

      final rawEncodedString = discoveryMessageInstance.encode();
      final decodedDiscoveryMessage = DiscoveryMessage.decode(rawEncodedString, '192.168.1.50');

      expect(decodedDiscoveryMessage.messageType, equals(ProtocolConstants.discover));
      expect(decodedDiscoveryMessage.deviceId, equals('test-device-123'));
      expect(decodedDiscoveryMessage.deviceName, equals('Test Phone'));
      expect(decodedDiscoveryMessage.devicePlatform, equals('Android'));
      expect(decodedDiscoveryMessage.deviceIpAddress, equals('192.168.1.50'));
      expect(decodedDiscoveryMessage.udpDiscoveryPort, equals(50505));
      expect(decodedDiscoveryMessage.tcpConnectionPort, equals(50506));
    });

    test('toDeviceInfo produces valid DeviceInfo', () {
      final discoveryMessageInstance = DiscoveryMessage(
        messageType: ProtocolConstants.discover,
        deviceId: 'dev-456',
        deviceName: 'Laptop',
        devicePlatform: 'Windows',
        deviceIpAddress: '10.0.0.5',
        tcpConnectionPort: 50506,
        udpDiscoveryPort: 50505,
      );

      final convertedDeviceInfo = discoveryMessageInstance.toDeviceInfo(lastSeenTimestampMs: 123456789);

      expect(convertedDeviceInfo.id, equals('dev-456'));
      expect(convertedDeviceInfo.name, equals('Laptop'));
      expect(convertedDeviceInfo.platform, equals('Windows'));
      expect(convertedDeviceInfo.ip, equals('10.0.0.5'));
      expect(convertedDeviceInfo.lastSeenMs, equals(123456789));
    });
  });
}
