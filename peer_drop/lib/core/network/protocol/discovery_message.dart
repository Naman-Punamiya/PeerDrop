import 'dart:convert';
import '../models/device_info.dart';

class DiscoveryMessage {
  final String messageType;
  final String deviceId;
  final String deviceName;
  final String devicePlatform;
  final String deviceIpAddress;
  final int tcpConnectionPort;
  final int udpDiscoveryPort;

  const DiscoveryMessage({
    required this.messageType,
    required this.deviceId,
    required this.deviceName,
    required this.devicePlatform,
    required this.deviceIpAddress,
    required this.tcpConnectionPort,
    required this.udpDiscoveryPort,
  });

  factory DiscoveryMessage.fromDevice({
    required String messageType,
    required DeviceInfo deviceInformation,
  }) {
    return DiscoveryMessage(
      messageType: messageType,
      deviceId: deviceInformation.id,
      deviceName: deviceInformation.name,
      devicePlatform: deviceInformation.platform,
      deviceIpAddress: deviceInformation.ip,
      tcpConnectionPort: deviceInformation.connectionPort,
      udpDiscoveryPort: deviceInformation.discoveryPort,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': messageType,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': devicePlatform,
      'ip': deviceIpAddress,
      'connectionPort': tcpConnectionPort,
      'discoveryPort': udpDiscoveryPort,
    };
  }

  String encode() {
    return jsonEncode(toJson());
  }

  factory DiscoveryMessage.fromJson(Map<String, dynamic> jsonMap, String fallbackIpAddress) {
    final rawIpString = jsonMap['ip'] as String? ?? '';
    final resolvedIpAddress = (rawIpString.isEmpty || rawIpString == '127.0.0.1' || rawIpString.startsWith('10.0.2.'))
        ? fallbackIpAddress
        : rawIpString;

    return DiscoveryMessage(
      messageType: jsonMap['type'] as String? ?? '',
      deviceId: jsonMap['deviceId'] as String? ?? '',
      deviceName: jsonMap['deviceName'] as String? ?? 'Unknown Device',
      devicePlatform: jsonMap['platform'] as String? ?? 'Unknown',
      deviceIpAddress: resolvedIpAddress,
      tcpConnectionPort: (jsonMap['connectionPort'] as num?)?.toInt() ?? 50506,
      udpDiscoveryPort: (jsonMap['discoveryPort'] as num?)?.toInt() ?? 50505,
    );
  }

  factory DiscoveryMessage.decode(String rawJsonString, String fallbackIpAddress) {
    final Map<String, dynamic> jsonMap = jsonDecode(rawJsonString) as Map<String, dynamic>;
    return DiscoveryMessage.fromJson(jsonMap, fallbackIpAddress);
  }

  DeviceInfo toDeviceInfo({int? lastSeenTimestampMs}) {
    return DeviceInfo(
      id: deviceId,
      name: deviceName,
      platform: devicePlatform,
      ip: deviceIpAddress,
      discoveryPort: udpDiscoveryPort,
      connectionPort: tcpConnectionPort,
      lastSeenMs: lastSeenTimestampMs ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
