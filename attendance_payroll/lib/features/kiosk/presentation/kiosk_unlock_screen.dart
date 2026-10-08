import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/utils/validators.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/shared/widgets/auth_panel.dart';
import 'package:attendance_payroll/shared/widgets/busy_button.dart';
import 'package:attendance_payroll/shared/widgets/failure_banner.dart';
import 'package:attendance_payroll/shared/widgets/password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The only way out of kiosk mode: an administrator signs in.
class KioskUnlockScreen extends ConsumerStatefulWidget {
  const KioskUnlockScreen({required this.kioskLocation, super.key});

  final String kioskLocation;

  @override
  ConsumerState<KioskUnlockScreen> createState() => _KioskUnlockScreenState();
}

class _KioskUnlockScreenState extends ConsumerState<KioskUnlockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final failure = await ref
        .read(authControllerProvider.notifier)
        .unlockKiosk(_username.text, _password.text);
    if (!mounted) {
      return;
    }
    _password.clear();
    setState(() {
      _busy = false;
      _error = failure?.userMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return AuthPanel(
      title: 'Leave kiosk mode',
      subtitle:
          'An administrator must sign in to stop using this device as the '
          'attendance kiosk.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            if (error != null) FailureBanner(message: error),
            TextFormField(
              controller: _username,
              decoration: const InputDecoration(labelText: 'Username'),
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  Validators.isBlank(value) ? 'Enter your username.' : null,
            ),
            PasswordField(
              controller: _password,
              label: 'Password',
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (value) =>
                  (value ?? '').isEmpty ? 'Enter your password.' : null,
            ),
            BusyButton(
              label: 'Sign in and leave kiosk',
              busy: _busy,
              onPressed: _submit,
            ),
            TextButton(
              onPressed: () => context.go(widget.kioskLocation),
              child: const Text('Back to the kiosk'),
            ),
          ],
        ),
      ),
    );
  }
}
