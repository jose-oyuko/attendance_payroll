import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';
import 'package:flutter_test/flutter_test.dart';

EmployeeDetails _details({
  String employeeNumber = 'E001',
  String firstName = 'John',
  String lastName = 'Kamau',
  String? middleName,
  String? displayName,
  String? email,
  LocalDate? endDate,
}) {
  return EmployeeDetails(
    employeeNumber: employeeNumber,
    firstName: firstName,
    lastName: lastName,
    middleName: middleName,
    displayName: displayName,
    email: email,
    employmentStartDate: LocalDate(2026, 1, 1),
    employmentEndDate: endDate,
  );
}

void main() {
  group('EmployeeDetails', () {
    test('normalized trims text and drops blank optional fields', () {
      final details = _details(
        employeeNumber: '  E001 ',
        firstName: ' John',
        middleName: '   ',
        email: ' john@example.com ',
      ).normalized();

      expect(details.employeeNumber, 'E001');
      expect(details.firstName, 'John');
      expect(details.middleName, isNull);
      expect(details.email, 'john@example.com');
    });

    test('valid details pass', () {
      expect(_details().validate(), isNull);
    });

    test('each rule reports the offending field', () {
      final cases = <String, EmployeeDetails>{
        'employeeNumber': _details(employeeNumber: ''),
        'firstName': _details(firstName: ' '),
        'lastName': _details(lastName: ''),
        'email': _details(email: 'not-an-email'),
        'employmentEndDate': _details(endDate: LocalDate(2025, 12, 31)),
      };

      cases.forEach((field, details) {
        expect(details.validate()?.field, field, reason: field);
      });
    });

    test('employee numbers have a maximum length', () {
      final tooLong = _details(
        employeeNumber: 'E' * (EmployeeDetails.maxEmployeeNumberLength + 1),
      );

      expect(tooLong.validate()?.field, 'employeeNumber');
    });

    test('an end date on the start date is allowed', () {
      expect(_details(endDate: LocalDate(2026, 1, 1)).validate(), isNull);
    });

    test('shownName prefers the display name over the full name', () {
      expect(_details(middleName: 'Mwangi').fullName, 'John Mwangi Kamau');
      expect(_details().shownName, 'John Kamau');
      expect(_details(displayName: 'Johnny').shownName, 'Johnny');
    });
  });
}
