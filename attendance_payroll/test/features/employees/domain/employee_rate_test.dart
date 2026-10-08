import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/employees/domain/employee_rate.dart';
import 'package:flutter_test/flutter_test.dart';

EmployeeRate _rate(LocalDate from, LocalDate? to) {
  final now = DateTime.utc(2026);
  return EmployeeRate(
    id: 'r',
    employeeId: 'e',
    rateType: RateType.hourly,
    amountMinor: 50000,
    currencyCode: 'KES',
    effectiveFrom: from,
    effectiveTo: to,
    createdAt: now,
    updatedAt: now,
    version: 1,
  );
}

NewEmployeeRate _newRate({int amountMinor = 50000, String currency = 'KES'}) {
  return NewEmployeeRate(
    rateType: RateType.hourly,
    amountMinor: amountMinor,
    currencyCode: currency,
    effectiveFrom: LocalDate(2026, 1, 1),
  );
}

void main() {
  group('EmployeeRate.appliesOn', () {
    test('includes both the first and the last day', () {
      final rate = _rate(LocalDate(2026, 1, 1), LocalDate(2026, 6, 30));

      expect(rate.appliesOn(LocalDate(2025, 12, 31)), isFalse);
      expect(rate.appliesOn(LocalDate(2026, 1, 1)), isTrue);
      expect(rate.appliesOn(LocalDate(2026, 6, 30)), isTrue);
      expect(rate.appliesOn(LocalDate(2026, 7, 1)), isFalse);
      expect(rate.isCurrent, isFalse);
    });

    test('an open-ended rate applies from its start onwards', () {
      final rate = _rate(LocalDate(2026, 7, 1), null);

      expect(rate.isCurrent, isTrue);
      expect(rate.appliesOn(LocalDate(2030, 1, 1)), isTrue);
      expect(rate.appliesOn(LocalDate(2026, 6, 30)), isFalse);
    });
  });

  group('NewEmployeeRate', () {
    test('rejects zero and negative amounts', () {
      expect(_newRate(amountMinor: 0).validate()?.field, 'amount');
      expect(_newRate(amountMinor: -100).validate()?.field, 'amount');
      expect(_newRate().validate(), isNull);
    });

    test('normalises and validates the currency code', () {
      expect(_newRate(currency: ' kes ').normalized().currencyCode, 'KES');
      expect(_newRate(currency: 'KSH1').validate()?.field, 'currencyCode');
    });
  });
}
