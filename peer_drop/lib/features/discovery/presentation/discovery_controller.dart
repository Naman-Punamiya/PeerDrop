import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/network_utils.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/udp_discovery_service.dart';
import '../domain/peer_device.dart';
import 'discovery_state.dart';

final discoveryControllerProvider = StateNotifierProvider<DiscoveryController, DiscoveryState>((ref) {
  final settingsAsync = ref.watch(settingsControllerProvider);
  final controller = DiscoveryController();

  ref.onDispose(() {
    controller.disposeService();
  });

  // When settings are available and autoDiscover is true, initialize and start discovery
  settingsAsync.whenData((settings) {
    controller.initService(
      deviceId: settings.deviceId,
      deviceName: settings.deviceName,
      platform: NetworkUtils.getPlatformName(),
      tcpPort: settings.tcpPort,
      discoveryPort: settings.discoveryPort,
      autoStart: settings.autoDiscover,
    );
  });

  return controller;
});

class DiscoveryController extends StateNotifier<DiscoveryState> {
  UdpDiscoveryService? _service;
  String? _deviceId;
  String? _deviceName;
  String? _platform;
  int? _tcpPort;
  int? _discoveryPort;

  DiscoveryController() : super(const DiscoveryState());

  void initService({
    required String deviceId,
    required String deviceName,
    required String platform,
    required int tcpPort,
    required int discoveryPort,
    bool autoStart = true,
  }) {
    // If configuration changed or service is null, recreate
    final needsRecreate = _service == null ||
        _deviceId != deviceId ||
        _deviceName != deviceName ||
        _platform != platform ||
        _tcpPort != tcpPort ||
        _discoveryPort != discoveryPort;

    if (!needsRecreate) return;

    _deviceId = deviceId;
    _deviceName = deviceName;
    _platform = platform;
    _tcpPort = tcpPort;
    _discoveryPort = discoveryPort;

    _service?.dispose();

    _service = UdpDiscoveryService(
      localDeviceId: deviceId,
      localDeviceName: deviceName,
      platform: platform,
      localTcpPort: tcpPort,
      discoveryPort: discoveryPort,
      onPeersUpdated: _handlePeersUpdated,
      onStateChanged: _handleServiceStateChanged,
    );

    if (autoStart) {
      startDiscovery();
    }
  }

  Future<void> startDiscovery() async {
    if (_service == null) return;
    state = state.copyWith(status: DiscoveryServiceState.starting, clearError: true);
    await _service!.start();
  }

  void stopDiscovery() {
    _service?.stop();
    state = state.copyWith(status: DiscoveryServiceState.stopped, peers: const []);
  }

  Future<void> restartDiscovery() async {
    stopDiscovery();
    await Future.delayed(const Duration(milliseconds: 300));
    await startDiscovery();
  }

  void _handlePeersUpdated(List<PeerDevice> peers) {
    if (!mounted) return;
    state = state.copyWith(peers: peers);
  }

  void _handleServiceStateChanged(DiscoveryServiceState serviceState, String? error) {
    if (!mounted) return;
    state = state.copyWith(
      status: serviceState,
      errorMessage: error,
      clearError: error == null,
    );
  }

  void disposeService() {
    try {
      _service?.dispose();
      _service = null;
    } catch (e) {
      AppLogger.warning('Error disposing discovery service: $e', tag: 'Discovery');
    }
  }

  @override
  void dispose() {
    disposeService();
    super.dispose();
  }
}
