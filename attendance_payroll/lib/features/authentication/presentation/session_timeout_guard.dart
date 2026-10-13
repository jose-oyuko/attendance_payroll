import 'dart:async';

import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long an administrator can leave the app untouched before it signs
/// them out. Payroll data is sensitive and the device may be left on a desk.
final inactivityLimitProvider = Provider<Duration>(
  (ref) => const Duration(minutes: 15),
);

/// The time source for the "left the app for a while" check. Timers do not
/// run while the app is in the background, so the time away is measured with
/// the clock. Replaced in tests.
final sessionClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Signs the administrator out after [inactivityLimitProvider] without a
/// touch, and when they come back to the app after being away that long.
/// Kiosk mode is never timed out: it is meant to stay open.
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
    ref.listenManual<bool>(
      adminSessionProvider.select((session) => session != null),
      (_, signedIn) => signedIn ? _restart() : _stop(),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _restart() {
    _timer?.cancel();
    _timer = Timer(ref.read(inactivityLimitProvider), _expire);
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
    final minutes = ref.read(inactivityLimitProvider).inMinutes;
    _stop();
    ref
        .read(authControllerProvider.notifier)
        .signOut(
          reason:
              'You were signed out after $minutes minutes without activity. '
              'Sign in again to continue.',
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
        final away = left == null
            ? Duration.zero
            : ref.read(sessionClockProvider)().difference(left);
        if (away >= ref.read(inactivityLimitProvider)) {
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
