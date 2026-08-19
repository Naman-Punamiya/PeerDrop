class DeviceInfo {
  final String id;
  final String name;
  final String platform;
  final String ip;
  final int discoveryPort;
  final int connectionPort;
  final int? lastSeenMs;

  DeviceInfo({
    required this.id,
    required this.name,
    required this.platform,
    required this.ip,
    required this.discoveryPort,
    required this.connectionPort,
    this.lastSeenMs,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'platform': platform,
      'ip': ip,
      'discoveryPort': discoveryPort,
      'connectionPort': connectionPort,
      'lastSeenMs': lastSeenMs ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Device',
      platform: json['platform'] as String? ?? 'Unknown',
      ip: json['ip'] as String? ?? '',
      discoveryPort: (json['discoveryPort'] as num?)?.toInt() ?? 45000,
      connectionPort: (json['connectionPort'] as num?)?.toInt() ?? 45001,
      lastSeenMs: (json['lastSeenMs'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  DeviceInfo copyWith({
    String? id,
    String? name,
    String? platform,
    String? ip,
    int? discoveryPort,
    int? connectionPort,
    int? lastSeenMs,
  }) {
    return DeviceInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      ip: ip ?? this.ip,
      discoveryPort: discoveryPort ?? this.discoveryPort,
      connectionPort: connectionPort ?? this.connectionPort,
      lastSeenMs: lastSeenMs ?? this.lastSeenMs,
    );
  }
}

