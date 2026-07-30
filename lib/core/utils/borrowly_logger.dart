import 'package:flutter/foundation.dart';

enum LogLevel { info, warning, error, event }

class BorrowlyLogger {
  static void log(String message, {LogLevel level = LogLevel.info, Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final prefix = switch (level) {
      LogLevel.info => 'ℹ️ [INFO]',
      LogLevel.warning => '⚠️ [WARNING]',
      LogLevel.error => '❌ [ERROR]',
      LogLevel.event => '🚀 [EVENT]',
    };

    debugPrint('$prefix [$timestamp] $message');
    if (error != null) {
      debugPrint('   Details: $error');
    }
    if (stackTrace != null) {
      debugPrint('   StackTrace: $stackTrace');
    }
  }

  static void event(String name, {Map<String, dynamic>? parameters}) {
    final paramStr = parameters != null ? ' | Params: $parameters' : '';
    log('Event Triggered: $name$paramStr', level: LogLevel.event);
  }

  static void info(String message) => log(message, level: LogLevel.info);
  static void warning(String message) => log(message, level: LogLevel.warning);
  static void error(String message, [Object? err, StackTrace? stack]) => log(message, level: LogLevel.error, error: err, stackTrace: stack);
}
