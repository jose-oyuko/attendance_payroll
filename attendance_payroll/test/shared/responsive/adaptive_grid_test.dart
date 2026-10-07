import 'package:attendance_payroll/shared/responsive/adaptive_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpGrid(
  WidgetTester tester, {
  required double width,
  int? maxColumns,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AdaptiveGrid(
          spacing: 16,
          maxColumns: maxColumns,
          children: [
            for (var i = 0; i < 4; i++)
              SizedBox(key: ValueKey<int>(i), height: 10),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('uses one full-width column on compact widths', (tester) async {
    await _pumpGrid(tester, width: 400);

    expect(tester.getSize(find.byKey(const ValueKey<int>(0))).width, 400);
  });

  testWidgets('splits the width into columns on expanded widths', (
    tester,
  ) async {
    await _pumpGrid(tester, width: 1000);

    // Expanded uses three columns: (1000 - 2 * 16) / 3.
    expect(
      tester.getSize(find.byKey(const ValueKey<int>(0))).width,
      closeTo((1000 - 32) / 3, 0.001),
    );
    // The fourth item wraps onto a second row.
    expect(
      tester.getTopLeft(find.byKey(const ValueKey<int>(3))).dy,
      greaterThan(tester.getTopLeft(find.byKey(const ValueKey<int>(0))).dy),
    );
  });

  testWidgets('respects maxColumns', (tester) async {
    await _pumpGrid(tester, width: 1000, maxColumns: 2);

    expect(
      tester.getSize(find.byKey(const ValueKey<int>(0))).width,
      closeTo((1000 - 16) / 2, 0.001),
    );
  });
}
