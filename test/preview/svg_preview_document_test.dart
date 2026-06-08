import 'package:flutter_test/flutter_test.dart';
import 'package:mytools/pages/preview/svg_preview_document.dart';

void main() {
  test(
    'svg preview formatter builds copy summary with byte count and path',
    () {
      const formatter = SvgPreviewDocumentFormatter();
      final summary = formatter.buildSummary(
        svg: '<svg>\n<text>你好</text>\n</svg>',
        sourceLabel: '文件导入',
        sourcePath: '/tmp/icon.svg',
      );

      expect(summary, contains('SVG 摘要'));
      expect(summary, contains('来源：文件导入'));
      expect(summary, contains('字符数：28'));
      expect(summary, contains('字节数：32'));
      expect(summary, contains('行数：3'));
      expect(summary, contains('路径：/tmp/icon.svg'));
    },
  );

  test('svg preview formatter builds history time and suggested file name', () {
    const formatter = SvgPreviewDocumentFormatter();
    final timestamp = DateTime(2026, 6, 7, 9, 8, 5);

    expect(formatter.formatHistoryTime(timestamp), '09:08:05');
    expect(
      formatter.buildSuggestedFileName(timestamp, '.svg'),
      'svg_preview_20260607090805.svg',
    );
  });

  test('svg preview formatter builds browser preview html', () {
    const formatter = SvgPreviewDocumentFormatter();
    final html = formatter.buildBrowserPreviewHtml(
      '<svg id="icon"></svg><script>alert(1)</script>',
    );

    expect(html, contains('<html lang="zh-CN">'));
    expect(html, contains('<title>SVG Preview</title>'));
    expect(html, contains('sandbox=""'));
    expect(html, contains('&lt;svg id=&quot;icon&quot;&gt;&lt;&#47;svg&gt;'));
    expect(html, contains('&lt;script&gt;alert(1)&lt;&#47;script&gt;'));
    expect(html, isNot(contains('<script>alert(1)</script>')));
  });
}
