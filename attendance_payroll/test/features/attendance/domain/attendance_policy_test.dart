import 'package:attendance_payroll/features/attendance/domain/attendance_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the defaults are valid', () {
    expect(const AttendancePolicy().validate(), isNull);
  });

  test('each value must be within its range', () {
    final cases = <String, AttendancePolicy>{
      'duplicateWindow': const AttendancePolicy(
        duplicateWindow: Duration(minutes: 61),
      ),
      'staleOpenSessionAfter': const AttendancePolicy(
        staleOpenSessionAfter: Duration(hours: 1),
      ),
      'excessiveDurationAfter': const AttendancePolicy(
        excessiveDurationAfter: Duration(hours: 25),
      ),
      'breakDeduct': const AttendancePolicy(
        automaticBreak: AutomaticBreak(
          after: Duration(hours: 6),
          deduct: Duration.zero,
        ),
      ),
      'breakAfter': const AttendancePolicy(
        automaticBreak: AutomaticBreak(
          after: Duration(minutes: 30),
          deduct: Duration(hours: 1),
        ),
      ),
    };

    cases.forEach((field, policy) {
      expect(policy.validate()?.field, field, reason: field);
    });
  });

  test('accepts values that suit a long night shift', () {
    const nightShift = AttendancePolicy(
      duplicateWindow: Duration(minutes: 5),
      staleOpenSessionAfter: Duration(hours: 20),
      excessiveDurationAfter: Duration(hours: 14),
      automaticBreak: AutomaticBreak(
        after: Duration(hours: 8),
        deduct: Duration(minutes: 45),
      ),
    );

    expect(nightShift.validate(), isNull);
  });

  test('context loaded around a range covers the longest session', () {
    const policy = AttendancePolicy(staleOpenSessionAfter: Duration(hours: 30));

    expect(policy.sessionLookaround, const Duration(hours: 60));
  });

  test('reports which settings changed', () {
    const before = AttendancePolicy();
    const after = AttendancePolicy(
      excessiveDurationAfter: Duration(hours: 10),
      automaticBreak: AutomaticBreak(
        after: Duration(hours: 6),
        deduct: Duration(hours: 1),
      ),
    );

    expect(after.changedFieldsFrom(before), [
      'excessiveDurationAfter',
      'automaticBreak',
    ]);
    expect(before.changedFieldsFrom(before), isEmpty);
  });
}
