import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/utils/validators.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/shared/widgets/auth_panel.dart';
import 'package:attendance_payroll/shared/widgets/busy_button.dart';
import 'package:attendance_payroll/shared/widgets/failure_banner.dart';
import 'package:attendance_payroll/shared/widgets/password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
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
        .signIn(_username.text, _password.text);
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
      title: 'Sign in',
      subtitle: 'Administrator access to attendance and payroll.',
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.md,
            children: [
              if (error != null) FailureBanner(message: error),
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(labelText: 'Username'),
                autocorrect: false,
                autofillHints: const [AutofillHints.username],
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
              BusyButton(label: 'Sign in', busy: _busy, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
