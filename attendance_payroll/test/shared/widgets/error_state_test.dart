import 'package:attendance_payroll/core/errors/app_failure.dart';
import 'package:attendance_payroll/shared/widgets/empty_state.dart';
import 'package:attendance_payroll/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ErrorState shows the user message, never the cause', (
    tester,
  ) async {
    final failure = AppFailure.from(
      StateError('SqliteException: UNIQUE constraint failed'),
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ErrorState(failure: failure))),
    );

    expect(find.text(failure.userMessage), findsOneWidget);
    expect(find.textContaining('Sqlite'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('ErrorState retry button calls back', (tester) async {
    var retries = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorState(
            failure: const DatabaseFailure(),
            onRetry: () => retries++,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Try again'));

    expect(retries, 1);
  });

  testWidgets('EmptyState renders title, message and action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.people_outline,
            title: 'No employees yet.',
            message: 'Add your first employee to get started.',
            action: FilledButton(
              onPressed: () {},
              child: const Text('Add employee'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('No employees yet.'), findsOneWidget);
    expect(find.text('Add your first employee to get started.'), findsOneWidget);
    expect(find.text('Add employee'), findsOneWidget);
  });
}
