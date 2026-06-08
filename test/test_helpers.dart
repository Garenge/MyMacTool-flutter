import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> selectTool(WidgetTester tester, String title) async {
  final toolFinder = find.text(title);

  if (toolFinder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      toolFinder,
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  await tester.tap(toolFinder);
  await tester.pumpAndSettle();
}

Future<void> expectVisibleText(
  WidgetTester tester,
  String text, {
  Finder? scrollable,
}) async {
  final textFinder = find.text(text, findRichText: true);

  if (textFinder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      textFinder,
      120,
      scrollable: scrollable ?? find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }

  expect(textFinder, findsOneWidget);
}

void installClipboardTextMock(String text) {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (methodCall) async {
          if (methodCall.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': text};
          }

          if (methodCall.method == 'Clipboard.setData') {
            return null;
          }

          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
}
