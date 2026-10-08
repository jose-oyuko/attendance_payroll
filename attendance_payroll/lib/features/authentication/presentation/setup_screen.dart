import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:attendance_payroll/core/time/company_time_zone.dart';
import 'package:attendance_payroll/core/utils/validators.dart';
import 'package:attendance_payroll/features/authentication/domain/admin_user.dart';
import 'package:attendance_payroll/features/authentication/domain/password_policy.dart';
import 'package:attendance_payroll/features/authentication/presentation/auth_controller.dart';
import 'package:attendance_payroll/features/authentication/presentation/widgets/auth_panel.dart';
import 'package:attendance_payroll/features/company/domain/company.dart';
import 'package:attendance_payroll/shared/widgets/busy_button.dart';
import 'package:attendance_payroll/shared/widgets/failure_banner.dart';
import 'package:attendance_payroll/shared/widgets/password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// First-run setup: the company and its owner account.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  // Pre-filled, editable defaults for the market this app first targets.
  static const String defaultCurrency = 'KES';
  static const String defaultTimezone = 'Africa/Nairobi';

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyName = TextEditingController();
  final _currency = TextEditingController(text: SetupScreen.defaultCurrency);
  final _timezone = TextEditingController(text: SetupScreen.defaultTimezone);
  final _ownerName = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _companyName,
      _currency,
      _timezone,
      _ownerName,
      _username,
      _password,
      _confirm,
    ]) {
      controller.dispose();
    }
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
        .setUp(
          company: CompanyDetails(
            name: _companyName.text,
            currencyCode: _currency.text,
            timezone: _timezone.text,
          ),
          owner: NewAdminUser(
            username: _username.text,
            displayName: _ownerName.text,
          ),
          password: _password.text,
        );
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _error = failure?.userMessage;
    });
  }

  static String? _required(String? value, String message) {
    return Validators.isBlank(value) ? message : null;
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return AuthPanel(
      title: 'Set up your company',
      subtitle:
          'Create the company and the owner account. You can add employees '
          'once this is done.',
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.md,
            children: [
              if (error != null) FailureBanner(message: error),
              Text('Company', style: context.textStyles.titleSmall),
              TextFormField(
                controller: _companyName,
                decoration: const InputDecoration(labelText: 'Company name'),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (v) => _required(v, 'Enter the company name.'),
              ),
              TextFormField(
                controller: _currency,
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  helperText: 'Three-letter code, for example KES',
                ),
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    Validators.isCurrencyCode((v ?? '').trim().toUpperCase())
                    ? null
                    : 'Enter a three-letter currency code.',
              ),
              TextFormField(
                controller: _timezone,
                decoration: const InputDecoration(
                  labelText: 'Timezone',
                  helperText: 'For example Africa/Nairobi',
                ),
                autocorrect: false,
                textInputAction: TextInputAction.next,
                validator: (v) => CompanyTimeZone.isKnown((v ?? '').trim())
                    ? null
                    : 'Enter a timezone such as Africa/Nairobi.',
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('Owner account', style: context.textStyles.titleSmall),
              TextFormField(
                controller: _ownerName,
                decoration: const InputDecoration(labelText: 'Your name'),
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                validator: (v) => _required(v, 'Enter your name.'),
              ),
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(labelText: 'Username'),
                autocorrect: false,
                autofillHints: const [AutofillHints.newUsername],
                textInputAction: TextInputAction.next,
                validator: (v) => NewAdminUser(
                  username: v ?? '',
                  displayName: _ownerName.text,
                ).normalized().validate()?.userMessage,
              ),
              PasswordField(
                controller: _password,
                label: 'Password',
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                validator: (v) => PasswordPolicy.validate(v ?? '')?.userMessage,
              ),
              PasswordField(
                controller: _confirm,
                label: 'Confirm password',
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (v) =>
                    v == _password.text ? null : 'The passwords do not match.',
              ),
              Text(
                'Keep this password safe: this version has no password '
                'recovery.',
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              BusyButton(
                label: 'Create company',
                busy: _busy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
