/// How a printer is reached. Only Bluetooth is implemented; the others are
/// named so stored settings and the UI do not change when they arrive.
enum PrinterConnection { bluetooth, usb, network }

/// A printer the administrator can choose.
final class PrinterDevice {
  const PrinterDevice({
    required this.id,
    required this.name,
    required this.connection,
  });

  /// Where the printer is reached: the Bluetooth address, USB device id or
  /// network host.
  final String id;
  final String name;
  final PrinterConnection connection;

  @override
  bool operator ==(Object other) =>
      other is PrinterDevice &&
      other.id == id &&
      other.name == name &&
      other.connection == connection;

  @override
  int get hashCode => Object.hash(id, name, connection);
}

/// Width of the paper roll, which fixes how many characters fit on a line.
enum PaperWidth {
  mm58(characters: 32),
  mm80(characters: 48);

  const PaperWidth({required this.characters});

  /// Characters per line in the printer's standard font.
  final int characters;
}

/// The printer chosen on this device. Never shared with other devices: a
/// printer belongs to the place the device is in.
final class PrinterSettings {
  const PrinterSettings({this.device, this.paperWidth = PaperWidth.mm58});

  /// `null` until a printer has been chosen.
  final PrinterDevice? device;
  final PaperWidth paperWidth;

  PrinterSettings copyWith({
    PrinterDevice? device,
    bool clearDevice = false,
    PaperWidth? paperWidth,
  }) => PrinterSettings(
    device: clearDevice ? null : device ?? this.device,
    paperWidth: paperWidth ?? this.paperWidth,
  );
}

/// Whether a printer can be printed to right now.
enum PrinterStatus {
  /// The platform has no Bluetooth, or it is switched off.
  unavailable,

  /// The app may not use Bluetooth until the administrator allows it.
  permissionNeeded,

  /// Bluetooth works but no printer is connected.
  disconnected,
  connected,
}
