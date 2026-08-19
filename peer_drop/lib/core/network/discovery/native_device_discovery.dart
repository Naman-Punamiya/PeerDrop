import 'dart:async';
import 'dart:convert';

import '../models/device_info.dart';
import '../protocol/discovery_message.dart';
import '../protocol/protocol_constants.dart';
import 'device_discovery.dart';
import 'udp_broadcaster.dart';
import 'udp_listener.dart';

class NativeDeviceDiscovery implements DeviceDiscovery {
  final UdpBroadcaster _udpBroadcaster;
  final UdpListener _udpListener;
  final DeviceInfo _localDeviceInfo;
  final Duration deviceTimeoutDuration;

  final Map<String, DeviceInfo> _discoveredDevicesMap = {};
  StreamController<List<DeviceInfo>>? _discoveredDevicesStreamController;
  StreamSubscription<UdpPacket>? _udpPacketSubscription;
  Timer? _staleDeviceCleanupTimer;
  bool _isDiscoveryRunning = false;

  NativeDeviceDiscovery({
    required UdpBroadcaster broadcaster,
    required UdpListener listener,
    required DeviceInfo localDeviceInfo,
    Duration timeout = const Duration(seconds: 10),
  })  : _udpBroadcaster = broadcaster,
        _udpListener = listener,
        _localDeviceInfo = localDeviceInfo,
        deviceTimeoutDuration = timeout;

  @override
  Stream<List<DeviceInfo>> get devices {
    _discoveredDevicesStreamController ??= StreamController<List<DeviceInfo>>.broadcast();
    return _discoveredDevicesStreamController!.stream;
  }

  @override
  Future<void> start() async {
    if (_isDiscoveryRunning) return;
    _isDiscoveryRunning = true;

    _discoveredDevicesStreamController ??= StreamController<List<DeviceInfo>>.broadcast();

    await _udpListener.start();
    _udpPacketSubscription = _udpListener.packets.listen(_handleIncomingUdpPacket);

    await _udpBroadcaster.start(targetDeviceInfo: _localDeviceInfo);

    _staleDeviceCleanupTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _cleanupOfflineStaleDevices(),
    );
  }

  void _handleIncomingUdpPacket(UdpPacket receivedUdpPacket) {
    try {
      final rawJsonString = utf8.decode(receivedUdpPacket.packetDataPayload);
      final parsedDiscoveryMessage = DiscoveryMessage.decode(rawJsonString, receivedUdpPacket.senderAddress.address);

      if (parsedDiscoveryMessage.messageType != ProtocolConstants.discover &&
          parsedDiscoveryMessage.messageType != ProtocolConstants.discoverResponse) {
        return;
      }

      if (parsedDiscoveryMessage.deviceId.isEmpty || parsedDiscoveryMessage.deviceId == _localDeviceInfo.id) {
        return;
      }

      final currentTimestampMs = DateTime.now().millisecondsSinceEpoch;
      final remoteDeviceInfo = parsedDiscoveryMessage.toDeviceInfo(lastSeenTimestampMs: currentTimestampMs);

      _discoveredDevicesMap[remoteDeviceInfo.id] = remoteDeviceInfo;
      _emitDiscoveredDevicesList();
    } catch (caughtParsingError) {}
  }

  void _cleanupOfflineStaleDevices() {
    final currentTimestampMs = DateTime.now().millisecondsSinceEpoch;
    final offlineTimeoutThresholdMs = deviceTimeoutDuration.inMilliseconds;
    final staleDeviceIdsToRemove = <String>[];

    _discoveredDevicesMap.forEach((deviceId, deviceInformation) {
      if (deviceInformation.lastSeenMs != null && (currentTimestampMs - deviceInformation.lastSeenMs!) > offlineTimeoutThresholdMs) {
        staleDeviceIdsToRemove.add(deviceId);
      }
    });

    if (staleDeviceIdsToRemove.isNotEmpty) {
      for (final deviceId in staleDeviceIdsToRemove) {
        _discoveredDevicesMap.remove(deviceId);
      }
      _emitDiscoveredDevicesList();
    }
  }

  void _emitDiscoveredDevicesList() {
    final activeController = _discoveredDevicesStreamController;
    if (activeController != null && !activeController.isClosed) {
      activeController.add(List<DeviceInfo>.unmodifiable(_discoveredDevicesMap.values));
    }
  }

  @override
  Future<void> stop() async {
    if (!_isDiscoveryRunning) return;
    _isDiscoveryRunning = false;

    _staleDeviceCleanupTimer?.cancel();
    _staleDeviceCleanupTimer = null;

    await _udpPacketSubscription?.cancel();
    _udpPacketSubscription = null;

    await _udpBroadcaster.stop();
    await _udpListener.stop();

    _discoveredDevicesMap.clear();

    await _discoveredDevicesStreamController?.close();
    _discoveredDevicesStreamController = null;
  }
}