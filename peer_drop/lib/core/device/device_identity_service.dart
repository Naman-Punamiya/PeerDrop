import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdentityService {
  static const String _deviceIdKey = "device_id_key";
  static const String _deviceNameKey = "device_name_key";
  final Uuid _uuid = const Uuid();
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();


  Future<String> getDeviceId() async {
    final existingId = await _prefs.getString(_deviceIdKey);
    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }
    final newId = _uuid.v4();
    await _prefs.setString(_deviceIdKey, newId);
    return newId;
  }

  Future<String> getDeviceName() async {
    final existingName = await _prefs.getString(_deviceNameKey);
    if (existingName != null && existingName.isNotEmpty) {
      return existingName;
    }
    String defaultName = Platform.localHostname;
    if (defaultName.isEmpty || defaultName == 'localhost') {
      defaultName = '${getDeviceType()} Device';
    }
    await _prefs.setString(_deviceNameKey, defaultName);
    return defaultName;
  }

  Future<void> setDeviceName(String name) async {
    await _prefs.setString(_deviceNameKey, name);
  }

  String getDeviceType() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Desktop';
  }
}
