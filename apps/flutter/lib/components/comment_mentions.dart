import 'package:flutter/material.dart';

final commentMentionPattern = RegExp(
  r'@(?:\{([A-Za-z0-9_]{1,32})\}|([A-Za-z0-9_]{1,32}))',
);

List<InlineSpan> commentMentionSpans(String text, Color color) {
  final spans = <InlineSpan>[];
  var offset = 0;
  for (final match in commentMentionPattern.allMatches(text)) {
    spans.add(TextSpan(text: text.substring(offset, match.start)));
    spans.add(
      TextSpan(
        text: match.group(0),
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
    offset = match.end;
  }
  spans.add(TextSpan(text: text.substring(offset)));
  return spans;
}

class MentionEditingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Keep IME composing text underlined while styling completed mention tokens.
    if (withComposing &&
        value.isComposingRangeValid &&
        !value.composing.isCollapsed) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: true,
      );
    }
    return TextSpan(
      style: style,
      children: commentMentionSpans(
        text,
        Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
