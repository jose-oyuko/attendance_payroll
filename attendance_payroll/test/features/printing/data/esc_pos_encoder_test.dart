import 'dart:convert';

import 'package:attendance_payroll/features/printing/data/esc_pos_encoder.dart';
import 'package:attendance_payroll/features/printing/domain/printer_models.dart';
import 'package:attendance_payroll/features/printing/domain/receipt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const narrow = EscPosEncoder(PaperWidth.mm58);
  const wide = EscPosEncoder(PaperWidth.mm80);

  /// The printable lines of [bytes], without the printer commands.
  List<String> linesOf(List<int> bytes) {
    final text = <int>[];
    for (var i = 0; i < bytes.length; i++) {
      final b = bytes[i];
      if (b == 0x1B) {
        // ESC @ is two bytes; ESC E / a / d are three.
        i += bytes[i + 1] == 0x40 ? 1 : 2;
      } else if (b == 0x1D) {
        // GS ! n and GS V n are three bytes.
        i += 2;
      } else {
        text.add(b);
      }
    }
    return const LineSplitter().convert(ascii.decode(text));
  }

  group('wrap', () {
    test('breaks at spaces within the width', () {
      expect(EscPosEncoder.wrap('Pay for October 2026 is ready', 12), [
        'Pay for',
        'October 2026',
        'is ready',
      ]);
    });

    test('splits a word longer than a line', () {
      expect(EscPosEncoder.wrap('Supercalifragilistic', 8), [
        'Supercal',
        'ifragili',
        'stic',
      ]);
    });

    test('keeps blank lines and short text as it is', () {
      expect(EscPosEncoder.wrap('One\n\nTwo', 32), ['One', '', 'Two']);
      expect(EscPosEncoder.wrap('', 32), ['']);
    });
  });

  group('columns', () {
    test('puts the value against the right edge', () {
      final line = narrow.columns('Gross pay', '94,250.00').single;

      expect(line.length, 32);
      expect(line, startsWith('Gross pay'));
      expect(line, endsWith('94,250.00'));
    });

    test('wraps a long label and keeps the value on its first line', () {
      final lines = narrow.columns(
        'Overtime allowance for the public holiday',
        '1,500.00',
      );

      expect(lines.first, endsWith('1,500.00'));
      expect(lines.first.length, 32);
      expect(lines.every((l) => l.length <= 32), isTrue);
      expect(lines.length, greaterThan(1));
    });

    test('gives a value that fills the line its own line', () {
      final value = 'KES ${'9' * 27}'; // 31 characters: no room for a label.
      final lines = narrow.columns('Net', value);

      expect(lines.first, 'Net');
      expect(lines.last, ' $value');
    });

    test('uses the width of the paper', () {
      expect(wide.columns('Net pay', '1.00').single.length, 48);
    });
  });

  group('encode', () {
    test('starts with a reset and ends with the defaults restored', () {
      final bytes = narrow.encode(
        const Receipt([ReceiptText('Hi', bold: true)]),
      );

      expect(bytes.take(2), [0x1B, 0x40]);
      expect(bytes, containsAllInOrder([0x1B, 0x45, 1]));
      expect(bytes.skip(bytes.length - 3), [0x1B, 0x45, 0]);
    });

    test('sends text, a rule and aligned columns', () {
      final bytes = narrow.encode(
        const Receipt([
          ReceiptText('ACME', align: ReceiptAlign.center),
          ReceiptRule(),
          ReceiptColumns('Net', '1.00'),
          ReceiptRule(double: true),
        ]),
      );

      final lines = linesOf(bytes);
      expect(lines[0], 'ACME');
      expect(lines[1], '-' * 32);
      expect(lines[2].length, 32);
      expect(lines[3], '=' * 32);
      expect(bytes, containsAllInOrder([0x1B, 0x61, 1]));
    });

    test('large text wraps at half the width and doubles the size', () {
      final bytes = narrow.encode(
        const Receipt([ReceiptText('KES 94,250.00 NET', large: true)]),
      );

      expect(bytes, containsAllInOrder([0x1D, 0x21, 0x11]));
      expect(linesOf(bytes).every((l) => l.length <= 16), isTrue);
    });

    test('feeds and cuts', () {
      final bytes = narrow.encode(
        const Receipt([ReceiptFeed(2), ReceiptCut()]),
      );

      expect(bytes, containsAllInOrder([0x1B, 0x64, 2]));
      expect(bytes, containsAllInOrder([0x1B, 0x64, 4, 0x1D, 0x56, 1]));
    });

    test('reduces accents and symbols to what every printer prints', () {
      final bytes = narrow.encode(
        const Receipt([ReceiptText('José Müller – 8 × 500 → ✓')]),
      );

      expect(linesOf(bytes).single, 'Jose Muller - 8 x 500 -> ?');
      expect(bytes.every((b) => b < 0x80), isTrue);
    });

    test('never lets a name inject printer commands', () {
      final bytes = narrow.encode(
        const Receipt([ReceiptText('Eve\x1B@\x1DV\x01Smith')]),
      );

      expect(linesOf(bytes).single, 'Eve@VSmith');
      expect(bytes.where((b) => b == 0x1D), isEmpty);
    });
  });
}
