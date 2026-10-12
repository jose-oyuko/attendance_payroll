/// A document for a thermal printer, independent of the printer, its
/// language (ESC/POS) and its paper width. The encoder wraps and aligns it
/// for the paper in use.
final class Receipt {
  const Receipt(this.lines);

  final List<ReceiptLine> lines;
}

sealed class ReceiptLine {
  const ReceiptLine();
}

enum ReceiptAlign { left, center, right }

/// Text on its own line(s); long text wraps.
final class ReceiptText extends ReceiptLine {
  const ReceiptText(
    this.text, {
    this.align = ReceiptAlign.left,
    this.bold = false,
    this.large = false,
  });

  final String text;
  final ReceiptAlign align;
  final bool bold;

  /// Double height and width: halves the characters per line.
  final bool large;
}

/// A label with a value against the right edge, e.g. "Gross pay   88,250.00".
/// The label wraps when the two do not fit together.
final class ReceiptColumns extends ReceiptLine {
  const ReceiptColumns(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;
}

/// A line across the paper.
final class ReceiptRule extends ReceiptLine {
  const ReceiptRule({this.double = false});

  /// `=` instead of `-`.
  final bool double;
}

/// Blank lines.
final class ReceiptFeed extends ReceiptLine {
  const ReceiptFeed([this.lines = 1]);

  final int lines;
}

/// Feeds the paper past the cutter and cuts it, so the next receipt starts
/// on a fresh piece.
final class ReceiptCut extends ReceiptLine {
  const ReceiptCut();
}
