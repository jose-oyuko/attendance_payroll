import 'dart:async';

import 'package:attendance_payroll/app/router/app_router.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/employees/data/employee_providers.dart';
import 'package:attendance_payroll/features/reports/presentation/report_preview_screen.dart';
import 'package:attendance_payroll/features/reports/presentation/report_routes.dart';
import 'package:attendance_payroll/features/reports/presentation/report_view_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump_app.dart';
import '../../../support/test_database.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _settle(tester);
}

/// Pumps a few frames. The preview shows progress indicators that never
/// settle while a document is being made, so `pumpAndSettle` cannot be used.
Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Waits until the preview's document is ready (`null` if it failed).
///
/// The work started inside the test's fake time, so real time (for the
/// isolate and asset loading) and frames (for their callbacks) must
/// alternate; waiting on either alone never finishes.
Future<ReportFile?> _document(
  WidgetTester tester,
  ProviderContainer c,
  ReportRequest request,
) async {
  for (var i = 0; i < 600; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    switch (c.read(reportFileProvider(request))) {
      case AsyncData(:final value):
        await _frames(tester);
        return value;
      case AsyncError():
        await _frames(tester);
        return null;
      default:
    }
  }
  fail('The document was not produced in time.');
}

/// Stands in for the platform PDF viewer, which needs the printing plugin.
final _viewer = documentViewerProvider.overrideWithValue(
  (file) => Text('Viewing ${file.fileName}'),
);

void main() {
  testWidgets('every document is offered, by payroll and attendance', (
    tester,
  ) async {
    await pumpApp(tester, size: tabletSize);
    await _tap(tester, find.text('Reports'));

    for (final title in [
      'Payslips',
      'Payroll summary',
      'Attendance report',
      'Timesheet',
      'Exception report',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('an attendance report opens in the preview', (tester) async {
    final c = await pumpApp(tester, size: tabletSize, overrides: [_viewer]);
    await tester.runAsync(
      () => c
          .read(employeeManagementServiceProvider)
          .create(c.read(adminSessionProvider)!, johnDetails()),
    );
    await _tap(tester, find.text('Reports'));
    await _tap(tester, find.text('Attendance report'));
    expect(find.text('Up to 366 days.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Open'));
    await _frames(tester);

    expect(find.byType(ReportPreviewScreen), findsOneWidget);
    // The dialog's choice reached the preview through its location.
    final request = tester
        .widget<ReportPreviewScreen>(find.byType(ReportPreviewScreen))
        .request!;
    expect(request.kind, ReportKind.attendance);
    expect(request.from!.day, 1);
    final file = (await _document(tester, c, request))!;

    expect(file.fileName, startsWith('attendance-'));
    expect(find.text('Viewing ${file.fileName}'), findsOneWidget);
    expect(find.text(file.title), findsOneWidget);
  });

  testWidgets('a timesheet needs an employee', (tester) async {
    await pumpApp(tester, size: phoneSize);
    await _tap(tester, find.byTooltip('Open navigation menu'));
    await _tap(tester, find.text('Reports'));
    await _tap(tester, find.text('Timesheet'));

    await _tap(tester, find.widgetWithText(FilledButton, 'Open'));

    expect(find.text('Choose an employee.'), findsOneWidget);
    expect(find.byType(ReportPreviewScreen), findsNothing);
  });

  testWidgets('a document that cannot be made explains why', (tester) async {
    final c = await pumpApp(tester, size: tabletSize, overrides: [_viewer]);
    const request = ReportRequest(
      kind: ReportKind.payslips,
      periodId: 'missing',
    );
    unawaited(c.read(appRouterProvider).push(ReportRoutes.previewOf(request)));
    await _frames(tester);

    expect(await _document(tester, c, request), isNull);

    expect(find.textContaining('Viewing'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
  });

  test('requests survive the trip through the location', () {
    final request = ReportRequest(
      kind: ReportKind.timesheet,
      employeeId: 'e-1',
      from: LocalDate(2026, 10, 1),
      to: LocalDate(2026, 10, 31),
    );

    final location = Uri.parse(ReportRoutes.previewOf(request));

    expect(location.path, ReportRoutes.preview);
    expect(ReportRequest.fromQuery(location.queryParameters), request);
    // Incomplete requests are not guessed at.
    expect(ReportRequest.fromQuery({'kind': 'timesheet'}), isNull);
    expect(ReportRequest.fromQuery({'kind': 'payslips'}), isNull);
    expect(
      ReportRequest.fromQuery({'kind': 'attendance', 'from': 'x', 'to': 'y'}),
      isNull,
    );
  });
}
