import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/utils/validators.dart';

/// Editable details of a company.
final class CompanyDetails {
  const CompanyDetails({
    required this.name,
    required this.currencyCode,
    required this.timezone,
    this.legalName,
    this.registrationNumber,
    this.phone,
    this.email,
    this.address,
    this.logoPath,
  });

  final String name;
  final String? legalName;
  final String? registrationNumber;
  final String? phone;
  final String? email;
  final String? address;

  /// ISO 4217 code, for example `KES`.
  final String currencyCode;

  /// IANA timezone name used to interpret attendance, for example
  /// `Africa/Nairobi`.
  final String timezone;
  final String? logoPath;

  /// A copy with text trimmed, blank optional fields removed and the currency
  /// code upper-cased.
  CompanyDetails normalized() {
    return CompanyDetails(
      name: name.trim(),
      legalName: Validators.optional(legalName),
      registrationNumber: Validators.optional(registrationNumber),
      phone: Validators.optional(phone),
      email: Validators.optional(email),
      address: Validators.optional(address),
      currencyCode: currencyCode.trim().toUpperCase(),
      timezone: timezone.trim(),
      logoPath: Validators.optional(logoPath),
    );
  }

  /// The first rule these details break, or `null` when they are valid.
  ValidationFailure? validate() {
    if (Validators.isBlank(name)) {
      return const ValidationFailure(
        field: 'name',
        userMessage: 'Enter the company name.',
      );
    }
    if (email case final email? when !Validators.isEmail(email)) {
      return const ValidationFailure(
        field: 'email',
        userMessage: 'Enter a valid email address.',
      );
    }
    if (!Validators.isCurrencyCode(currencyCode)) {
      return const ValidationFailure(
        field: 'currencyCode',
        userMessage: 'Enter a three-letter currency code, for example KES.',
      );
    }
    if (!Validators.isTimezoneName(timezone)) {
      return const ValidationFailure(
        field: 'timezone',
        userMessage: 'Choose a valid timezone, for example Africa/Nairobi.',
      );
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    return other is CompanyDetails &&
        other.name == name &&
        other.legalName == legalName &&
        other.registrationNumber == registrationNumber &&
        other.phone == phone &&
        other.email == email &&
        other.address == address &&
        other.currencyCode == currencyCode &&
        other.timezone == timezone &&
        other.logoPath == logoPath;
  }

  @override
  int get hashCode => Object.hash(
    name,
    legalName,
    registrationNumber,
    phone,
    email,
    address,
    currencyCode,
    timezone,
    logoPath,
  );
}

/// A persisted company.
final class Company {
  const Company({
    required this.id,
    required this.details,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  final String id;
  final CompanyDetails details;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Pass back as `expectedVersion` when updating.
  final int version;
}
