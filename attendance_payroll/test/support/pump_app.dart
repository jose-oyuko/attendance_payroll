import 'package:attendance_payroll/app/app.dart';
import 'package:attendance_payroll/app/configuration/app_config.dart';
import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/database_providers.dart';
import 'package:attendance_payroll/features/authentication/data/authentication_providers.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_database.dart';
import 'test_env.dart';

/// Pumps the whole app at a logical screen [size] over a fresh in-memory
/// database. Unless [signedIn] is false, first-run setup is completed so the
/// test starts on the dashboard as the owner.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  required Size size,
  bool signedIn = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig.forEnvironment(AppEnvironment.development),
        ),
        appDatabaseProvider.overrideWithValue(database),
        passwordHasherProvider.overrideWithValue(fastHasher()),
        pinHasherProvider.overrideWithValue(fastHasher()),
      ],
      child: const AttendancePayrollApp(),
    ),
  );
  await tester.pumpAndSettle();

  final container = ProviderScope.containerOf(
    tester.element(find.byType(AttendancePayrollApp)),
  );
  if (signedIn) {
    await tester.runAsync(
      () => container
          .read(authControllerProvider.notifier)
          .setUp(
            company: acmeDetails,
            owner: const NewAdminUser(
              username: ownerUsername,
              displayName: 'Jane Owner',
            ),
            password: ownerPassword,
          ),
    );
    await tester.pumpAndSettle();
  }
  return container;
}

const Size phoneSize = Size(400, 800);
const Size smallTabletSize = Size(700, 900);
const Size tabletSize = Size(1000, 800);
