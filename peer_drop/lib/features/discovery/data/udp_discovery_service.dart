import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/network_utils.dart';
import '../domain/discovery_message.dart';
import '../domain/peer_device.dart';

enum DiscoveryServiceState {
  idle,
  starting,
  discovering,
  stopped,
  error,
  disposed,
}

typedef PeerUpdateCallback = void Function(List<PeerDevice> peers);
typedef StateChangeCallback = void Function(DiscoveryServiceState state, String? error);

class UdpDiscoveryService {
  final String localDeviceId;
  final String localDeviceName;
  final String platform;
  final int localTcpPort;
  final int discoveryPort;

  RawDatagramSocket? _socket;
  StreamSubscription<RawSocketEvent>? _socketSubscription;

  Timer? _broadcastTimer;
  Timer? _sweepTimer;

  DiscoveryServiceState _state = DiscoveryServiceState.idle;
  DiscoveryServiceState get state => _state;

  final Map<String, PeerDevice> _peers = {};
  final Map<String, DateTime> _lastDirectReply = {};
  PeerUpdateCallback? _onPeersUpdated;
  StateChangeCallback? _onStateChanged;

  UdpDiscoveryService({
    required this.localDeviceId,
    required this.localDeviceName,
    required this.platform,
    required this.localTcpPort,
    this.discoveryPort = AppConstants.defaultDiscoveryPort,
    PeerUpdateCallback? onPeersUpdated,
    StateChangeCallback? onStateChanged,
  })  : _onPeersUpdated = onPeersUpdated,
        _onStateChanged = onStateChanged;

  void setCallbacks({
    PeerUpdateCallback? onPeersUpdated,
    StateChangeCallback? onStateChanged,
  }) {
    if (_state == DiscoveryServiceState.disposed) return;
    _onPeersUpdated = onPeersUpdated;
    _onStateChanged = onStateChanged;
  }

