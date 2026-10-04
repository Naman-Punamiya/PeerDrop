import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peerdrop/app/theme/app_theme.dart';

/// Wraps a widget under test with a MaterialApp and ProviderScope.
Widget createTestWidget({
  required Widget child,
  List<Override> overrides = const [],
  NavigatorObserver? navigatorObserver,
  ThemeData? theme,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      navigatorObservers: [
        if (navigatorObserver != null) navigatorObserver,
      ],
      home: Scaffold(body: child),
    ),
  );
}

/// Creates a test app with GoRouter or custom route configuration.
Widget createTestAppWithChild({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    ),
  );
}
