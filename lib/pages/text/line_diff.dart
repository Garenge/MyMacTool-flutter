class LineDiffCalculator {
  const LineDiffCalculator();

  List<DiffLine> buildLineDiff(String leftText, String rightText) {
    final leftLines = leftText.split('\n');
    final rightLines = rightText.split('\n');
    final table = List<List<int>>.generate(
      leftLines.length + 1,
      (_) => List<int>.filled(rightLines.length + 1, 0),
    );

    for (var leftIndex = leftLines.length - 1; leftIndex >= 0; leftIndex -= 1) {
      for (
        var rightIndex = rightLines.length - 1;
        rightIndex >= 0;
        rightIndex -= 1
      ) {
        if (leftLines[leftIndex] == rightLines[rightIndex]) {
          table[leftIndex][rightIndex] =
              table[leftIndex + 1][rightIndex + 1] + 1;
          continue;
        }

        table[leftIndex][rightIndex] =
            table[leftIndex + 1][rightIndex] >= table[leftIndex][rightIndex + 1]
            ? table[leftIndex + 1][rightIndex]
            : table[leftIndex][rightIndex + 1];
      }
    }

    return _backtrackDiff(leftLines, rightLines, table);
  }

  String formatDiffText(List<DiffLine> diffLines) {
    return diffLines
        .map((DiffLine line) => '${line.type.prefix} ${line.text}')
        .join('\n');
  }

  List<DiffLine> _backtrackDiff(
    List<String> leftLines,
    List<String> rightLines,
    List<List<int>> table,
  ) {
    final diffLines = <DiffLine>[];
    var leftIndex = 0;
    var rightIndex = 0;

    while (leftIndex < leftLines.length && rightIndex < rightLines.length) {
      if (leftLines[leftIndex] == rightLines[rightIndex]) {
        diffLines.add(
          DiffLine(
            type: DiffLineType.equal,
            leftLineNumber: leftIndex + 1,
            rightLineNumber: rightIndex + 1,
            text: leftLines[leftIndex],
          ),
        );
        leftIndex += 1;
        rightIndex += 1;
        continue;
      }

      if (table[leftIndex + 1][rightIndex] >=
          table[leftIndex][rightIndex + 1]) {
        diffLines.add(
          DiffLine(
            type: DiffLineType.removed,
            leftLineNumber: leftIndex + 1,
            rightLineNumber: null,
            text: leftLines[leftIndex],
          ),
        );
        leftIndex += 1;
        continue;
      }

      diffLines.add(
        DiffLine(
          type: DiffLineType.added,
          leftLineNumber: null,
          rightLineNumber: rightIndex + 1,
          text: rightLines[rightIndex],
        ),
      );
      rightIndex += 1;
    }

    while (leftIndex < leftLines.length) {
      diffLines.add(
        DiffLine(
          type: DiffLineType.removed,
          leftLineNumber: leftIndex + 1,
          rightLineNumber: null,
          text: leftLines[leftIndex],
        ),
      );
      leftIndex += 1;
    }

    while (rightIndex < rightLines.length) {
      diffLines.add(
        DiffLine(
          type: DiffLineType.added,
          leftLineNumber: null,
          rightLineNumber: rightIndex + 1,
          text: rightLines[rightIndex],
        ),
      );
      rightIndex += 1;
    }

    return diffLines;
  }
}

class DiffLine {
  const DiffLine({
    required this.type,
    required this.leftLineNumber,
    required this.rightLineNumber,
    required this.text,
  });

  final DiffLineType type;
  final int? leftLineNumber;
  final int? rightLineNumber;
  final String text;

  String get lineLabel {
    final left = leftLineNumber?.toString() ?? '-';
    final right = rightLineNumber?.toString() ?? '-';
    return '$left / $right';
  }
}

enum DiffLineType {
  equal(' '),
  added('+'),
  removed('-');

  const DiffLineType(this.prefix);

  final String prefix;
}
