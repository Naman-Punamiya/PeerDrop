import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/app_settings.dart';

class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  static Future<SettingsRepository> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsRepository(prefs);
  }

  Future<AppSettings> loadSettings() async {
    // 1. Stable Device ID
    String? deviceId = _prefs.getString(AppConstants.prefDeviceId);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = const Uuid().v4();
      await _prefs.setString(AppConstants.prefDeviceId, deviceId);
      AppLogger.info('Generated new stable device ID: $deviceId', tag: 'Settings');
    }

    // 2. Device Name
    String? deviceName = _prefs.getString(AppConstants.prefDeviceName);
    if (deviceName == null || deviceName.isEmpty) {
      deviceName = await _getDefaultDeviceName();
      await _prefs.setString(AppConstants.prefDeviceName, deviceName);
    }

    // 3. Ports
    final tcpPort = _prefs.getInt(AppConstants.prefTcpPort) ?? AppConstants.defaultTcpPort;
    final discoveryPort = _prefs.getInt(AppConstants.prefDiscoveryPort) ?? AppConstants.defaultDiscoveryPort;

    // 4. Download Directory
    String? downloadDir = _prefs.getString(AppConstants.prefDownloadDir);
    if (downloadDir == null || downloadDir.isEmpty || (Platform.isAndroid && downloadDir.contains('Android/data'))) {
      downloadDir = await _getDefaultDownloadDirectory();
      await _prefs.setString(AppConstants.prefDownloadDir, downloadDir);
    }

    // 5. Auto Discover (default false so user manually turns on)
    final autoDiscover = _prefs.getBool(AppConstants.prefAutoDiscover) ?? false;

    return AppSettings(
      deviceId: deviceId,
      deviceName: deviceName,
      tcpPort: tcpPort,
      discoveryPort: discoveryPort,
      downloadDirectory: downloadDir,
      autoDiscover: autoDiscover,
    );
  }

  Future<void> saveDeviceName(String name) async {
    await _prefs.setString(AppConstants.prefDeviceName, name);
  }

  Future<void> saveDownloadDirectory(String path) async {
    await _prefs.setString(AppConstants.prefDownloadDir, path);
  }

  Future<void> saveTcpPort(int port) async {
    await _prefs.setInt(AppConstants.prefTcpPort, port);
  }

  Future<void> saveDiscoveryPort(int port) async {
    await _prefs.setInt(AppConstants.prefDiscoveryPort, port);
  }

  Future<void> saveAutoDiscover(bool enabled) async {
    await _prefs.setBool(AppConstants.prefAutoDiscover, enabled);
  }

  static Future<String> _getDefaultDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        return '${android.brand.toUpperCase()} ${android.model}';
      } else if (Platform.isWindows) {
        final windows = await deviceInfo.windowsInfo;
        return windows.computerName.isNotEmpty ? windows.computerName : 'Windows PC';
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        return ios.name;
      } else if (Platform.isMacOS) {
        final mac = await deviceInfo.macOsInfo;
        return mac.computerName;
      } else if (Platform.isLinux) {
        final linux = await deviceInfo.linuxInfo;
        return linux.name;
      }
    } catch (e) {
      AppLogger.warning('Failed to query device info', tag: 'Settings', error: e);
    }
    return Platform.isAndroid ? 'Android Device' : 'Windows PC';
  }

  static Future<String> _getDefaultDownloadDirectory() async {
    try {
      Directory? baseDir;
      if (Platform.isAndroid) {
        // Use standard Android public Download folder: /storage/emulated/0/Download
        final publicDownload = Directory('/storage/emulated/0/Download');
        if (await publicDownload.exists()) {
          baseDir = publicDownload;
        } else {
          baseDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isWindows) {
        baseDir = await getDownloadsDirectory();
      }

      baseDir ??= await getApplicationDocumentsDirectory();

      final peerDropDir = Directory('${baseDir.path}/PeerDrop');
      if (!await peerDropDir.exists()) {
        await peerDropDir.create(recursive: true);
      }
      return peerDropDir.path;
    } catch (e) {
      AppLogger.error('Failed to get download directory', tag: 'Settings', error: e);
      final docDir = await getApplicationDocumentsDirectory();
      return docDir.path;
    }
  }
}
