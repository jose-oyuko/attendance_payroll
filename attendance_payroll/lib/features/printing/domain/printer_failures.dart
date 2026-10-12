import 'package:attendance_payroll/core/errors/app_failure.dart';

/// What can go wrong between the app and a printer, in words the
/// administrator can act on. Technical detail goes in `cause`, never the
/// message.
abstract final class PrinterFailures {
  static const String notConfiguredRule = 'printer_not_configured';
  static const String bluetoothOffRule = 'printer_bluetooth_off';
  static const String permissionRule = 'printer_permission_needed';
  static const String connectFailedRule = 'printer_connect_failed';
  static const String printFailedRule = 'printer_print_failed';
  static const String unsupportedRule = 'printer_unsupported_connection';

  static const BusinessRuleFailure notConfigured = BusinessRuleFailure(
    rule: notConfiguredRule,
    userMessage: 'Choose a printer first, in Settings → Printer.',
  );

  static const BusinessRuleFailure bluetoothOff = BusinessRuleFailure(
    rule: bluetoothOffRule,
    userMessage: 'Bluetooth is switched off. Turn it on and try again.',
  );

  static const BusinessRuleFailure permissionNeeded = BusinessRuleFailure(
    rule: permissionRule,
    userMessage:
        'Allow this app to use nearby devices (Bluetooth) in the phone '
        'settings, then try again.',
  );

  static BusinessRuleFailure connectFailed(String printerName) =>
      BusinessRuleFailure(
        rule: connectFailedRule,
        userMessage:
            'Could not connect to $printerName. Check that it is switched '
            'on, in range and paired with this device.',
      );

  static const BusinessRuleFailure printFailed = BusinessRuleFailure(
    rule: printFailedRule,
    userMessage:
        'The printer did not accept the document. Check the paper and the '
        'connection, then try again.',
  );

  static const BusinessRuleFailure unsupported = BusinessRuleFailure(
    rule: unsupportedRule,
    userMessage: 'This kind of printer connection is not supported yet.',
  );
}