  /// Starts the UDP discovery service safely and asynchronously.
  Future<void> start() async {
    if (_state == DiscoveryServiceState.disposed) {
      AppLogger.warning('Cannot start disposed UdpDiscoveryService', tag: 'Discovery');
      return;
    }

    if (_state == DiscoveryServiceState.discovering || _state == DiscoveryServiceState.starting) {
      AppLogger.debug('Discovery already starting or active, ignoring start()', tag: 'Discovery');
      return;
    }

    _updateState(DiscoveryServiceState.starting);
    AppLogger.info('Starting UDP Discovery on port $discoveryPort...', tag: 'Discovery');

    try {
      // Safely close any dangling socket before binding
      _cleanupSocket();

      // Bind to any IPv4 address with reuseAddress enabled
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        discoveryPort,
        reuseAddress: true,
        reusePort: false,
      );

      _socket!.broadcastEnabled = true;

      // Listen asynchronously for incoming datagrams
      _socketSubscription = _socket!.listen(
        _handleSocketEvent,
        onError: (err, st) {
          // Log transient socket stream errors (e.g. ICMP network unreachable) without crashing discovery
          AppLogger.warning('Transient UDP socket stream error: $err', tag: 'Discovery');
        },
        onDone: () {
          AppLogger.info('UDP socket stream completed', tag: 'Discovery');
        },
        cancelOnError: false,
      );

      // Start periodic broadcast timer
      _broadcastTimer?.cancel();
      _broadcastTimer = Timer.periodic(
        AppConstants.discoveryBroadcastInterval,
        (_) => _sendBroadcast(),
      );

      // Start single sweep timer for peer expiration
      _sweepTimer?.cancel();
      _sweepTimer = Timer.periodic(
        AppConstants.peerSweepInterval,
        (_) => _sweepExpiredPeers(),
      );

      _updateState(DiscoveryServiceState.discovering);
      AppLogger.info('UDP Discovery started successfully', tag: 'Discovery');

      // Send initial announcement burst (0ms, 200ms, 450ms, 800ms) for fast peer detection
      _sendBroadcast();
      Timer(const Duration(milliseconds: 200), () {
        if (_state == DiscoveryServiceState.discovering) _sendBroadcast();
      });
      Timer(const Duration(milliseconds: 450), () {
        if (_state == DiscoveryServiceState.discovering) _sendBroadcast();
      });
      Timer(const Duration(milliseconds: 800), () {
        if (_state == DiscoveryServiceState.discovering) _sendBroadcast();
      });
    } catch (e, st) {
      AppLogger.error('Failed to start UDP Discovery', tag: 'Discovery', error: e, stackTrace: st);
      _handleError('Failed to bind UDP socket: $e');
    }
  }

  /// Handles incoming socket events asynchronously.
  void _handleSocketEvent(RawSocketEvent event) {
    if (_state != DiscoveryServiceState.discovering || _socket == null) return;

    if (event == RawSocketEvent.read) {
      try {
        while (true) {
          final datagram = _socket?.receive();
          if (datagram == null) break;

          final rawText = utf8.decode(datagram.data, allowMalformed: true);
          final message = DiscoveryMessage.tryDecode(rawText);

          if (message == null) {
            continue;
          }

          // Self-discovery filter: ignore own broadcasts
          if (message.deviceId == localDeviceId) {
            continue;
          }

          _handlePeerDiscovered(
            message: message,
            senderAddress: datagram.address,
          );
        }
      } catch (e) {
        // Malformed packet or decoding error must never crash the service
        AppLogger.debug('Ignored malformed discovery packet: $e', tag: 'Discovery');
      }
    }
  }

  /// Processes a valid discovered peer or goodbye event.
  void _handlePeerDiscovered({
    required DiscoveryMessage message,
    required InternetAddress senderAddress,
  }) {
    if (message.action == DiscoveryMessage.actionGoodbye) {
      final removed = _peers.remove(message.deviceId);
      _lastDirectReply.remove(message.deviceId);
      if (removed != null) {
        AppLogger.info('Peer left gracefully: ${removed.deviceName} (${removed.deviceId})', tag: 'Discovery');
        _notifyPeersUpdated();
      }
      return;
    }

    final now = DateTime.now();
    final existing = _peers[message.deviceId];

    final isNew = existing == null;
    final propertyChanged = isNew ||
        existing.ipAddress != senderAddress.address ||
        existing.tcpPort != message.tcpPort ||
        existing.deviceName != message.deviceName;

    final updatedPeer = PeerDevice(
      deviceId: message.deviceId,
      deviceName: message.deviceName,
      platform: message.platform,
      ipAddress: senderAddress.address,
      tcpPort: message.tcpPort,
      lastSeen: now,
    );

    _peers[message.deviceId] = updatedPeer;

    if (isNew) {
      AppLogger.info('Peer discovered: ${updatedPeer.deviceName} (${updatedPeer.platform}) at ${senderAddress.address}:${updatedPeer.tcpPort}', tag: 'Discovery');
    }

    // Send a direct unicast announcement reply back so peer discovers us instantly
    final lastReply = _lastDirectReply[message.deviceId];
    final shouldReplyDirect = isNew || lastReply == null || now.difference(lastReply).inMilliseconds >= 1500;
    if (shouldReplyDirect) {
      _lastDirectReply[message.deviceId] = now;
      _sendDirectAnnouncement(senderAddress);
    }

    if (propertyChanged) {
      _notifyPeersUpdated();
    }
  }

  /// Sends a direct unicast announcement to a specific peer address.
  void _sendDirectAnnouncement(InternetAddress targetAddress) {
    if (_state != DiscoveryServiceState.discovering || _socket == null) return;

    try {
      final message = DiscoveryMessage(
        deviceId: localDeviceId,
        deviceName: localDeviceName,
        platform: platform,
        tcpPort: localTcpPort,
        action: DiscoveryMessage.actionAnnounce,
      );
      final data = utf8.encode(message.encode());
      _socket?.send(data, targetAddress, discoveryPort);
    } catch (e) {
      AppLogger.debug('Error sending direct discovery announcement: $e', tag: 'Discovery');
    }
  }

  /// Sends a broadcast packet to LAN broadcast addresses.
  Future<void> _sendBroadcast() async {
    if (_state != DiscoveryServiceState.discovering || _socket == null) return;

    try {
      final message = DiscoveryMessage(
        deviceId: localDeviceId,
        deviceName: localDeviceName,
        platform: platform,
        tcpPort: localTcpPort,
        action: DiscoveryMessage.actionAnnounce,
      );

      final data = utf8.encode(message.encode());
      final broadcastAddresses = await NetworkUtils.getBroadcastAddresses();

      // 1. Broadcast to all subnet and global broadcast addresses
      for (final address in broadcastAddresses) {
        try {
          _socket?.send(data, address, discoveryPort);
        } catch (_) {
          // Ignore individual broadcast target failures (e.g. inactive network interface)
        }
      }

      // 2. Direct unicast heartbeat to all known peers (bypasses router broadcast drops)
      for (final peer in _peers.values) {
        try {
          _socket?.send(data, InternetAddress(peer.ipAddress), discoveryPort);
        } catch (_) {}
      }
    } catch (e) {
      AppLogger.debug('Error sending discovery broadcast: $e', tag: 'Discovery');
    }
  }

  /// Sweeps expired peers using a single sweep timer.
  void _sweepExpiredPeers() {
    if (_state != DiscoveryServiceState.discovering) return;

    bool changed = false;
    final expiredIds = <String>[];

    for (final entry in _peers.entries) {
      if (entry.value.isExpired(AppConstants.peerTimeoutDuration)) {
        expiredIds.add(entry.key);
      }
    }

    for (final id in expiredIds) {
      final peer = _peers.remove(id);
      _lastDirectReply.remove(id);
      if (peer != null) {
        AppLogger.info('Peer expired: ${peer.deviceName} (${peer.deviceId})', tag: 'Discovery');
        changed = true;
      }
    }

    if (changed) {
      _notifyPeersUpdated();
    }
  }

  /// Stops discovery safely and releases socket and timers.
  Future<void> stop() async {
    if (_state == DiscoveryServiceState.disposed || _state == DiscoveryServiceState.stopped) {
      return;
    }

    AppLogger.info('Stopping UDP Discovery...', tag: 'Discovery');
    await _sendGoodbye();

    _cleanupTimers();
    _cleanupSocket();
    _peers.clear();
    _lastDirectReply.clear();
    _updateState(DiscoveryServiceState.stopped);
    _notifyPeersUpdated();
    AppLogger.info('UDP Discovery stopped', tag: 'Discovery');
  }

  Future<void> _sendGoodbye() async {
    if (_socket == null) return;
    try {
      final message = DiscoveryMessage(
        deviceId: localDeviceId,
        deviceName: localDeviceName,
        platform: platform,
        tcpPort: localTcpPort,
        action: DiscoveryMessage.actionGoodbye,
      );
      final data = utf8.encode(message.encode());
      final broadcastAddresses = await NetworkUtils.getBroadcastAddresses();
      for (final address in broadcastAddresses) {
        try {
          _socket?.send(data, address, discoveryPort);
        } catch (_) {}
      }
      for (final peer in _peers.values) {
        try {
          _socket?.send(data, InternetAddress(peer.ipAddress), discoveryPort);
        } catch (_) {}
      }
    } catch (e) {
      AppLogger.debug('Error sending discovery goodbye: $e', tag: 'Discovery');
    }
  }

  /// Completely disposes of all resources.
  void dispose() {
    if (_state == DiscoveryServiceState.disposed) return;

    _state = DiscoveryServiceState.disposed;
    _cleanupTimers();
    _cleanupSocket();
    _peers.clear();
    _onPeersUpdated = null;
    _onStateChanged = null;
    AppLogger.info('UDP Discovery service disposed', tag: 'Discovery');
  }

  void _cleanupTimers() {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _sweepTimer?.cancel();
    _sweepTimer = null;
  }

  void _cleanupSocket() {
    try {
      _socketSubscription?.cancel();
      _socketSubscription = null;
      _socket?.close();
      _socket = null;
    } catch (e) {
      AppLogger.debug('Error closing UDP socket: $e', tag: 'Discovery');
    }
  }

  void _handleError(String message) {
    if (_state == DiscoveryServiceState.disposed) return;
    _cleanupTimers();
    _cleanupSocket();
    _updateState(DiscoveryServiceState.error, message);
  }

  void _updateState(DiscoveryServiceState newState, [String? error]) {
    if (_state == DiscoveryServiceState.disposed) return;
    _state = newState;
    _onStateChanged?.call(newState, error);
  }

  void _notifyPeersUpdated() {
    if (_state == DiscoveryServiceState.disposed) return;
    final list = _peers.values.toList()
      ..sort((a, b) => a.deviceName.toLowerCase().compareTo(b.deviceName.toLowerCase()));
    _onPeersUpdated?.call(List.unmodifiable(list));
  }
}
