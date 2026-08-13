class DeviceInfo {
  final String id;
  final String name;
  final String deviceType;
  final String ip;
  final int port;
  final int? lastSeenMs;

  DeviceInfo({
    required this.id,
    required this.name,
    required this.deviceType,
    required this.ip,
    required this.port,
    this.lastSeenMs,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'deviceType': deviceType,
      'ip': ip,
      'port': port,
      'lastSeenMs': lastSeenMs ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Device',
      deviceType: json['deviceType'] as String? ?? 'Unknown',
      ip: json['ip'] as String? ?? '',
      port: (json['port'] as num?)?.toInt() ?? 5050,
      lastSeenMs: (json['lastSeenMs'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  DeviceInfo copyWith({
    String? id,
    String? name,
    String? deviceType,
    String? ip,
    int? port,
    int? lastSeenMs,
  }) {
    return DeviceInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceType: deviceType ?? this.deviceType,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      lastSeenMs: lastSeenMs ?? this.lastSeenMs,
    );
  }
}

