import 'package:flutter_test/flutter_test.dart';
import 'package:mytools/pages/text/line_diff.dart';

void main() {
  const calculator = LineDiffCalculator();

  test('builds equal line diff', () {
    final diffLines = calculator.buildLineDiff('a\nb', 'a\nb');

    expect(diffLines.map((DiffLine line) => line.type), <DiffLineType>[
      DiffLineType.equal,
      DiffLineType.equal,
    ]);
    expect(diffLines.map((DiffLine line) => line.lineLabel), <String>[
      '1 / 1',
      '2 / 2',
    ]);
  });

  test('builds added and removed line diff', () {
    final diffLines = calculator.buildLineDiff('a\nb\nc', 'a\nx\nc');

    expect(diffLines.map((DiffLine line) => line.type), <DiffLineType>[
      DiffLineType.equal,
      DiffLineType.removed,
      DiffLineType.added,
      DiffLineType.equal,
    ]);
    expect(calculator.formatDiffText(diffLines), '  a\n- b\n+ x\n  c');
  });

  test('keeps trailing empty line changes visible', () {
    final diffLines = calculator.buildLineDiff('a\n', 'a');

    expect(diffLines.map((DiffLine line) => line.type), <DiffLineType>[
      DiffLineType.equal,
      DiffLineType.removed,
    ]);
    expect(diffLines.last.text, isEmpty);
  });
}
