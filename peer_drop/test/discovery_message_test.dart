import 'package:flutter_test/flutter_test.dart';
import 'package:peerdrop/features/discovery/domain/discovery_message.dart';

void main() {
  group('DiscoveryMessage Tests', () {
    test('Valid JSON parses successfully', () {
      final json = '''
      {
        "type": "peer_discovery",
        "version": 1,
        "deviceId": "dev-12345",
        "deviceName": "Naman Windows PC",
        "platform": "windows",
        "tcpPort": 4040
      }
      ''';

      final message = DiscoveryMessage.tryDecode(json);
      expect(message, isNotNull);
      expect(message!.deviceId, 'dev-12345');
      expect(message.deviceName, 'Naman Windows PC');
      expect(message.platform, 'windows');
      expect(message.tcpPort, 4040);
      expect(message.version, 1);
    });

    test('Encodes to JSON correctly', () {
      const message = DiscoveryMessage(
        deviceId: 'dev-999',
        deviceName: 'Pixel 8',
        platform: 'android',
        tcpPort: 4040,
      );

      final encoded = message.encode();
      final decoded = DiscoveryMessage.tryDecode(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.deviceId, 'dev-999');
      expect(decoded.deviceName, 'Pixel 8');
      expect(decoded.platform, 'android');
      expect(decoded.tcpPort, 4040);
    });

    test('Malformed JSON returns null without throwing', () {
      expect(DiscoveryMessage.tryDecode('not valid json'), isNull);
      expect(DiscoveryMessage.tryDecode('{}'), isNull);
      expect(DiscoveryMessage.tryDecode('{"type": "other"}'), isNull);
      expect(DiscoveryMessage.tryDecode('{"type": "peer_discovery", "deviceId": ""}'), isNull);
      expect(DiscoveryMessage.tryDecode('{"type": "peer_discovery", "deviceId": "1", "deviceName": "A", "tcpPort": 999999}'), isNull);
    });
  });
}
