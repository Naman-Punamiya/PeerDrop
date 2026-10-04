import 'package:flutter_test/flutter_test.dart';
import 'package:peerdrop/core/utils/network_utils.dart';

void main() {
  group('NetworkUtils Tests', () {
    test('getPlatformName returns valid platform string', () {
      final platform = NetworkUtils.getPlatformName();
      expect(
        ['android', 'windows', 'ios', 'macos', 'linux', 'unknown'],
        contains(platform),
      );
    });

    test('getLocalIpAddress returns an IP address string', () async {
      final ip = await NetworkUtils.getLocalIpAddress();
      expect(ip, isNotEmpty);
      expect(ip.split('.').length, 4);
    });

    test('getBroadcastAddresses returns at least global fallback broadcast address', () async {
      final addresses = await NetworkUtils.getBroadcastAddresses();
      expect(addresses, isNotEmpty);
      expect(addresses.any((a) => a.address.endsWith('.255')), true);
    });
  });
}
