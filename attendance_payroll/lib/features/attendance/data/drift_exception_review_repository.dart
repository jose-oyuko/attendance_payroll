import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_guard.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/core/utils/id_generator.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_exception.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:drift/drift.dart';

final class DriftExceptionReviewRepository
    implements ExceptionReviewRepository {
  DriftExceptionReviewRepository(
    this._db, {
    this._clock = systemClockUtc,
    this._newId = generateUuidV7,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _newId;

  @override
  Future<Result<ExceptionReview>> record(NewExceptionReview review) {
    return guardDatabase(() async {
      final now = _clock();
      final issue = review.issue;
      final row = await _db
          .into(_db.exceptionReviews)
          .insertReturning(
            ExceptionReviewsCompanion.insert(
              id: _newId(),
              companyId: review.companyId,
              employeeId: review.employeeId,
              issueKey: issue.key,
              issueType: issue.type.name,
              eventId: issue.eventId,
              sessionKey: Value(issue.sessionKey),
              issueOccurredAt: issue.occurredAt,
              status: review.decision.name,
              reason: review.reason.trim(),
              reviewedBy: review.reviewedBy,
              reviewedAt: review.reviewedAt,
              relatedCorrectionId: Value(review.relatedCorrectionId),
              createdAt: now,
              updatedAt: now,
            ),
          );
      return _toDomain(row);
    });
  }

  @override
  Future<Result<List<ExceptionReview>>> forCompany(
    String companyId, {
    required DateTime from,
    required DateTime to,
  }) {
    return guardDatabase(() async {
      final rows =
          await (_db.select(_db.exceptionReviews)
                ..where(
                  (r) =>
                      r.companyId.equals(companyId) &
                      r.deletedAt.isNull() &
                      r.issueOccurredAt.isBiggerOrEqualValue(from) &
                      r.issueOccurredAt.isSmallerThanValue(to),
                )
                ..orderBy([
                  (r) => OrderingTerm.asc(r.reviewedAt),
                  (r) => OrderingTerm.asc(r.id),
                ]))
              .get();
      return rows.map(_toDomain).toList();
    });
  }

  ExceptionReview _toDomain(ExceptionReviewRow row) {
    return ExceptionReview(
      id: row.id,
      employeeId: row.employeeId,
      issueKey: row.issueKey,
      issueType: AttendanceIssueType.values.byName(row.issueType),
      eventId: row.eventId,
      sessionKey: row.sessionKey,
      issueOccurredAt: row.issueOccurredAt,
      decision: ReviewDecision.values.byName(row.status),
      reason: row.reason,
      reviewedBy: row.reviewedBy,
      reviewedAt: row.reviewedAt,
      relatedCorrectionId: row.relatedCorrectionId,
    );
  }
}
