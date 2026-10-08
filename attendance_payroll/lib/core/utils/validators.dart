/// Small validation helpers shared by domain models.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// ISO 4217 alphabetic code, for example `KES`.
  static final RegExp _currencyCode = RegExp(r'^[A-Z]{3}$');

  static bool isBlank(String? value) => value == null || value.trim().isEmpty;

  static bool isEmail(String value) => _email.hasMatch(value);

  static bool isCurrencyCode(String value) => _currencyCode.hasMatch(value);

  /// Trims [value] and turns a blank string into `null`.
  static String? optional(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
