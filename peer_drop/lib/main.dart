import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/logging/app_logger.dart';
import 'features/history/data/history_repository.dart';
import 'features/history/presentation/history_controller.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/settings/presentation/settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for mobile
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  AppLogger.info('Initializing PeerDrop application...', tag: 'App');

  // Initialize persistent repositories
  final prefs = await SharedPreferences.getInstance();
  final settingsRepo = SettingsRepository(prefs);
  final historyRepo = HistoryRepository(prefs);

  runApp(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        historyRepositoryProvider.overrideWithValue(historyRepo),
      ],
      child: const PeerDropApp(),
    ),
  );
}
