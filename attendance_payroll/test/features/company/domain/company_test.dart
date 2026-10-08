import 'package:attendance_payroll/features/company/domain/company.dart';
import 'package:flutter_test/flutter_test.dart';

CompanyDetails _details({
  String name = 'Acme Ltd',
  String currencyCode = 'KES',
  String timezone = 'Africa/Nairobi',
  String? email,
}) {
  return CompanyDetails(
    name: name,
    currencyCode: currencyCode,
    timezone: timezone,
    email: email,
  );
}

void main() {
  group('CompanyDetails', () {
    test('normalized trims text and upper-cases the currency', () {
      final details = _details(
        name: ' Acme ',
        currencyCode: 'kes',
        email: '  ',
      ).normalized();

      expect(details.name, 'Acme');
      expect(details.currencyCode, 'KES');
      expect(details.email, isNull);
    });

    test('valid details pass, including UTC and nested zone names', () {
      expect(_details().validate(), isNull);
      expect(_details(timezone: 'UTC').validate(), isNull);
      expect(
        _details(timezone: 'America/Argentina/Buenos_Aires').validate(),
        isNull,
      );
    });

    test('each rule reports the offending field', () {
      final cases = <String, CompanyDetails>{
        'name': _details(name: ''),
        'currencyCode': _details(currencyCode: 'KESH'),
        'timezone': _details(timezone: 'Nairobi'),
        'email': _details(email: 'acme.example.com'),
      };

      cases.forEach((field, details) {
        expect(details.validate()?.field, field, reason: field);
      });
    });
  });
}
