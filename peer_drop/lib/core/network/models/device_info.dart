class DeviceInfo {
  final String id;
  final String name;
  final String deviceType;
  final String ip;
  final int port;

  DeviceInfo({
    required this.id,
    required this.name,
    required this.deviceType,
    required this.ip,
    required this.port,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'deviceType': deviceType,
      'ip': ip,
      'port': port,
    };
  }

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      id: json['id'],
      name: json['name'],
      deviceType: json['deviceType'],
      ip: json['ip'],
      port: json['port'],
    );
  }
}
