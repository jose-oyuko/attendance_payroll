/// Converts between typed amounts and integer minor units (for example cents)
/// without ever passing through `double`.
abstract final class MinorUnits {
  /// Minor-unit digits used for display and input. ISO 4217 currencies such
  /// as KES, USD and EUR use two.
  static const int defaultDecimals = 2;

  static final RegExp _amount = RegExp(r'^(\d+)(?:\.(\d*))?$');

  /// Parses an amount such as `500`, `500.5`, `1,250.75` into minor units.
  /// Returns `null` for anything else, including negative amounts and more
  /// decimal places than the currency has.
  static int? parse(String input, {int decimals = defaultDecimals}) {
    final cleaned = input.trim().replaceAll(',', '');
    final match = _amount.firstMatch(cleaned);
    if (match == null) {
      return null;
    }
    final fraction = match[2] ?? '';
    if (fraction.length > decimals) {
      return null;
    }
    final whole = int.tryParse(match[1]!);
    final part = int.tryParse(fraction.padRight(decimals, '0').ifEmpty('0'));
    if (whole == null || part == null) {
      return null;
    }
    return whole * _scale(decimals) + part;
  }

  /// Formats minor units for display, for example `8825000` → `88,250.00`.
  static String format(int minorUnits, {int decimals = defaultDecimals}) {
    final negative = minorUnits < 0;
    final absolute = minorUnits.abs();
    final scale = _scale(decimals);
    final whole = _group((absolute ~/ scale).toString());
    final fraction = decimals == 0
        ? ''
        : '.${(absolute % scale).toString().padLeft(decimals, '0')}';
    return '${negative ? '-' : ''}$whole$fraction';
  }

  static int _scale(int decimals) {
    var scale = 1;
    for (var i = 0; i < decimals; i++) {
      scale *= 10;
    }
    return scale;
  }

  static String _group(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
