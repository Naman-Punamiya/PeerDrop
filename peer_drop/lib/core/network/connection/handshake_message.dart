class HandshakeMessage {
  final String type;
  final int version;
  final String deviceId;
  final String deviceName;
  final String deviceType;

  HandshakeMessage({
    required this.type,
    required this.version,
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'version': version,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceType': deviceType,
    };
  }

  factory HandshakeMessage.fromJson(Map<String, dynamic> json) {
    return HandshakeMessage(
      type: json['type'],
      version: json['version'],
      deviceId: json['deviceId'],
      deviceName: json['deviceName'],
      deviceType: json['deviceType'],
    );
  }
}