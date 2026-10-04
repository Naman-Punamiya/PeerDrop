import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peerdrop/features/discovery/data/udp_discovery_service.dart';
import 'package:peerdrop/features/discovery/presentation/discovery_controller.dart';
import 'package:peerdrop/features/discovery/presentation/discovery_state.dart';
import 'package:peerdrop/features/home/presentation/widgets/device_card.dart';
import 'package:peerdrop/features/settings/domain/app_settings.dart';
import 'package:peerdrop/features/settings/presentation/settings_controller.dart';
import '../helpers/test_helpers.dart';

class MockDiscoveryController extends StateNotifier<DiscoveryState> implements DiscoveryController {
  MockDiscoveryController([DiscoveryState? state]) : super(state ?? const DiscoveryState());

  int restartCallCount = 0;
  int startCallCount = 0;

  @override
  void initService({
    required String deviceId,
    required String deviceName,
    required String platform,
    required int tcpPort,
    required int discoveryPort,
    bool autoStart = false,
  }) {}

  @override
  Future<void> startDiscovery() async {
    startCallCount++;
    state = state.copyWith(status: DiscoveryServiceState.discovering);
  }

  @override
  Future<void> stopDiscovery() async {
    state = state.copyWith(status: DiscoveryServiceState.stopped);
  }

  @override
  Future<void> restartDiscovery() async {
    restartCallCount++;
  }

  @override
  void disposeService() {}
}

class MockSettingsController extends StateNotifier<AsyncValue<AppSettings>> implements SettingsController {
  MockSettingsController(AppSettings settings) : super(AsyncValue.data(settings));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testSettings = AppSettings(
    deviceId: '12345678-abcd-ef01-2345-6789abcdef01',
    deviceName: 'My Laptop',
    tcpPort: 4040,
    discoveryPort: 4041,
    downloadDirectory: '/downloads',
    autoDiscover: false,
  );

  testWidgets('DeviceCard displays device name, port, and truncated device ID', (tester) async {
    final mockDiscoveryController = MockDiscoveryController(
      const DiscoveryState(status: DiscoveryServiceState.discovering),
    );

    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          settingsControllerProvider.overrideWith((ref) => MockSettingsController(testSettings)),
          discoveryControllerProvider.overrideWith((ref) => mockDiscoveryController),
        ],
        child: const DeviceCard(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('My Laptop'), findsOneWidget);
    expect(find.textContaining('Port: 4040'), findsOneWidget);
    expect(find.text('Discovering'), findsOneWidget);
    expect(find.text('ID: 12345678'), findsOneWidget);
  });

  testWidgets('DeviceCard refresh button triggers discovery restart', (tester) async {
    final mockDiscoveryController = MockDiscoveryController(
      const DiscoveryState(status: DiscoveryServiceState.discovering),
    );

    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          settingsControllerProvider.overrideWith((ref) => MockSettingsController(testSettings)),
          discoveryControllerProvider.overrideWith((ref) => mockDiscoveryController),
        ],
        child: const DeviceCard(),
      ),
    );

    await tester.pumpAndSettle();

    final refreshButton = find.byIcon(Icons.refresh_rounded);
    expect(refreshButton, findsOneWidget);

    await tester.tap(refreshButton);
    await tester.pump();

    expect(mockDiscoveryController.restartCallCount, 1);
  });
}
