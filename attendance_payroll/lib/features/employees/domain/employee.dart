import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/core/utils/validators.dart';

/// Employment state. Employees are archived, never deleted, because
/// attendance and payroll history refers to them.
enum EmploymentStatus { active, inactive, suspended, archived }

/// Editable details of an employee.
final class EmployeeDetails {
  const EmployeeDetails({
    required this.employeeNumber,
    required this.firstName,
    required this.lastName,
    required this.employmentStartDate,
    this.middleName,
    this.displayName,
    this.phone,
    this.email,
    this.jobTitle,
    this.employmentStatus = EmploymentStatus.active,
    this.employmentEndDate,
  });

  static const int maxEmployeeNumberLength = 20;

  /// Company-assigned identifier shown on payslips; unique within the company.
  final String employeeNumber;
  final String firstName;
  final String? middleName;
  final String lastName;

  /// Preferred name, for example on the kiosk greeting. See [shownName].
  final String? displayName;
  final String? phone;
  final String? email;
  final String? jobTitle;
  final EmploymentStatus employmentStatus;
  final LocalDate employmentStartDate;
  final LocalDate? employmentEndDate;

  String get fullName => [firstName, ?middleName, lastName].join(' ');

  /// The name to show in the UI.
  String get shownName => displayName ?? fullName;

  /// A copy with text trimmed and blank optional fields removed.
  EmployeeDetails normalized() {
    return EmployeeDetails(
      employeeNumber: employeeNumber.trim(),
      firstName: firstName.trim(),
      middleName: Validators.optional(middleName),
      lastName: lastName.trim(),
      displayName: Validators.optional(displayName),
      phone: Validators.optional(phone),
      email: Validators.optional(email),
      jobTitle: Validators.optional(jobTitle),
      employmentStatus: employmentStatus,
      employmentStartDate: employmentStartDate,
      employmentEndDate: employmentEndDate,
    );
  }

  /// The first rule these details break, or `null` when they are valid.
  ValidationFailure? validate() {
    if (Validators.isBlank(employeeNumber)) {
      return const ValidationFailure(
        field: 'employeeNumber',
        userMessage: 'Enter an employee number.',
      );
    }
    if (employeeNumber.length > maxEmployeeNumberLength) {
      return const ValidationFailure(
        field: 'employeeNumber',
        userMessage:
            'Employee numbers can be at most '
            '$maxEmployeeNumberLength characters.',
      );
    }
    if (Validators.isBlank(firstName)) {
      return const ValidationFailure(
        field: 'firstName',
        userMessage: 'Enter a first name.',
      );
    }
    if (Validators.isBlank(lastName)) {
      return const ValidationFailure(
        field: 'lastName',
        userMessage: 'Enter a last name.',
      );
    }
    if (email case final email? when !Validators.isEmail(email)) {
      return const ValidationFailure(
        field: 'email',
        userMessage: 'Enter a valid email address.',
      );
    }
    if (employmentEndDate case final end?
        when end.isBefore(employmentStartDate)) {
      return const ValidationFailure(
        field: 'employmentEndDate',
        userMessage: 'The end date cannot be before the start date.',
      );
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    return other is EmployeeDetails &&
        other.employeeNumber == employeeNumber &&
        other.firstName == firstName &&
        other.middleName == middleName &&
        other.lastName == lastName &&
        other.displayName == displayName &&
        other.phone == phone &&
        other.email == email &&
        other.jobTitle == jobTitle &&
        other.employmentStatus == employmentStatus &&
        other.employmentStartDate == employmentStartDate &&
        other.employmentEndDate == employmentEndDate;
  }

  @override
  int get hashCode => Object.hash(
    employeeNumber,
    firstName,
    middleName,
    lastName,
    displayName,
    phone,
    email,
    jobTitle,
    employmentStatus,
    employmentStartDate,
    employmentEndDate,
  );
}

/// A persisted employee.
final class Employee {
  const Employee({
    required this.id,
    required this.companyId,
    required this.details,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  final String id;
  final String companyId;
  final EmployeeDetails details;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Pass back as `expectedVersion` when updating.
  final int version;
}
