import 'package:attendance_payroll/app/theme/app_theme.dart';
import 'package:attendance_payroll/app/theme/semantic_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('builds Material 3 light and dark themes', () {
      final light = AppTheme.light();
      final dark = AppTheme.dark();

      expect(light.useMaterial3, isTrue);
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
    });

    test('both themes carry their semantic colours', () {
      expect(
        AppTheme.light().extension<SemanticColors>(),
        same(SemanticColors.light),
      );
      expect(
        AppTheme.dark().extension<SemanticColors>(),
        same(SemanticColors.dark),
      );
    });
  });

  group('SemanticColors', () {
    test('lerp returns the endpoints at t = 0 and t = 1', () {
      final atStart = SemanticColors.light.lerp(SemanticColors.dark, 0);
      final atEnd = SemanticColors.light.lerp(SemanticColors.dark, 1);

      expect(atStart.success.color, SemanticColors.light.success.color);
      expect(atEnd.success.color, SemanticColors.dark.success.color);
      expect(atEnd.neutral.container, SemanticColors.dark.neutral.container);
    });

    test('lerp ignores an unrelated extension', () {
      expect(SemanticColors.light.lerp(null, 0.5), same(SemanticColors.light));
    });

    test('copyWith replaces only the given set', () {
      final copy = SemanticColors.light.copyWith(
        warning: SemanticColors.dark.warning,
      );

      expect(copy.warning, same(SemanticColors.dark.warning));
      expect(copy.success, same(SemanticColors.light.success));
    });

    testWidgets('context.semanticColors follows the active theme', (
      tester,
    ) async {
      late SemanticColors seen;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              seen = context.semanticColors;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(seen, same(SemanticColors.light));
    });
  });
}
