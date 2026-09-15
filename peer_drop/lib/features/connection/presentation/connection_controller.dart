import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/network_utils.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/tcp_server.dart';

final tcpServerProvider = Provider<TcpServer?>((ref) {
  final serverConfig = ref.watch(
    settingsControllerProvider.select((s) => s.valueOrNull == null
        ? null
        : (
            s.value!.tcpPort,
            s.value!.deviceId,
            s.value!.deviceName,
          )),
  );

  if (serverConfig == null) return null;

  final (tcpPort, deviceId, deviceName) = serverConfig;

  final server = TcpServer(
    port: tcpPort,
    localDeviceId: deviceId,
    localDeviceName: deviceName,
    platform: NetworkUtils.getPlatformName(),
  );

  server.start().catchError((e) {
    AppLogger.error('Failed to start background TCP server', tag: 'TcpServer', error: e);
  });

  ref.onDispose(() {
    server.stop();
  });

  return server;
});

class ConnectionState {
  final bool isServerRunning;
  final String? localIp;
  final int tcpPort;

  const ConnectionState({
    this.isServerRunning = false,
    this.localIp,
    this.tcpPort = 4040,
  });

  ConnectionState copyWith({
    bool? isServerRunning,
    String? localIp,
    int? tcpPort,
  }) {
    return ConnectionState(
      isServerRunning: isServerRunning ?? this.isServerRunning,
      localIp: localIp ?? this.localIp,
      tcpPort: tcpPort ?? this.tcpPort,
    );
  }
}
