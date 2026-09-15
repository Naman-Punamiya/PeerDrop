class AppConstants {
  AppConstants._();

  static const String appName = 'PeerDrop';
  static const int protocolVersion = 1;

  // Networking ports
  static const int defaultDiscoveryPort = 4041;
  static const int defaultTcpPort = 4040;

  // Discovery intervals & timeouts
  static const Duration discoveryBroadcastInterval = Duration(milliseconds: 1500);
  static const Duration peerTimeoutDuration = Duration(seconds: 40);
  static const Duration peerSweepInterval = Duration(seconds: 2);

  // TCP & File transfer
  static const int defaultChunkSize = 512 * 1024; // 512 KB
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration handshakeTimeout = Duration(seconds: 15);
  static const Duration transferRequestTimeout = Duration(seconds: 60);

  // Preference keys
  static const String prefDeviceId = 'peerdrop_device_id';
  static const String prefDeviceName = 'peerdrop_device_name';
  static const String prefDiscoveryPort = 'peerdrop_discovery_port';
  static const String prefTcpPort = 'peerdrop_tcp_port';
  static const String prefDownloadDir = 'peerdrop_download_dir';
  static const String prefAutoDiscover = 'peerdrop_auto_discover';
  static const String prefTransferHistory = 'peerdrop_transfer_history';
}
