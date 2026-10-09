import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:attendance_payroll/features/employees/domain/employee.dart';

/// Where an exception stands.
enum ExceptionStatus {
  /// Detected, nobody has looked at it yet.
  open,

  /// An administrator noted something but has not settled it; it still
  /// blocks payroll if its type does.
  reviewed,

  /// Settled: accepted as recorded, or fixed by a correction.
  resolved,

  /// Not a problem (for example a harmless double tap).
  dismissed;

  /// Still waiting for an administrator's decision.
  bool get needsAction => this == open || this == reviewed;
}

/// What an administrator decided. `open` is never stored.
enum ReviewDecision {
  reviewed,
  resolved,
  dismissed;

  ExceptionStatus get status => switch (this) {
    ReviewDecision.reviewed => ExceptionStatus.reviewed,
    ReviewDecision.resolved => ExceptionStatus.resolved,
    ReviewDecision.dismissed => ExceptionStatus.dismissed,
  };
}

/// One stored review decision about one exception.
final class ExceptionReview {
  const ExceptionReview({
    required this.id,
    required this.employeeId,
    required this.issueKey,
    required this.issueType,
    required this.eventId,
    required this.sessionKey,
    required this.issueOccurredAt,
    required this.decision,
    required this.reason,
    required this.reviewedBy,
    required this.reviewedAt,
    required this.relatedCorrectionId,
  });

  final String id;
  final String employeeId;
  final String issueKey;
  final AttendanceIssueType issueType;

  /// The event that revealed the issue; null for whole-day issues.
  final String? eventId;
  final String? sessionKey;
  final DateTime issueOccurredAt;
  final ReviewDecision decision;
  final String reason;
  final String reviewedBy;
  final DateTime reviewedAt;
  final String? relatedCorrectionId;
}

/// A decision to record.
final class NewExceptionReview {
  const NewExceptionReview({
    required this.companyId,
    required this.employeeId,
    required this.issue,
    required this.decision,
    required this.reason,
    required this.reviewedBy,
    required this.reviewedAt,
    this.relatedCorrectionId,
  });

  final String companyId;
  final String employeeId;
  final AttendanceIssue issue;
  final ReviewDecision decision;
  final String reason;
  final String reviewedBy;
  final DateTime reviewedAt;
  final String? relatedCorrectionId;
}

abstract interface class ExceptionReviewRepository {
  Future<Result<ExceptionReview>> record(NewExceptionReview review);

  /// Reviews of the company's exceptions that occurred in `[from, to)`,
  /// oldest decision first.
  Future<Result<List<ExceptionReview>>> forCompany(
    String companyId, {
    required DateTime from,
    required DateTime to,
  });
}

/// An attendance exception as the administrator sees it: the issue (if it is
/// still detected), its employee and session, and every review decision.
final class AttendanceException {
  const AttendanceException({
    required this.issueKey,
    required this.type,
    required this.occurredAt,
    required this.employee,
    required this.issue,
    required this.session,
    required this.reviews,
  });

  final String issueKey;
  final AttendanceIssueType type;

  /// When the event that revealed it happened.
  final DateTime occurredAt;
  final Employee employee;

  /// The issue as currently detected, or `null` when the data no longer
  /// shows it (typically after a correction).
  final AttendanceIssue? issue;

  /// The session it concerns, as currently derived, if any.
  final AttendanceSession? session;

  /// Decisions, oldest first.
  final List<ExceptionReview> reviews;

  ExceptionReview? get latestReview => reviews.lastOrNull;

  bool get stillDetected => issue != null;

  ExceptionStatus get status {
    final latest = latestReview;
    if (latest == null) {
      return ExceptionStatus.open;
    }
    // A note does not settle an issue that has since disappeared; the data
    // changed, so it no longer needs action.
    if (!stillDetected && latest.decision == ReviewDecision.reviewed) {
      return ExceptionStatus.resolved;
    }
    return latest.decision.status;
  }

  /// Whether it keeps the session's time out of payroll until settled.
  bool get blocksPayroll => type.blocksPayroll;
}
