import 'package:attendance_payroll/core/database/transaction_runner.dart';
import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/core/result/result.dart';
import 'package:attendance_payroll/core/utils/clock.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_correction.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_exception.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_reader.dart';
import 'package:attendance_payroll/features/attendance/domain/attendance_session.dart';
import 'package:attendance_payroll/features/audit/domain/audit_entry.dart';
import 'package:attendance_payroll/features/audit/domain/audit_log_repository.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_session.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';

/// The exception dashboard: lists attendance exceptions and records the
/// administrator's decisions about them.
///
/// Exceptions are derived from events (see `SessionBuilder`); only decisions
/// are stored. A decision is checked against the current data before it is
/// saved, so it always refers to an issue that really exists.
final class AttendanceExceptionService {
  AttendanceExceptionService({
    required this._reader,
    required this._reviews,
    required this._audit,
    required this._transactions,
    this._clock = systemClockUtc,
  });

  static const String mustCorrectRule = 'exception_must_be_corrected';
  static const String decisionNotAllowedRule = 'exception_decision_not_allowed';

  final AttendanceReader _reader;
  final ExceptionReviewRepository _reviews;
  final AuditLogRepository _audit;
  final TransactionRunner _transactions;
  final Clock _clock;

  /// Which decisions an issue type allows, besides noting it as reviewed.
  ///
  /// - A missing clock-out has no end time to accept: it must be corrected.
  /// - Overnight and excessive sessions can be accepted as recorded.
  /// - Informational issues can be dismissed (for lateness, early departure
  ///   and absence: excused).
  static Set<ReviewDecision> decisionsFor(AttendanceIssueType type) {
    return switch (type) {
      AttendanceIssueType.missingClockOut => {ReviewDecision.reviewed},
      AttendanceIssueType.overnightSession ||
      AttendanceIssueType.excessiveDuration => {
        ReviewDecision.reviewed,
        ReviewDecision.resolved,
      },
      AttendanceIssueType.duplicateClockIn ||
      AttendanceIssueType.duplicateClockOut ||
      AttendanceIssueType.clockOutWithoutClockIn ||
      AttendanceIssueType.lateArrival ||
      AttendanceIssueType.earlyDeparture ||
      AttendanceIssueType.missingAttendance => {
        ReviewDecision.reviewed,
        ReviewDecision.dismissed,
      },
    };
  }

  /// Exceptions revealed on company dates [from] to [to], newest first,
  /// including those settled by a decision or fixed by a correction since.
  Future<Result<List<AttendanceException>>> list(
    AdminSession session, {
    required LocalDate from,
    required LocalDate to,
  }) async {
    if (session.check(Permission.viewAttendance) case final denied?) {
      return Err(denied);
    }
    final snapshot = await _reader.read(session.companyId, from: from, to: to);
    return snapshot.map(_exceptionsOf);
  }

  /// Records [decision] about [exception], with a reason.
  Future<Result<ExceptionReview>> decide(
    AdminSession session,
    AttendanceException exception, {
    required ReviewDecision decision,
    required String reason,
  }) async {
    final invalid =
        session.check(Permission.correctAttendance) ??
        CorrectionReason.validate(reason);
    if (invalid != null) {
      return Err(invalid);
    }
    if (!decisionsFor(exception.type).contains(decision)) {
      return Err(
        BusinessRuleFailure(
          rule: exception.type == AttendanceIssueType.missingClockOut
              ? mustCorrectRule
              : decisionNotAllowedRule,
          userMessage: exception.type == AttendanceIssueType.missingClockOut
              ? 'Add the missing clock-out, or remove the clock-in if it was '
                    'a mistake.'
              : 'That decision does not apply to this kind of exception.',
        ),
      );
    }

    // Re-derive the employee's attendance to confirm the issue still exists.
    final snapshot = await _reader.read(
      session.companyId,
      from: _dateOf(exception, -1),
      to: _dateOf(exception, 1),
      employeeId: exception.employee.id,
    );
    if (snapshot case Err(:final failure)) {
      return Err(failure);
    }
    final current = snapshot
        .valueOrNull!
        .timelines[exception.employee.id]
        ?.issues
        .where((issue) => issue.key == exception.issueKey)
        .firstOrNull;
    if (current == null) {
      return const Err(
        ConflictFailure(
          userMessage:
              'This exception has changed or no longer applies. Reload and '
              'try again.',
        ),
      );
    }

    return _transactions.run(() async {
      final review = (await _reviews.record(
        NewExceptionReview(
          companyId: session.companyId,
          employeeId: exception.employee.id,
          issue: current,
          decision: decision,
          reason: reason,
          reviewedBy: session.admin.id,
          reviewedAt: _clock(),
        ),
      )).unwrap();
      (await _audit.record(
        AuditEntry(
          companyId: session.companyId,
          actorType: AuditActorType.admin,
          actorId: session.admin.id,
          action: AuditAction.attendanceExceptionReviewed,
          entityType: 'attendance_exception',
          entityId: review.issueKey,
          metadata: {
            'employeeId': review.employeeId,
            'type': review.issueType.name,
            'decision': review.decision.name,
          },
        ),
      )).unwrap();
      return review;
    });
  }

  /// A date [offset] days from the exception's UTC date. One day either
  /// side covers its company date whatever the timezone's offset.
  static LocalDate _dateOf(AttendanceException exception, int offset) {
    return LocalDate.fromDateTime(exception.occurredAt.toUtc()).addDays(offset);
  }

  static List<AttendanceException> _exceptionsOf(AttendanceSnapshot snapshot) {
    final employees = {for (final e in snapshot.employees) e.id: e};
    final reviewsByKey = <String, List<ExceptionReview>>{};
    for (final review in snapshot.reviews) {
      (reviewsByKey[review.issueKey] ??= []).add(review);
    }

    final exceptions = <AttendanceException>[];
    final seen = <String>{};
    for (final employee in snapshot.employees) {
      final timeline = snapshot.timelines[employee.id];
      final sessions = {
        for (final s in timeline?.sessions ?? const <AttendanceSession>[])
          s.key: s,
      };
      for (final issue in snapshot.issuesFor(employee.id)) {
        seen.add(issue.key);
        exceptions.add(
          AttendanceException(
            issueKey: issue.key,
            type: issue.type,
            occurredAt: issue.occurredAt,
            employee: employee,
            issue: issue,
            session: sessions[issue.sessionKey],
            reviews: reviewsByKey[issue.key] ?? const [],
          ),
        );
      }
    }

    // Exceptions that are no longer detected but were decided on or linked
    // to a correction: they stay visible as settled history.
    for (final entry in reviewsByKey.entries) {
      final first = entry.value.first;
      final employee = employees[first.employeeId];
      final inRange = _inRange(snapshot, first.issueOccurredAt);
      if (seen.contains(entry.key) || employee == null || !inRange) {
        continue;
      }
      exceptions.add(
        AttendanceException(
          issueKey: entry.key,
          type: first.issueType,
          occurredAt: first.issueOccurredAt,
          employee: employee,
          issue: null,
          session: null,
          reviews: entry.value,
        ),
      );
    }

    return exceptions..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  static bool _inRange(AttendanceSnapshot snapshot, DateTime instant) {
    final date = snapshot.timeZone.dateOf(instant);
    return !date.isBefore(snapshot.from) && !date.isAfter(snapshot.to);
  }
}
