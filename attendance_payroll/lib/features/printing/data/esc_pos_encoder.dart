import 'dart:typed_data';

import 'package:attendance_payroll/features/printing/domain/printer_models.dart';
import 'package:attendance_payroll/features/printing/domain/receipt.dart';

/// Turns a [Receipt] into ESC/POS, the command set nearly every thermal
/// receipt printer understands, laid out for the paper in use.
///
/// Text is sent as plain ASCII: printers differ in their code pages, so
/// accents are reduced to their base letters instead of risking garbled
/// names ("José" prints as "Jose").
final class EscPosEncoder {
  const EscPosEncoder(this.paperWidth);

  final PaperWidth paperWidth;

  static const int _esc = 0x1B;
  static const int _gs = 0x1D;

  /// Paper fed before a cut, so the cut does not fall through the text (the
  /// cutter sits a few millimetres after the print head).
  static const int _feedBeforeCut = 4;

  Uint8List encode(Receipt receipt) {
    final out = BytesBuilder(copy: false)
      // Reset: forget the settings of whatever printed last.
      ..add(const [_esc, 0x40]);
    var align = ReceiptAlign.left;
    var bold = false;
    var large = false;

    void setAlign(ReceiptAlign value) {
      if (value != align) {
        align = value;
        out.add([_esc, 0x61, value.index]);
      }
    }

    void setBold(bool value) {
      if (value != bold) {
        bold = value;
        out.add([_esc, 0x45, value ? 1 : 0]);
      }
    }

    void setLarge(bool value) {
      if (value != large) {
        large = value;
        // Double width and height.
        out.add([_gs, 0x21, value ? 0x11 : 0x00]);
      }
    }

    void write(String line) => out
      ..add(_ascii(line))
      ..addByte(0x0A);

    for (final line in receipt.lines) {
      switch (line) {
        case ReceiptText():
          setAlign(line.align);
          setBold(line.bold);
          setLarge(line.large);
          final width = line.large ? paperWidth.characters ~/ 2 : null;
          for (final part in wrap(line.text, width ?? paperWidth.characters)) {
            write(part);
          }
        case ReceiptColumns():
          setAlign(ReceiptAlign.left);
          setBold(line.bold);
          setLarge(false);
          columns(line.label, line.value).forEach(write);
        case ReceiptRule():
          setAlign(ReceiptAlign.left);
          setBold(false);
          setLarge(false);
          write((line.double ? '=' : '-') * paperWidth.characters);
        case ReceiptFeed():
          setLarge(false);
          out.add([_esc, 0x64, line.lines.clamp(0, 255)]);
        case ReceiptCut():
          setLarge(false);
          out
            ..add([_esc, 0x64, _feedBeforeCut])
            // Partial cut. Printers without a cutter ignore it.
            ..add([_gs, 0x56, 0x01]);
      }
    }
    // Back to the defaults for the next job.
    setAlign(ReceiptAlign.left);
    setBold(false);
    setLarge(false);
    return out.takeBytes();
  }

  /// [text] broken into lines of at most [width] characters, at spaces where
  /// possible. Blank lines in [text] are kept.
  static List<String> wrap(String text, int width) {
    assert(width > 0, 'A line needs room for at least one character.');
    final lines = <String>[];
    for (final paragraph in _printable(text).split('\n')) {
      var current = '';
      for (final word in paragraph.split(' ').where((w) => w.isNotEmpty)) {
        var rest = word;
        // A word longer than a line is split where the line ends.
        while (rest.length > width) {
          if (current.isNotEmpty) {
            lines.add(current);
            current = '';
          }
          lines.add(rest.substring(0, width));
          rest = rest.substring(width);
        }
        if (current.isEmpty) {
          current = rest;
        } else if (current.length + 1 + rest.length <= width) {
          current = '$current $rest';
        } else {
          lines.add(current);
          current = rest;
        }
      }
      lines.add(current);
    }
    return lines;
  }

  /// [label] against the left edge and [value] against the right, on lines
  /// of the paper's width. A label too long to share the line with the value
  /// wraps, and the value stays on its first line.
  List<String> columns(String label, String value) {
    final width = paperWidth.characters;
    final shown = _printable(value).replaceAll('\n', ' ').trim();
    final room = width - shown.length - 1;
    if (room < 1) {
      // The value alone nearly fills the line: it gets its own line.
      return [
        ...wrap(label, width),
        shown.length > width
            ? shown.substring(shown.length - width)
            : shown.padLeft(width),
      ];
    }
    final labelLines = wrap(label, room);
    final first = labelLines.first.padRight(width - shown.length) + shown;
    return [first, ...labelLines.skip(1)];
  }

  static Uint8List _ascii(String text) => Uint8List.fromList(
    _printable(text).codeUnits.map((c) => c == 0x0A ? 0x20 : c).toList(),
  );

  /// [text] reduced to what every printer prints: ASCII, with accents
  /// replaced by their base letters, common symbols by look-alikes, and
  /// anything else by "?". Newlines are kept; other control characters go.
  static String _printable(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (rune == 0x0A || (rune >= 0x20 && rune < 0x7F)) {
        buffer.writeCharCode(rune);
        continue;
      }
      final replacement = _replacements[String.fromCharCode(rune)];
      if (replacement != null) {
        buffer.write(replacement);
      } else if (rune >= 0x20 && rune != 0x7F) {
        buffer.write('?');
      }
    }
    return buffer.toString();
  }

  static final Map<String, String> _replacements = _buildReplacements();

  static Map<String, String> _buildReplacements() {
    const letters = {
      'a': 'àáâãäåāăą',
      'c': 'çćčĉċ',
      'd': 'ďđ',
      'e': 'èéêëēĕėęě',
      'g': 'ĝğġģ',
      'i': 'ìíîïĩīĭįı',
      'l': 'ĺļľŀł',
      'n': 'ñńņňŉ',
      'o': 'òóôõöøōŏő',
      'r': 'ŕŗř',
      's': 'śŝşš',
      't': 'ţťŧ',
      'u': 'ùúûüũūŭůűų',
      'y': 'ýÿŷ',
      'z': 'źżž',
    };
    final map = <String, String>{
      'ß': 'ss',
      'æ': 'ae',
      'œ': 'oe',
      'Æ': 'AE',
      'Œ': 'OE',
      'Þ': 'Th',
      'þ': 'th',
      'Ð': 'D',
      'ð': 'd',
      '×': 'x',
      '÷': '/',
      '·': '.',
      '•': '*',
      '…': '...',
      '–': '-',
      '—': '-',
      '‘': "'",
      '’': "'",
      '‚': ',',
      '“': '"',
      '”': '"',
      '→': '->',
      '←': '<-',
      '€': 'EUR',
      '£': 'GBP',
      ' ': ' ',
      '\t': ' ',
    };
    for (final MapEntry(:key, :value) in letters.entries) {
      for (final accented in value.split('')) {
        map[accented] = key;
        map[accented.toUpperCase()] = key.toUpperCase();
      }
    }
    return map;
  }
}
