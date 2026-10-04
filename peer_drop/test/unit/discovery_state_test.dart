import 'package:flutter_test/flutter_test.dart';
import 'package:peerdrop/features/discovery/data/udp_discovery_service.dart';
import 'package:peerdrop/features/discovery/domain/peer_device.dart';
import 'package:peerdrop/features/discovery/presentation/discovery_state.dart';

void main() {
  group('DiscoveryState Tests', () {
    test('Default constructor sets default properties', () {
      const state = DiscoveryState();
      expect(state.status, DiscoveryServiceState.idle);
      expect(state.peers, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.isDiscovering, false);
      expect(state.isLoading, false);
      expect(state.hasError, false);
      expect(state.isEmpty, false);
    });

    test('Status flags reflect state accurately', () {
      const discoveringEmpty = DiscoveryState(
        status: DiscoveryServiceState.discovering,
        peers: [],
      );
      expect(discoveringEmpty.isDiscovering, true);
      expect(discoveringEmpty.isEmpty, true);

      final dummyPeer = PeerDevice(
        deviceId: 'peer-1',
        deviceName: 'Android Device',
        platform: 'android',
        ipAddress: '192.168.1.50',
        tcpPort: 4040,
        lastSeen: DateTime.now(),
      );

      final discoveringWithPeers = DiscoveryState(
        status: DiscoveryServiceState.discovering,
        peers: [dummyPeer],
      );
      expect(discoveringWithPeers.isDiscovering, true);
      expect(discoveringWithPeers.isEmpty, false);

      const loadingState = DiscoveryState(
        status: DiscoveryServiceState.starting,
      );
      expect(loadingState.isLoading, true);

      const errorState = DiscoveryState(
        status: DiscoveryServiceState.error,
        errorMessage: 'Network error',
      );
      expect(errorState.hasError, true);
      expect(errorState.errorMessage, 'Network error');
    });

    test('copyWith properly copies and clears error', () {
      const initial = DiscoveryState(
        status: DiscoveryServiceState.error,
        errorMessage: 'Some error',
      );

      final updated = initial.copyWith(
        status: DiscoveryServiceState.discovering,
        clearError: true,
      );

      expect(updated.status, DiscoveryServiceState.discovering);
      expect(updated.errorMessage, isNull);
    });
  });
}
