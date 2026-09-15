import 'package:flutter_test/flutter_test.dart';
import 'package:peerdrop/features/discovery/domain/peer_device.dart';

void main() {
  group('PeerDevice & Timeout Tests', () {
    test('PeerDevice detects expiration correctly', () {
      final now = DateTime.now();
      final freshPeer = PeerDevice(
        deviceId: 'peer-1',
        deviceName: 'Android Phone',
        platform: 'android',
        ipAddress: '192.168.1.100',
        tcpPort: 4040,
        lastSeen: now,
      );

      final expiredPeer = PeerDevice(
        deviceId: 'peer-2',
        deviceName: 'Windows PC',
        platform: 'windows',
        ipAddress: '192.168.1.101',
        tcpPort: 4040,
        lastSeen: now.subtract(const Duration(seconds: 10)),
      );

      const timeout = Duration(seconds: 6);

      expect(freshPeer.isExpired(timeout), false);
      expect(expiredPeer.isExpired(timeout), true);
    });

    test('PeerDevice copyWith updates lastSeen and network metadata without creating duplicate', () {
      final peer = PeerDevice(
        deviceId: 'peer-1',
        deviceName: 'Device A',
        platform: 'android',
        ipAddress: '192.168.1.10',
        tcpPort: 4040,
        lastSeen: DateTime.now().subtract(const Duration(seconds: 5)),
      );

      final newTime = DateTime.now();
      final updatedPeer = peer.copyWith(
        ipAddress: '192.168.1.20',
        tcpPort: 4041,
        lastSeen: newTime,
      );

      expect(updatedPeer.deviceId, peer.deviceId);
      expect(updatedPeer.ipAddress, '192.168.1.20');
      expect(updatedPeer.tcpPort, 4041);
      expect(updatedPeer.lastSeen, newTime);
      expect(updatedPeer == peer, true); // Same deviceId equals true
    });
  });
}
