/// Masks values whose keys indicate secrets before they are logged.
///
/// Matching is token based: a key is split on camelCase and non-alphanumeric
/// boundaries, so `employeePin` and `password_hash` are masked while
/// `shipping` and `mapping` are not.
///
/// This only protects structured `fields`. Never put a secret in a log
/// message string.
abstract final class Redactor {
  static const String mask = '***';

  static const Set<String> _sensitiveTokens = <String>{
    'authorization',
    'credential',
    'credentials',
    'hash',
    'passcode',
    'password',
    'pin',
    'salt',
    'secret',
    'token',
  };

  static final RegExp _camelBoundary = RegExp('([a-z0-9])([A-Z])');
  static final RegExp _nonAlphanumeric = RegExp('[^a-z0-9]+');

  /// Whether a field with this [key] must be masked.
  static bool isSensitiveKey(String key) {
    final normalised = key
        .replaceAllMapped(_camelBoundary, (match) => '${match[1]}_${match[2]}')
        .toLowerCase();
    return normalised.split(_nonAlphanumeric).any(_sensitiveTokens.contains);
  }

  /// Returns a copy of [fields] with sensitive values masked, recursing into
  /// nested maps and lists.
  static Map<String, Object?> redactMap(Map<String, Object?> fields) {
    return <String, Object?>{
      for (final entry in fields.entries)
        entry.key: isSensitiveKey(entry.key)
            ? mask
            : _redactValue(entry.value),
    };
  }

  static Object? _redactValue(Object? value) {
    return switch (value) {
      final Map<Object?, Object?> map => redactMap(<String, Object?>{
        for (final entry in map.entries) '${entry.key}': entry.value,
      }),
      final List<Object?> list => list.map(_redactValue).toList(),
      _ => value,
    };
  }
}
