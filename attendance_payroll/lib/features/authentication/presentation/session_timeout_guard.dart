import 'dart:async';

import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/kiosk/domain/app_lock_service.dart';
import 'package:attendance_payroll/features/kiosk/presentation/app_lock_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long an administrator can leave the app untouched before it locks,
/// or `null` for never. Chosen by an administrator (Settings → App lock);
/// until it has loaded, the default applies.
final inactivityLimitProvider = Provider<Duration?>((ref) {
  final minutes =
      ref.watch(appLockMinutesProvider).value ?? AppLockService.defaultMinutes;
  return minutes == AppLockService.neverMinutes
      ? null
      : Duration(minutes: minutes);
});

/// The time source for the "left the app for a while" check. Timers do not
/// run while the app is in the background, so the time away is measured with
/// the clock. Replaced in tests.
final sessionClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Locks the app (shows the kiosk) after [inactivityLimitProvider] without
/// a touch, and when an administrator comes back to the app after being away
/// that long. The kiosk itself is never timed out: it is meant to stay open
/// for employees.
class SessionTimeoutGuard extends ConsumerStatefulWidget {
  const SessionTimeoutGuard({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<SessionTimeoutGuard> createState() =>
      _SessionTimeoutGuardState();
}

class _SessionTimeoutGuardState extends ConsumerState<SessionTimeoutGuard>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime? _leftAt;

  bool get _signedIn => ref.read(adminSessionProvider) != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref
      ..listenManual<bool>(
        adminSessionProvider.select((session) => session != null),
        (_, signedIn) => signedIn ? _restart() : _stop(),
        fireImmediately: true,
      )
      // A different time chosen while signed in applies straight away.
      ..listenManual<Duration?>(inactivityLimitProvider, (_, _) {
        if (_signedIn) {
          _restart();
        }
      });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _restart() {
    _timer?.cancel();
    final limit = ref.read(inactivityLimitProvider);
    _timer = limit == null ? null : Timer(limit, _expire);
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _leftAt = null;
  }

  void _expire() {
    if (!_signedIn) {
      return;
    }
    final minutes = ref.read(inactivityLimitProvider)?.inMinutes ?? 0;
    _stop();
    ref
        .read(authControllerProvider.notifier)
        .lock(
          reason:
              'The app locked after $minutes minutes without activity. Sign '
              'in to continue.',
        );
  }

  /// Any touch keeps the session alive.
  void _touched(PointerEvent _) {
    if (_timer != null) {
      _restart();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_signedIn) {
      return;
    }
    switch (state) {
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        _leftAt ??= ref.read(sessionClockProvider)();
      case AppLifecycleState.resumed:
        final left = _leftAt;
        _leftAt = null;
        final limit = ref.read(inactivityLimitProvider);
        final away = left == null
            ? Duration.zero
            : ref.read(sessionClockProvider)().difference(left);
        if (limit != null && away >= limit) {
          _expire();
        } else {
          _restart();
        }
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _touched,
      onPointerMove: _touched,
      onPointerSignal: _touched,
      child: widget.child,
    );
  }
}
