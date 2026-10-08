import 'dart:io';

import 'package:attendance_payroll/core/database/app_database.dart';
import 'package:attendance_payroll/core/database/drift_device_identity_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the device id is created once and survives a restart', () async {
    final directory = await Directory.systemTemp.createTemp('device_id');
    addTearDown(() => directory.delete(recursive: true));
    AppDatabase open() =>
        AppDatabase(NativeDatabase(File('${directory.path}/app.db')));

    final first = open();
    final repository = DriftDeviceIdentityRepository(first);
    final id = (await repository.currentDeviceId()).unwrap();
    expect((await repository.currentDeviceId()).unwrap(), id);
    await first.close();

    final reopened = open();
    addTearDown(reopened.close);
    final again = await DriftDeviceIdentityRepository(
      reopened,
    ).currentDeviceId();

    expect(again.unwrap(), id);
    expect(await reopened.select(reopened.deviceIdentity).get(), hasLength(1));
  });
}
