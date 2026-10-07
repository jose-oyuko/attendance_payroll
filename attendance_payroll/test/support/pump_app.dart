import 'package:attendance_payroll/app/app.dart';
import 'package:attendance_payroll/app/configuration/app_config.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps the whole app at a logical screen [size].
Future<void> pumpApp(WidgetTester tester, {required Size size}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig.forEnvironment(AppEnvironment.development),
        ),
      ],
      child: const AttendancePayrollApp(),
    ),
  );
  await tester.pumpAndSettle();
}

const Size phoneSize = Size(400, 800);
const Size smallTabletSize = Size(700, 900);
const Size tabletSize = Size(1000, 800);
