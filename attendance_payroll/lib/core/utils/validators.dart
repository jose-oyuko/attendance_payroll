/// Small validation helpers shared by domain models.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// ISO 4217 alphabetic code, for example `KES`.
  static final RegExp _currencyCode = RegExp(r'^[A-Z]{3}$');

  /// IANA timezone name such as `Africa/Nairobi`, or `UTC`. Only the shape is
  /// checked here; resolving the name against the timezone database belongs to
  /// the attendance engine (Phase 3).
  static final RegExp _timezoneName = RegExp(
    r'^(UTC|[A-Za-z]+(/[A-Za-z0-9_+\-]+)+)$',
  );

  static bool isBlank(String? value) => value == null || value.trim().isEmpty;

  static bool isEmail(String value) => _email.hasMatch(value);

  static bool isCurrencyCode(String value) => _currencyCode.hasMatch(value);

  static bool isTimezoneName(String value) => _timezoneName.hasMatch(value);

  /// Trims [value] and turns a blank string into `null`.
  static String? optional(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
