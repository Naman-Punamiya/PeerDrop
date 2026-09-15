import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

class AppLogger {
  AppLogger._();

  static void debug(String message, {String tag = 'PeerDrop', Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void info(String message, {String tag = 'PeerDrop', Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, {String tag = 'PeerDrop', Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {String tag = 'PeerDrop', Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, {
    required String tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final prefix = switch (level) {
      LogLevel.debug => '🔍 [DEBUG]',
      LogLevel.info => 'ℹ️ [INFO]',
      LogLevel.warning => '⚠️ [WARN]',
      LogLevel.error => '❌ [ERROR]',
    };

    developer.log(
      '[$timestamp] $prefix [$tag] $message',
      name: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
