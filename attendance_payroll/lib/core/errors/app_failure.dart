/// Structured application error.
///
/// Every layer below presentation reports problems as an [AppFailure] so the
/// UI never sees raw exceptions such as database or platform errors.
///
/// - [userMessage] is safe to show to the user.
/// - [cause] and [stackTrace] carry technical detail for logging only. They
///   are deliberately excluded from [toString] so they cannot leak into UI.
///
/// All subclasses live in this file so `switch` over a failure is exhaustive.
sealed class AppFailure implements Exception {
  const AppFailure({
    required this.code,
    required this.userMessage,
    this.cause,
    this.stackTrace,
  });

  /// Stable, machine-readable identifier (for logs and tests).
  final String code;

  /// Message that is safe to display to the user.
  final String userMessage;

  /// Underlying exception, for diagnostics only.
  final Object? cause;

  /// Stack trace captured where the failure was created, for diagnostics only.
  final StackTrace? stackTrace;

  /// Converts any thrown object into an [AppFailure].
  ///
  /// Existing failures are returned unchanged; anything else becomes an
  /// [UnexpectedFailure] that keeps the original error as its [cause].
  static AppFailure from(Object error, [StackTrace? stackTrace]) {
    if (error is AppFailure) {
      return error;
    }
    return UnexpectedFailure(cause: error, stackTrace: stackTrace);
  }

  @override
  String toString() => '$runtimeType($code)';
}

/// Input did not satisfy a validation rule.
final class ValidationFailure extends AppFailure {
  const ValidationFailure({
    required super.userMessage,
    this.field,
    super.cause,
    super.stackTrace,
  }) : super(code: 'validation');

  /// Name of the offending field, when the failure relates to a single field.
  final String? field;
}

/// A requested entity does not exist.
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({required this.entity, super.cause, super.stackTrace})
    : super(
        code: 'not_found',
        userMessage: 'The requested $entity could not be found.',
      );

  /// Human-readable entity name, for example `employee`.
  final String entity;
}

/// The operation conflicts with existing data (for example a duplicate).
final class ConflictFailure extends AppFailure {
  const ConflictFailure({
    required super.userMessage,
    super.cause,
    super.stackTrace,
  }) : super(code: 'conflict');
}

/// Credentials were missing, wrong or locked out.
final class AuthenticationFailure extends AppFailure {
  const AuthenticationFailure({
    super.userMessage =
        'Authentication failed. Please check your details and try again.',
    super.cause,
    super.stackTrace,
  }) : super(code: 'authentication');
}

/// The signed-in user is not allowed to perform the operation.
final class PermissionFailure extends AppFailure {
  const PermissionFailure({
    super.userMessage = 'You do not have permission to perform this action.',
    super.cause,
    super.stackTrace,
  }) : super(code: 'permission_denied');
}

/// A business rule rejected the operation (for example an invalid attendance
/// transition or a change to finalized payroll).
final class BusinessRuleFailure extends AppFailure {
  const BusinessRuleFailure({
    required this.rule,
    required super.userMessage,
    super.cause,
    super.stackTrace,
  }) : super(code: 'business_rule');

  /// Stable identifier of the rule that was violated.
  final String rule;
}

/// Reading or writing persistent storage failed.
final class DatabaseFailure extends AppFailure {
  const DatabaseFailure({
    super.userMessage = 'Unable to save your changes. Please try again.',
    super.cause,
    super.stackTrace,
  }) : super(code: 'database');
}

/// Anything that was not anticipated.
final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure({
    super.userMessage = 'Something went wrong. Please try again.',
    super.cause,
    super.stackTrace,
  }) : super(code: 'unexpected');
}
