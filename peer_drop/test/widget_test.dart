import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peerdrop/app/app.dart';
import 'package:peerdrop/features/history/data/history_repository.dart';
import 'package:peerdrop/features/history/presentation/history_controller.dart';
import 'package:peerdrop/features/settings/data/settings_repository.dart';
import 'package:peerdrop/features/settings/presentation/settings_controller.dart';

void main() {
  testWidgets('PeerDropApp renders HomeScreen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'peerdrop_device_id': 'test-device-id',
      'peerdrop_device_name': 'Test Device',
      'peerdrop_auto_discover': false,
    });

    final prefs = await SharedPreferences.getInstance();
    final settingsRepo = SettingsRepository(prefs);
    final historyRepo = HistoryRepository(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          historyRepositoryProvider.overrideWithValue(historyRepo),
        ],
        child: const PeerDropApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('PeerDrop'), findsWidgets);
    expect(find.text('Nearby Devices'), findsOneWidget);
  });
}
