import 'package:attendance_payroll/core/errors/app_failure.dart';

/// Outcome of an operation that can fail in an expected way.
///
/// Repositories and domain services return a [Result] instead of throwing, so
/// callers must handle the failure case explicitly.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;

  const factory Result.err(AppFailure failure) = Err<T>;

  /// Runs [action] and converts anything it throws into an [Err].
  static Future<Result<T>> guard<T>(Future<T> Function() action) async {
    try {
      return Ok<T>(await action());
    } on Object catch (error, stackTrace) {
      return Err<T>(AppFailure.from(error, stackTrace));
    }
  }

  bool get isOk => this is Ok<T>;

  bool get isErr => this is Err<T>;

  /// The value when successful, otherwise `null`.
  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  /// The failure when unsuccessful, otherwise `null`.
  AppFailure? get failureOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final failure) => failure,
  };

  /// The value when successful; otherwise throws the [AppFailure].
  ///
  /// Use inside a transaction, where a failed step must throw so that the
  /// whole transaction rolls back. Everywhere else, handle both cases.
  T unwrap() {
    return switch (this) {
      Ok<T>(:final value) => value,
      Err<T>(:final failure) => throw failure,
    };
  }

  /// Collapses the result into a single value.
  R fold<R>(R Function(T value) onOk, R Function(AppFailure failure) onErr) {
    return switch (this) {
      Ok<T>(:final value) => onOk(value),
      Err<T>(:final failure) => onErr(failure),
    };
  }

  /// Transforms a successful value and leaves a failure untouched.
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Ok<T>(:final value) => Ok<R>(transform(value)),
      Err<T>(:final failure) => Err<R>(failure),
    };
  }
}

/// Successful [Result].
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

/// Failed [Result].
final class Err<T> extends Result<T> {
  const Err(this.failure);

  final AppFailure failure;
}
