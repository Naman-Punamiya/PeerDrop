import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peerdrop/core/constants/app_constants.dart';
import 'package:peerdrop/features/settings/data/settings_repository.dart';
import 'package:peerdrop/features/settings/presentation/settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '/mock/path';
      },
    );
  });

  group('SettingsRepository Tests', () {
    test('loadSettings initializes default values when preferences are empty', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepository(prefs);

      final settings = await repository.loadSettings();

      expect(settings.deviceId, isNotEmpty);
      expect(settings.deviceName, isNotEmpty);
      expect(settings.tcpPort, AppConstants.defaultTcpPort);
      expect(settings.discoveryPort, AppConstants.defaultDiscoveryPort);
      expect(settings.downloadDirectory, isNotEmpty);
      expect(settings.autoDiscover, false);
    });

    test('loadSettings loads existing saved values from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefDeviceId: 'custom-device-123',
        AppConstants.prefDeviceName: 'Custom Phone',
        AppConstants.prefTcpPort: 5050,
        AppConstants.prefDiscoveryPort: 5051,
        AppConstants.prefDownloadDir: '/custom/downloads',
        AppConstants.prefAutoDiscover: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepository(prefs);

      final settings = await repository.loadSettings();

      expect(settings.deviceId, 'custom-device-123');
      expect(settings.deviceName, 'Custom Phone');
      expect(settings.tcpPort, 5050);
      expect(settings.discoveryPort, 5051);
      expect(settings.downloadDirectory, '/custom/downloads');
      expect(settings.autoDiscover, true);
    });

    test('saveDeviceName updates SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepository(prefs);

      await repository.saveDeviceName('New Name');
      expect(prefs.getString(AppConstants.prefDeviceName), 'New Name');
    });

    test('saveDownloadDirectory updates SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepository(prefs);

      await repository.saveDownloadDirectory('/downloads/path');
      expect(prefs.getString(AppConstants.prefDownloadDir), '/downloads/path');
    });

    test('saveTcpPort and saveDiscoveryPort update SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepository(prefs);

      await repository.saveTcpPort(8080);
      await repository.saveDiscoveryPort(8081);

      expect(prefs.getInt(AppConstants.prefTcpPort), 8080);
      expect(prefs.getInt(AppConstants.prefDiscoveryPort), 8081);
    });

    test('saveAutoDiscover updates SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepository(prefs);

      await repository.saveAutoDiscover(true);
      expect(prefs.getBool(AppConstants.prefAutoDiscover), true);
    });
  });

  group('SettingsController Tests', () {
    test('Loads initial settings and mutates state accurately', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefDeviceId: 'dev-1',
        AppConstants.prefDeviceName: 'Initial Device',
        AppConstants.prefDownloadDir: '/initial/downloads',
        AppConstants.prefAutoDiscover: false,
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepository(prefs);
      final controller = SettingsController(repository);

      // Await initial loading
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.state.value?.deviceName, 'Initial Device');

      // Test updating device name
      await controller.updateDeviceName('Updated Device');
      expect(controller.state.value?.deviceName, 'Updated Device');
      expect(prefs.getString(AppConstants.prefDeviceName), 'Updated Device');

      // Test updating auto discover
      await controller.updateAutoDiscover(true);
      expect(controller.state.value?.autoDiscover, true);
      expect(prefs.getBool(AppConstants.prefAutoDiscover), true);

      // Test updating download directory
      await controller.updateDownloadDirectory('/new/folder');
      expect(controller.state.value?.downloadDirectory, '/new/folder');
      expect(prefs.getString(AppConstants.prefDownloadDir), '/new/folder');

      // Test updating ports
      await controller.updateTcpPort(9000);
      await controller.updateDiscoveryPort(9001);
      expect(controller.state.value?.tcpPort, 9000);
      expect(controller.state.value?.discoveryPort, 9001);
    });
  });
}
