import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peerdrop/core/constants/app_constants.dart';
import 'package:peerdrop/features/connection/domain/protocol_message.dart';
import 'package:peerdrop/features/discovery/data/udp_discovery_service.dart';
import 'package:peerdrop/features/discovery/domain/peer_device.dart';
import 'package:peerdrop/features/discovery/presentation/discovery_controller.dart';
import 'package:peerdrop/features/discovery/presentation/discovery_state.dart';
import 'package:peerdrop/features/file_transfer/domain/transfer_state.dart';
import 'package:peerdrop/features/file_transfer/presentation/transfer_controller.dart';
import 'package:peerdrop/features/file_transfer/presentation/widgets/incoming_transfer_dialog.dart';
import 'package:peerdrop/features/history/data/history_repository.dart';
import 'package:peerdrop/features/history/presentation/history_controller.dart';
import 'package:peerdrop/features/home/presentation/home_screen.dart';
import 'package:peerdrop/features/home/presentation/widgets/device_card.dart';
import 'package:peerdrop/features/home/presentation/widgets/peer_card.dart';
import 'package:peerdrop/features/settings/data/settings_repository.dart';
import 'package:peerdrop/features/settings/domain/app_settings.dart';
import 'package:peerdrop/features/settings/presentation/settings_controller.dart';
import '../helpers/test_helpers.dart';

class MockHomeControllerDiscovery extends StateNotifier<DiscoveryState> implements DiscoveryController {
  MockHomeControllerDiscovery(super.state);

  int startCalls = 0;
  int stopCalls = 0;

  @override
  Future<void> startDiscovery() async {
    startCalls++;
    state = state.copyWith(status: DiscoveryServiceState.discovering);
  }

