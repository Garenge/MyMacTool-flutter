import 'dart:convert';

import '../../utils/time_utils.dart';

class SvgPreviewDocumentFormatter {
  const SvgPreviewDocumentFormatter();

  String formatHistoryTime(DateTime value) {
    return formatTimeOfDay(value);
  }

  String buildSummary({
    required String svg,
    required String sourceLabel,
    String? sourcePath,
  }) {
    final lines = svg.split('\n').length;
    final chars = svg.length;
    final bytes = utf8.encode(svg).length;

    return <String>[
      'SVG 摘要',
      '来源：$sourceLabel',
      '字符数：$chars',
      '字节数：$bytes',
      '行数：$lines',
      if (sourcePath != null && sourcePath.trim().isNotEmpty) '路径：$sourcePath',
    ].join('\n');
  }

  String buildSuggestedFileName(DateTime value, String extension) {
    return 'svg_preview_${formatCompactTimestamp(value)}$extension';
  }

  String buildBrowserPreviewHtml(String svg) {
    final escapedSvg = htmlEscape.convert(svg);

    return '''
<!DOCTYPE html>
<html lang="zh-CN">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>SVG Preview</title>
    <style>
      body {
        margin: 0;
        min-height: 100vh;
        display: grid;
        place-items: center;
        background: #f3f6f8;
      }
      .preview {
        width: min(88vw, 960px);
        height: min(88vh, 960px);
        padding: 24px;
        box-sizing: border-box;
        border: 1px solid #d8e2e8;
        border-radius: 24px;
        background: #ffffff;
        box-shadow: 0 8px 24px rgba(15, 23, 42, 0.08);
      }
      .preview svg {
        width: 100%;
        height: 100%;
      }
      .preview-frame {
        width: 100%;
        height: 100%;
        border: 0;
        background: transparent;
      }
    </style>
  </head>
  <body>
    <div class="preview">
      <iframe class="preview-frame" sandbox="" title="SVG Preview" srcdoc="$escapedSvg"></iframe>
    </div>
  </body>
</html>
''';
  }
}
