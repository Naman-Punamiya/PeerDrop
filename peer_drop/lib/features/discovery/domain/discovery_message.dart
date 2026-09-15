import 'dart:convert';
import '../../../core/constants/app_constants.dart';

class DiscoveryMessage {
  static const String messageType = 'peer_discovery';

  final String type;
  final int version;
  final String deviceId;
  final String deviceName;
  final String platform;
  final int tcpPort;

  const DiscoveryMessage({
    this.type = messageType,
    this.version = AppConstants.protocolVersion,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.tcpPort,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'version': version,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': platform,
      'tcpPort': tcpPort,
    };
  }

  String encode() => jsonEncode(toJson());

  static DiscoveryMessage? tryDecode(String jsonString) {
    try {
      final map = jsonDecode(jsonString);
      if (map is! Map<String, dynamic>) return null;

      final type = map['type'] as String?;
      if (type != messageType) return null;

      final version = map['version'] as int?;
      if (version == null || version <= 0) return null;

      final deviceId = map['deviceId'] as String?;
      if (deviceId == null || deviceId.trim().isEmpty) return null;

      final deviceName = map['deviceName'] as String?;
      if (deviceName == null || deviceName.trim().isEmpty) return null;

      final platformStr = map['platform'] as String? ?? 'unknown';

      final tcpPort = map['tcpPort'] as int?;
      if (tcpPort == null || tcpPort <= 0 || tcpPort > 65535) return null;

      return DiscoveryMessage(
        type: messageType,
        version: version,
        deviceId: deviceId.trim(),
        deviceName: deviceName.trim(),
        platform: platformStr.trim().toLowerCase(),
        tcpPort: tcpPort,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() {
    return 'DiscoveryMessage(deviceId: $deviceId, deviceName: $deviceName, platform: $platform, port: $tcpPort)';
  }
}