  @override
  Future<void> stopDiscovery() async {
    stopCalls++;
    state = state.copyWith(status: DiscoveryServiceState.stopped, peers: const []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHomeTransferController extends StateNotifier<TransferState> implements TransferController {
  MockHomeTransferController() : super(TransferState.idleState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHomeScreenSettingsController extends StateNotifier<AsyncValue<AppSettings>> implements SettingsController {
  MockHomeScreenSettingsController()
      : super(
          const AsyncValue.data(
            AppSettings(
              deviceId: 'test-home-id',
              deviceName: 'Home Test Device',
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

  late SettingsRepository settingsRepo;
  late HistoryRepository historyRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      AppConstants.prefDeviceId: 'test-home-id',
      AppConstants.prefDeviceName: 'Home Test Device',
      AppConstants.prefDownloadDir: '/downloads',
      AppConstants.prefAutoDiscover: false,
    });
    final prefs = await SharedPreferences.getInstance();
    settingsRepo = SettingsRepository(prefs);
    historyRepo = HistoryRepository(prefs);
  });

  testWidgets('HomeScreen renders AppBar, DeviceCard, and paused discovery state', (tester) async {
    final discoveryMock = MockHomeControllerDiscovery(
      const DiscoveryState(status: DiscoveryServiceState.stopped, peers: []),
    );

    await tester.pumpWidget(
      createTestAppWithChild(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          settingsControllerProvider.overrideWith((ref) => MockHomeScreenSettingsController()),
          historyRepositoryProvider.overrideWithValue(historyRepo),
          discoveryControllerProvider.overrideWith((ref) => discoveryMock),
          transferControllerProvider.overrideWith((ref) => MockHomeTransferController()),
        ],
        child: const HomeScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('PeerDrop'), findsOneWidget);
    expect(find.byType(DeviceCard), findsOneWidget);
    expect(find.text('Nearby Devices'), findsOneWidget);
    expect(find.text('Discovery is Paused'), findsOneWidget);
    expect(find.text('Turn on the switch above to search for nearby devices'), findsOneWidget);
  });

  testWidgets('HomeScreen toggling discovery switch calls start/stop discovery', (tester) async {
    final discoveryMock = MockHomeControllerDiscovery(
      const DiscoveryState(status: DiscoveryServiceState.stopped, peers: []),
    );

    await tester.pumpWidget(
      createTestAppWithChild(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          settingsControllerProvider.overrideWith((ref) => MockHomeScreenSettingsController()),
          historyRepositoryProvider.overrideWithValue(historyRepo),
          discoveryControllerProvider.overrideWith((ref) => discoveryMock),
          transferControllerProvider.overrideWith((ref) => MockHomeTransferController()),
        ],
        child: const HomeScreen(),
      ),
    );

    await tester.pumpAndSettle();

    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    await tester.tap(switchFinder);
    await tester.pump();

    expect(discoveryMock.startCalls, 1);
  });

  testWidgets('HomeScreen displays searching spinner when discovering with 0 peers', (tester) async {
    final discoveryMock = MockHomeControllerDiscovery(
      const DiscoveryState(status: DiscoveryServiceState.discovering, peers: []),
    );

    await tester.pumpWidget(
      createTestAppWithChild(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          settingsControllerProvider.overrideWith((ref) => MockHomeScreenSettingsController()),
          historyRepositoryProvider.overrideWithValue(historyRepo),
          discoveryControllerProvider.overrideWith((ref) => discoveryMock),
          transferControllerProvider.overrideWith((ref) => MockHomeTransferController()),
        ],
        child: const HomeScreen(),
      ),
    );

    await tester.pump();

    expect(find.text('Searching for Nearby Peers...'), findsOneWidget);
  });

  testWidgets('HomeScreen renders discovered peer cards in list', (tester) async {
    final peer = PeerDevice(
      deviceId: 'p1',
      deviceName: 'Alice Tablet',
      platform: 'android',
      ipAddress: '192.168.1.55',
      tcpPort: 4040,
      lastSeen: DateTime.now(),
    );

    final discoveryMock = MockHomeControllerDiscovery(
      DiscoveryState(status: DiscoveryServiceState.discovering, peers: [peer]),
    );

    await tester.pumpWidget(
      createTestAppWithChild(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          settingsControllerProvider.overrideWith((ref) => MockHomeScreenSettingsController()),
          historyRepositoryProvider.overrideWithValue(historyRepo),
          discoveryControllerProvider.overrideWith((ref) => discoveryMock),
          transferControllerProvider.overrideWith((ref) => MockHomeTransferController()),
        ],
        child: const HomeScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(PeerCard), findsOneWidget);
    expect(find.text('Alice Tablet'), findsOneWidget);
  });

  testWidgets('HomeScreen shows error box when discovery has error', (tester) async {
    final discoveryMock = MockHomeControllerDiscovery(
      const DiscoveryState(status: DiscoveryServiceState.error, errorMessage: 'Socket bind failed'),
    );

    await tester.pumpWidget(
      createTestAppWithChild(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          settingsControllerProvider.overrideWith((ref) => MockHomeScreenSettingsController()),
          historyRepositoryProvider.overrideWithValue(historyRepo),
          discoveryControllerProvider.overrideWith((ref) => discoveryMock),
          transferControllerProvider.overrideWith((ref) => MockHomeTransferController()),
        ],
        child: const HomeScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Socket bind failed'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('HomeScreen triggers IncomingTransferDialog when incomingRequestProvider is set', (tester) async {
    final discoveryMock = MockHomeControllerDiscovery(
      const DiscoveryState(status: DiscoveryServiceState.stopped, peers: []),
    );

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        settingsControllerProvider.overrideWith((ref) => MockHomeScreenSettingsController()),
        historyRepositoryProvider.overrideWithValue(historyRepo),
        discoveryControllerProvider.overrideWith((ref) => discoveryMock),
        transferControllerProvider.overrideWith((ref) => MockHomeTransferController()),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(IncomingTransferDialog), findsNothing);

    // Set incoming request
    container.read(incomingRequestProvider.notifier).state = const FileTransferRequestPayload(
      transferId: 'inc-99',
      filename: 'family_photo.png',
      fileSize: 1024 * 1024,
      mimeType: 'image/png',
      sha256: 'hash-xyz',
      senderDeviceId: 'peer-sender-1',
      senderDeviceName: 'Bob Phone',
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(IncomingTransferDialog), findsOneWidget);
    expect(find.text('family_photo.png'), findsOneWidget);
  });

  testWidgets('HomeScreen renders desktop layout on wide screens', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final discoveryMock = MockHomeControllerDiscovery(
      const DiscoveryState(status: DiscoveryServiceState.stopped, peers: []),
    );

    await tester.pumpWidget(
      createTestAppWithChild(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          settingsControllerProvider.overrideWith((ref) => MockHomeScreenSettingsController()),
          historyRepositoryProvider.overrideWithValue(historyRepo),
          discoveryControllerProvider.overrideWith((ref) => discoveryMock),
          transferControllerProvider.overrideWith((ref) => MockHomeTransferController()),
        ],
        child: const HomeScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Desktop layout contains VerticalDivider separating columns
    expect(find.byType(VerticalDivider), findsOneWidget);
    expect(find.text('PeerDrop'), findsOneWidget);
  });
}
