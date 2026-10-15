import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keihatsu/components/comment_composer.dart';

void main() {
  testWidgets(
    'image then circular black send are visible before focus and remain while typing',
    (tester) async {
      final controller = TextEditingController();
      final focus = FocusNode();
      var images = 0;
      var sends = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ListenableBuilder(
                listenable: focus,
                builder: (context, child) {
                  return CommentComposer(
                    controller: controller,
                    focusNode: focus,
                    avatar: const SizedBox(width: 32, height: 32),
                    brandColor: Colors.orange,
                    expanded: focus.hasFocus,
                    onImage: () => images++,
                    onSend: () => sends++,
                  );
                },
              ),
            ),
          ),
        ),
      );
      final image = find.byKey(const ValueKey('comment-image'));
      final send = find.byKey(const ValueKey('comment-send'));
      expect(image, findsOneWidget);
      expect(send, findsOneWidget);
      expect(tester.getCenter(image).dx, lessThan(tester.getCenter(send).dx));
      final icon = tester.widget<Icon>(
        find.descendant(of: send, matching: find.byType(Icon)),
      );
      expect(icon.color, Colors.black);
      final circle = tester.widget<DecoratedBox>(
        find.ancestor(of: send, matching: find.byType(DecoratedBox)).first,
      );
      expect((circle.decoration as BoxDecoration).shape, BoxShape.circle);
      expect((circle.decoration as BoxDecoration).color, Colors.orange);
      final field = find.byType(TextField);
      final before = tester.getSize(field).height;
      final bottom = tester.getBottomRight(send).dy;
      await tester.tap(image);
      await tester.tap(send);
      expect(images, 1);
      expect(sends, 1);
      await tester.tap(field);
      await tester.pump();
      await tester.enterText(field, 'Hello @reader');
      await tester.pump();
      expect(tester.getSize(field).height, greaterThan(before));
      expect(tester.getBottomRight(send).dy, bottom);
      expect(tester.widget<TextField>(field).maxLines, 4);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      focus.dispose();
    },
  );

  testWidgets('sending locks the draft and prevents duplicate taps', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Draft');
    final focus = FocusNode();
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommentComposer(
            controller: controller,
            focusNode: focus,
            avatar: const SizedBox(width: 32, height: 32),
            brandColor: Colors.orange,
            expanded: false,
            sending: true,
            onImage: () => taps++,
            onSend: () => taps++,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('comment-image')));
    await tester.tap(find.byKey(const ValueKey('comment-send')));
    expect(taps, 0);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, true);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    focus.dispose();
  });
}
