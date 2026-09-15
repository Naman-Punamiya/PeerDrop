class PeerDevice {
  final String deviceId;
  final String deviceName;
  final String platform;
  final String ipAddress;
  final int tcpPort;
  final DateTime lastSeen;

  const PeerDevice({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.ipAddress,
    required this.tcpPort,
    required this.lastSeen,
  });

  PeerDevice copyWith({
    String? deviceId,
    String? deviceName,
    String? platform,
    String? ipAddress,
    int? tcpPort,
    DateTime? lastSeen,
  }) {
    return PeerDevice(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      ipAddress: ipAddress ?? this.ipAddress,
      tcpPort: tcpPort ?? this.tcpPort,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  bool isExpired(Duration timeout) {
    return DateTime.now().difference(lastSeen) > timeout;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeerDevice && runtimeType == other.runtimeType && deviceId == other.deviceId;

  @override
  int get hashCode => deviceId.hashCode;

  @override
  String toString() {
    return 'PeerDevice(id: $deviceId, name: $deviceName, platform: $platform, ip: $ipAddress:$tcpPort)';
  }
}
