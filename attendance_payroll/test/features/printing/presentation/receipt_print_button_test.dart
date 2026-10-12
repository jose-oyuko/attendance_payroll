import 'dart:async';

import 'package:attendance_payroll/app/router/app_router.dart';
import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:attendance_payroll/features/printing/data/printing_providers.dart';
import 'package:attendance_payroll/features/printing/presentation/receipt_print_button.dart';
import 'package:attendance_payroll/features/reports/presentation/report_routes.dart';
import 'package:attendance_payroll/features/reports/presentation/report_view_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_printers.dart';
import '../../../support/pump_app.dart';

/// Stands in for the platform PDF viewer, which needs the printing plugin.
final _viewer = documentViewerProvider.overrideWithValue(
  (file) => Text('Viewing ${file.fileName}'),
);

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late FakeBluetoothGateway bluetooth;

  setUp(() => bluetooth = FakeBluetoothGateway());

  Future<ProviderContainer> openPreview(
    WidgetTester tester,
    ReportRequest request,
  ) async {
    final c = await pumpApp(
      tester,
      size: tabletSize,
      overrides: [
        _viewer,
        bluetoothGatewayProvider.overrideWithValue(bluetooth),
      ],
    );
    unawaited(c.read(appRouterProvider).push(ReportRoutes.previewOf(request)));
    await _frames(tester);
    return c;
  }

  testWidgets('payslips and the payroll summary can be printed on a receipt', (
    tester,
  ) async {
    await openPreview(
      tester,
      const ReportRequest(kind: ReportKind.payslips, periodId: 'p1'),
    );

    expect(find.byTooltip('Print receipt'), findsOneWidget);
  });

  testWidgets('attendance reports have no receipt', (tester) async {
    await openPreview(
      tester,
      ReportRequest(
        kind: ReportKind.attendance,
        from: LocalDate(2026, 10, 1),
        to: LocalDate(2026, 10, 31),
      ),
    );

    expect(find.byTooltip('Print receipt'), findsNothing);
  });

  testWidgets('a receipt that cannot be made says why, and prints nothing', (
    tester,
  ) async {
    await openPreview(
      tester,
      const ReportRequest(kind: ReportKind.payslips, periodId: 'missing'),
    );

    await tester.tap(find.byTooltip('Print receipt'));
    await _frames(tester);

    expect(find.byType(SnackBar), findsOneWidget);
    expect(bluetooth.written, isEmpty);
    // The button is available again for another try.
    expect(find.byTooltip('Print receipt'), findsOneWidget);
    expect(hasReceipt(ReportKind.payslips), isTrue);
  });
}
