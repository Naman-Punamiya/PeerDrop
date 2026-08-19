import 'package:flutter_test/flutter_test.dart';
import 'package:peer_drop/core/network/models/device_info.dart';

void main() {
  group('DeviceInfo Serialization & CopyWith', () {
    test('toJson and fromJson work bidirectionally', () {
      final original = DeviceInfo(
        id: 'id-001',
        name: 'My Mac',
        platform: 'macOS',
        ip: '192.168.1.10',
        discoveryPort: 50505,
        connectionPort: 50506,
        lastSeenMs: 100000,
      );

      final json = original.toJson();
      final restored = DeviceInfo.fromJson(json);

      expect(restored.id, equals('id-001'));
      expect(restored.name, equals('My Mac'));
      expect(restored.platform, equals('macOS'));
      expect(restored.ip, equals('192.168.1.10'));
      expect(restored.discoveryPort, equals(50505));
      expect(restored.connectionPort, equals(50506));
      expect(restored.lastSeenMs, equals(100000));
    });

    test('copyWith updates specified fields only', () {
      final info = DeviceInfo(
        id: 'id-001',
        name: 'My Mac',
        platform: 'macOS',
        ip: '192.168.1.10',
        discoveryPort: 50505,
        connectionPort: 50506,
      );

      final updated = info.copyWith(ip: '192.168.1.20', lastSeenMs: 200000);

      expect(updated.id, equals('id-001'));
      expect(updated.ip, equals('192.168.1.20'));
      expect(updated.lastSeenMs, equals(200000));
    });
  });
}
