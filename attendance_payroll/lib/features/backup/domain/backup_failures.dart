import 'package:attendance_payroll/core/errors/app_failure.dart';

/// What can go wrong when backing up or restoring, in words the
/// administrator can act on. Technical detail goes in `cause`, never the
/// message.
abstract final class BackupFailures {
  static const String noPasswordRule = 'backup_no_password';
  static const String wrongPasswordRule = 'backup_wrong_password';
  static const String invalidFileRule = 'backup_invalid_file';
  static const String newerFormatRule = 'backup_newer_format';
  static const String newerSchemaRule = 'backup_newer_schema';
  static const String differentCompanyRule = 'backup_different_company';
  static const String kioskActiveRule = 'backup_kiosk_active';
  static const String notFreshRule = 'backup_not_fresh_install';
  static const String nothingToBackUpRule = 'backup_nothing_to_back_up';
  static const String verificationFailedRule = 'backup_verification_failed';
  static const String storageFailedRule = 'backup_storage_failed';
  static const String restoreFailedRule = 'backup_restore_failed';

  static const BusinessRuleFailure noPassword = BusinessRuleFailure(
    rule: noPasswordRule,
    userMessage:
        'This backup is protected with a password. Enter it to continue.',
  );

  static const BusinessRuleFailure wrongPassword = BusinessRuleFailure(
    rule: wrongPasswordRule,
    userMessage:
        'The password is wrong, or the backup file is damaged. Check the '
        'backup password and try again.',
  );

  static const BusinessRuleFailure invalidFile = BusinessRuleFailure(
    rule: invalidFileRule,
    userMessage: 'This is not a valid backup file, or it is incomplete.',
  );

  static const BusinessRuleFailure newerFormat = BusinessRuleFailure(
    rule: newerFormatRule,
    userMessage:
        'This backup was made by a newer version of the app. Update the app, '
        'then try again.',
  );

  static const BusinessRuleFailure newerSchema = BusinessRuleFailure(
    rule: newerSchemaRule,
    userMessage:
        'This backup holds data from a newer version of the app. Update the '
        'app, then try again.',
  );

  static const BusinessRuleFailure differentCompany = BusinessRuleFailure(
    rule: differentCompanyRule,
    userMessage:
        'This backup belongs to a different company than the one on this '
        'device. Restoring it replaces the company data on this device.',
  );

  static const BusinessRuleFailure kioskActive = BusinessRuleFailure(
    rule: kioskActiveRule,
    userMessage:
        'The app is locked. Unlock it with an administrator account before '
        'restoring a backup.',
  );

  static const BusinessRuleFailure notFresh = BusinessRuleFailure(
    rule: notFreshRule,
    userMessage:
        'This device already has company data. Sign in as an administrator '
        'to restore a backup.',
  );

  static const BusinessRuleFailure nothingToBackUp = BusinessRuleFailure(
    rule: nothingToBackUpRule,
    userMessage: 'There is no company data to back up yet.',
  );

  static const BusinessRuleFailure verificationFailed = BusinessRuleFailure(
    rule: verificationFailedRule,
    userMessage:
        'The backup could not be verified, so it was not kept. Please try '
        'again.',
  );

  static BusinessRuleFailure storageFailed(Object cause) => BusinessRuleFailure(
    rule: storageFailedRule,
    userMessage:
        'Could not read or write the backup on this device. Check that '
        'there is enough free space and try again.',
    cause: cause,
  );

  static BusinessRuleFailure restoreFailed(Object cause) => BusinessRuleFailure(
    rule: restoreFailedRule,
    userMessage:
        'The backup could not be restored. Your current data was not '
        'changed.',
    cause: cause,
  );
}
