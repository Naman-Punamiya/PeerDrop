import '../../../core/constants/app_constants.dart';

class AppSettings {
  final String deviceId;
  final String deviceName;
  final int tcpPort;
  final int discoveryPort;
  final String downloadDirectory;
  final bool autoDiscover;

  const AppSettings({
    required this.deviceId,
    required this.deviceName,
    this.tcpPort = AppConstants.defaultTcpPort,
    this.discoveryPort = AppConstants.defaultDiscoveryPort,
    required this.downloadDirectory,
    this.autoDiscover = false,
  });

  AppSettings copyWith({
    String? deviceId,
    String? deviceName,
    int? tcpPort,
    int? discoveryPort,
    String? downloadDirectory,
    bool? autoDiscover,
  }) {
    return AppSettings(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      tcpPort: tcpPort ?? this.tcpPort,
      discoveryPort: discoveryPort ?? this.discoveryPort,
      downloadDirectory: downloadDirectory ?? this.downloadDirectory,
      autoDiscover: autoDiscover ?? this.autoDiscover,
    );
  }
}
