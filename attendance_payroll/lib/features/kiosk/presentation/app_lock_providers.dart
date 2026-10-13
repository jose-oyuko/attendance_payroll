import 'package:attendance_payroll/features/kiosk/data/kiosk_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Minutes before the app locks itself (0 for never). Read again after an
/// administrator changes it.
final appLockMinutesProvider = FutureProvider<int>((ref) async {
  return (await ref.watch(appLockServiceProvider).current()).unwrap();
});
