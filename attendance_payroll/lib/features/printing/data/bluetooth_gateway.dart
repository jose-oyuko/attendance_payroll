import 'dart:typed_data';

import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

/// A Bluetooth device the platform has paired.
final class BluetoothPeer {
  const BluetoothPeer({required this.address, required this.name});

  final String address;
  final String name;
}

/// What the app needs from the platform's classic Bluetooth. A seam around
/// the plugin: the printer service is tested with a fake, because a test
/// host has no Bluetooth, and another plugin could replace this one without
/// touching the service.
abstract interface class BluetoothGateway {
  /// Whether the app may use Bluetooth. On Android 12+ this shows the
  /// system permission prompt until the user answers, so call it when the
  /// administrator is acting on a printer, not in the background.
  Future<bool> ensurePermission();

  Future<bool> isEnabled();

  /// Devices already paired in the system settings.
  Future<List<BluetoothPeer>> pairedDevices();

  Future<bool> isConnected();

  /// `true` when the connection is open.
  Future<bool> connect(String address);

  Future<bool> disconnect();

  /// `true` when the printer took all of [bytes].
  Future<bool> write(Uint8List bytes);
}

/// [BluetoothGateway] over the `print_bluetooth_thermal` plugin.
final class PluginBluetoothGateway implements BluetoothGateway {
  const PluginBluetoothGateway();

  @override
  Future<bool> ensurePermission() =>
      PrintBluetoothThermal.isPermissionBluetoothGranted;

  @override
  Future<bool> isEnabled() => PrintBluetoothThermal.bluetoothEnabled;

  @override
  Future<List<BluetoothPeer>> pairedDevices() async => [
    for (final info in await PrintBluetoothThermal.pairedBluetooths)
      BluetoothPeer(address: info.macAdress, name: info.name),
  ];

  @override
  Future<bool> isConnected() => PrintBluetoothThermal.connectionStatus;

  @override
  Future<bool> connect(String address) =>
      PrintBluetoothThermal.connect(macPrinterAddress: address);

  @override
  Future<bool> disconnect() => PrintBluetoothThermal.disconnect;

  @override
  Future<bool> write(Uint8List bytes) =>
      PrintBluetoothThermal.writeBytes(bytes);
}
