import 'package:attendance_payroll/core/logging/app_logger.dart';
import 'package:flutter/foundation.dart';

/// Routes uncaught framework and asynchronous errors to [logger].
///
/// Technical detail goes to the log; nothing here is shown to the user.
void installGlobalErrorHandlers(AppLogger logger) {
  FlutterError.onError = (FlutterErrorDetails details) {
    logger.error(
      'flutter',
      'Unhandled framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    logger.error(
      'platform',
      'Unhandled asynchronous error',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };
}
