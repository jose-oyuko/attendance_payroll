import 'package:attendance_payroll/app/configuration/app_config.dart';
import 'package:attendance_payroll/core/logging/log_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppEnvironment.parse', () {
    test('parses known names case-insensitively', () {
      expect(AppEnvironment.parse('production'), AppEnvironment.production);
      expect(AppEnvironment.parse(' Staging '), AppEnvironment.staging);
      expect(AppEnvironment.parse('DEVELOPMENT'), AppEnvironment.development);
    });

    test('rejects unknown values instead of guessing', () {
      expect(() => AppEnvironment.parse('prod'), throwsFormatException);
    });
  });

  group('AppConfig', () {
    test('verbosity decreases towards production', () {
      expect(
        AppConfig.forEnvironment(AppEnvironment.development).logLevel,
        LogLevel.debug,
      );
      expect(
        AppConfig.forEnvironment(AppEnvironment.staging).logLevel,
        LogLevel.info,
      );
      expect(
        AppConfig.forEnvironment(AppEnvironment.production).logLevel,
        LogLevel.warning,
      );
    });

    test('isProduction is only true for production', () {
      expect(
        AppConfig.forEnvironment(AppEnvironment.production).isProduction,
        isTrue,
      );
      expect(
        AppConfig.forEnvironment(AppEnvironment.development).isProduction,
        isFalse,
      );
    });

    test('fromEnvironment defaults to development without --dart-define', () {
      expect(
        AppConfig.fromEnvironment().environment,
        AppEnvironment.development,
      );
    });
  });
}
