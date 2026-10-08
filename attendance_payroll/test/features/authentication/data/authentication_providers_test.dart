import 'package:attendance_payroll/features/authentication/data/authentication_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production PIN hashing runs on a background isolate', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final hasher = container.read(pinHasherProvider);

    final encoded = await hasher.hash('2468');

    expect(hasher.iterations, greaterThanOrEqualTo(20000));
    expect(await hasher.verify('2468', encoded), isTrue);
    expect(await hasher.verify('8642', encoded), isFalse);
  });

  test('passwords use a higher work factor than PINs', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(passwordHasherProvider).iterations,
      greaterThan(container.read(pinHasherProvider).iterations),
    );
  });
}
