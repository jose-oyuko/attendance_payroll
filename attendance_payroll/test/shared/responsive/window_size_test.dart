import 'package:attendance_payroll/shared/responsive/window_size.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WindowSize.fromWidth', () {
    test('maps widths to Material 3 size classes at the boundaries', () {
      const expectations = <double, WindowSize>{
        0: WindowSize.compact,
        399: WindowSize.compact,
        599.9: WindowSize.compact,
        600: WindowSize.medium,
        839.9: WindowSize.medium,
        840: WindowSize.expanded,
        1199.9: WindowSize.expanded,
        1200: WindowSize.large,
        1599.9: WindowSize.large,
        1600: WindowSize.extraLarge,
        3000: WindowSize.extraLarge,
      };

      expectations.forEach((width, expected) {
        expect(WindowSize.fromWidth(width), expected, reason: '$width');
      });
    });
  });

  group('WindowSize', () {
    test('isAtLeast compares size classes', () {
      expect(WindowSize.expanded.isAtLeast(WindowSize.medium), isTrue);
      expect(WindowSize.expanded.isAtLeast(WindowSize.expanded), isTrue);
      expect(WindowSize.medium.isAtLeast(WindowSize.expanded), isFalse);
    });

    test('grid columns never decrease as the window grows', () {
      final columns = WindowSize.values.map((s) => s.gridColumns).toList();

      expect(columns.first, 1);
      for (var i = 1; i < columns.length; i++) {
        expect(columns[i], greaterThanOrEqualTo(columns[i - 1]));
      }
    });

    test('page gutters never shrink as the window grows', () {
      final gutters = WindowSize.values.map((s) => s.pageGutter).toList();

      for (var i = 1; i < gutters.length; i++) {
        expect(gutters[i], greaterThanOrEqualTo(gutters[i - 1]));
      }
    });
  });
}
