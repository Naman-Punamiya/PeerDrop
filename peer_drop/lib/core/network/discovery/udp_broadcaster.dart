import 'dart:async';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:peer_drop/core/network/exception/network_exceptions.dart';
import 'package:peer_drop/core/network/models/device_info.dart';
import 'package:peer_drop/core/network/protocol/discovery_message.dart';
import 'package:peer_drop/core/network/protocol/protocol_constants.dart';
import 'package:peer_drop/core/network/utils/network_utils.dart';

class UdpBroadcaster {
  Timer? _periodicBroadcastTimer;
  RawDatagramSocket? _sendingDatagramSocket;
  final DeviceInfo? configuredDeviceInfo;
  final int targetUdpPort;
  final int targetTcpPort;
  final Duration broadcastIntervalDuration;

  UdpBroadcaster({
    DeviceInfo? deviceInfo,
    int? udpPort,
    int? tcpPort,
    Duration interval = const Duration(seconds: 3),
  }) : configuredDeviceInfo = deviceInfo,
       targetUdpPort = udpPort ?? int.parse(dotenv.env['UDP_PORT']!),
       targetTcpPort = tcpPort ?? int.parse(dotenv.env['TCP_PORT']!),
       broadcastIntervalDuration = interval;

  DeviceInfo? get deviceInfo => configuredDeviceInfo;
  int get udpPort => targetUdpPort;
  int get tcpPort => targetTcpPort;
  Duration get interval => broadcastIntervalDuration;

  Future<void> start({DeviceInfo? targetDeviceInfo}) async {
    await stop();
    final deviceInformationToBroadcast =
        targetDeviceInfo ?? configuredDeviceInfo;
    try {
      _sendingDatagramSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );
      _sendingDatagramSocket!.broadcastEnabled = true;
      if (deviceInformationToBroadcast != null) {
        await broadcastOnce(deviceInformationToBroadcast);
        _periodicBroadcastTimer = Timer.periodic(
          broadcastIntervalDuration,
          (_) => broadcastOnce(deviceInformationToBroadcast),
        );
      }
    } catch (caughtException) {
      throw DiscoveryException(
        'Broadcaster failed to bind socket',
        caughtException,
      );
    }
  }

  Future<void> startBroadcasting() => start();

  Future<void> broadcastOnce([DeviceInfo? targetDeviceInfo]) async {
    final deviceInformation = targetDeviceInfo ?? configuredDeviceInfo;
    if (deviceInformation == null) return;

    if (_sendingDatagramSocket == null) {
      try {
        _sendingDatagramSocket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4,
          0,
        );
        _sendingDatagramSocket!.broadcastEnabled = true;
      } catch (bindException) {
        return;
      }
    }

    final localIpAddress = await NetworkUtils.getLocalIpAddress();
    final updatedDeviceInfo = deviceInformation.copyWith(
      ip: localIpAddress,
      discoveryPort: targetUdpPort,
      connectionPort: targetTcpPort,
      lastSeenMs: DateTime.now().millisecondsSinceEpoch,
    );

    final discoveryMessage = DiscoveryMessage.fromDevice(
      messageType: ProtocolConstants.discover,
      deviceInformation: updatedDeviceInfo,
    );

    final byteDataPayload = discoveryMessage.encode().codeUnits;
    await broadcastPayload(byteDataPayload);
  }

  Future<void> broadcastPayload(List<int> byteDataPayload) async {
    final activeSocket = _sendingDatagramSocket;
    if (activeSocket == null) return;

    final broadcastTargetAddresses = await NetworkUtils.getBroadcastAddresses();
    for (final targetAddress in broadcastTargetAddresses) {
      try {
        activeSocket.send(byteDataPayload, targetAddress, targetUdpPort);
      } catch (sendException) {}
    }
  }

  Future<void> stop() async {
    _periodicBroadcastTimer?.cancel();
    _periodicBroadcastTimer = null;
    _sendingDatagramSocket?.close();
    _sendingDatagramSocket = null;
  }

  void dispose() {
    stop();
  }
}
