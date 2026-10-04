import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peerdrop/features/settings/domain/app_settings.dart';
import 'package:peerdrop/features/settings/presentation/settings_controller.dart';
import 'package:peerdrop/features/settings/presentation/settings_screen.dart';
import '../helpers/test_helpers.dart';

class MockSettingsScreenController extends StateNotifier<AsyncValue<AppSettings>> implements SettingsController {
  MockSettingsScreenController(AppSettings settings) : super(AsyncValue.data(settings));

  String? updatedDeviceName;
  bool? updatedAutoDiscover;

  @override
  Future<void> updateDeviceName(String name) async {
    updatedDeviceName = name;
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(deviceName: name));
    }
  }

  @override
  Future<void> updateAutoDiscover(bool enabled) async {
    updatedAutoDiscover = enabled;
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(autoDiscover: enabled));
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const initialSettings = AppSettings(
    deviceId: 'test-dev-999',
    deviceName: 'Original Name',
    tcpPort: 4040,
    discoveryPort: 4041,
    downloadDirectory: '/storage/downloads',
    autoDiscover: false,
  );

  testWidgets('SettingsScreen displays identity, storage, networking and about sections', (tester) async {
    final mockController = MockSettingsScreenController(initialSettings);

    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          settingsControllerProvider.overrideWith((ref) => mockController),
        ],
        child: const SettingsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Device Identity'), findsOneWidget);
    expect(find.text('Original Name'), findsOneWidget);
    expect(find.text('test-dev-999'), findsOneWidget);
    expect(find.text('Storage & Downloads'), findsOneWidget);
    expect(find.text('/storage/downloads'), findsOneWidget);
    expect(find.text('Networking'), findsOneWidget);
    expect(find.text('Auto-start Discovery'), findsOneWidget);
    expect(find.text('TCP Transfer Port'), findsOneWidget);
    expect(find.text('UDP Discovery Port'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('About'), 100);
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('SettingsScreen allows editing device name', (tester) async {
    final mockController = MockSettingsScreenController(initialSettings);

    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          settingsControllerProvider.overrideWith((ref) => mockController),
        ],
        child: const SettingsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on Device Name tile
    await tester.tap(find.text('Device Name'));
    // Use pump instead of pumpAndSettle to handle autofocus cursor animation
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Edit Device Name'), findsOneWidget);
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    await tester.enterText(textField, 'Renamed Device');
    await tester.pump();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(mockController.updatedDeviceName, 'Renamed Device');
    expect(find.text('Renamed Device'), findsOneWidget);
  });

  testWidgets('SettingsScreen allows toggling auto-start discovery', (tester) async {
    final mockController = MockSettingsScreenController(initialSettings);

    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          settingsControllerProvider.overrideWith((ref) => mockController),
        ],
        child: const SettingsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(mockController.updatedAutoDiscover, true);
    final updatedSwitch = tester.widget<Switch>(switchFinder);
    expect(updatedSwitch.value, true);
  });
}
