import '../domain/peer_device.dart';
import '../data/udp_discovery_service.dart';

class DiscoveryState {
  final DiscoveryServiceState status;
  final List<PeerDevice> peers;
  final String? errorMessage;

  const DiscoveryState({
    this.status = DiscoveryServiceState.idle,
    this.peers = const [],
    this.errorMessage,
  });

  bool get isDiscovering => status == DiscoveryServiceState.discovering;
  bool get isLoading => status == DiscoveryServiceState.starting;
  bool get hasError => status == DiscoveryServiceState.error;
  bool get isEmpty => status == DiscoveryServiceState.discovering && peers.isEmpty;

  DiscoveryState copyWith({
    DiscoveryServiceState? status,
    List<PeerDevice>? peers,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DiscoveryState(
      status: status ?? this.status,
      peers: peers ?? this.peers,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  String toString() => 'DiscoveryState(status: $status, peers: ${peers.length}, error: $errorMessage)';
}
