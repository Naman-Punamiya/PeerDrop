import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peerdrop/app/app.dart';
import 'package:peerdrop/features/discovery/presentation/discovery_controller.dart';
import 'package:peerdrop/features/discovery/presentation/discovery_state.dart';
import 'package:peerdrop/features/file_transfer/domain/transfer_state.dart';
import 'package:peerdrop/features/file_transfer/presentation/transfer_controller.dart';
import 'package:peerdrop/features/history/data/history_repository.dart';
import 'package:peerdrop/features/history/presentation/history_controller.dart';
import 'package:peerdrop/features/history/presentation/history_screen.dart';
import 'package:peerdrop/features/settings/data/settings_repository.dart';
import 'package:peerdrop/features/settings/domain/app_settings.dart';
import 'package:peerdrop/features/settings/presentation/settings_controller.dart';
import 'package:peerdrop/features/settings/presentation/settings_screen.dart';

class MockNavDiscoveryController extends StateNotifier<DiscoveryState> implements DiscoveryController {
  MockNavDiscoveryController() : super(const DiscoveryState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockNavTransferController extends StateNotifier<TransferState> implements TransferController {
  MockNavTransferController() : super(TransferState.idleState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockNavSettingsController extends StateNotifier<AsyncValue<AppSettings>> implements SettingsController {
  MockNavSettingsController()
      : super(
          const AsyncValue.data(
            AppSettings(
              deviceId: 'nav-test-id',
              deviceName: 'Nav Device',
              tcpPort: 4040,
              discoveryPort: 4041,
              downloadDirectory: '/downloads',
              autoDiscover: false,
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App navigation flows between Home, History, and Settings', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settingsRepo = SettingsRepository(prefs);
    final historyRepo = HistoryRepository(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          settingsControllerProvider.overrideWith((ref) => MockNavSettingsController()),
          historyRepositoryProvider.overrideWithValue(historyRepo),
          discoveryControllerProvider.overrideWith((ref) => MockNavDiscoveryController()),
          transferControllerProvider.overrideWith((ref) => MockNavTransferController()),
        ],
        child: const PeerDropApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Home Screen
    expect(find.text('Nearby Devices'), findsOneWidget);

    // Navigate to History Screen
    final historyIcon = find.byTooltip('Transfer History');
    expect(historyIcon, findsOneWidget);
    await tester.tap(historyIcon);
    await tester.pumpAndSettle();

    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(find.text('Transfer History'), findsOneWidget);

    // Navigate back to Home
    final backButton = find.byType(BackButton);
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(find.text('Nearby Devices'), findsOneWidget);

    // Navigate to Settings Screen
    final settingsIcon = find.byTooltip('Settings');
    expect(settingsIcon, findsOneWidget);
    await tester.tap(settingsIcon);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Device Identity'), findsOneWidget);

    // Navigate back to Home
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Nearby Devices'), findsOneWidget);
  });
}
