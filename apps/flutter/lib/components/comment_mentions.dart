import 'package:flutter/material.dart';

final commentMentionPattern = RegExp(
  r'@(?:\{([A-Za-z0-9_]{1,32})\}|([A-Za-z0-9_]{1,32}))',
);

TextEditingValue insertCommentMention(TextEditingValue value, String username) {
  final caret = value.selection.isValid
      ? value.selection.extentOffset
      : value.text.length;
  final match = RegExp(
    r'@\{?[A-Za-z0-9_]*$',
  ).firstMatch(value.text.substring(0, caret));
  if (match == null) return value;
  final end = caret < value.text.length && value.text[caret] == '}'
      ? caret + 1
      : caret;
  final mention = '@$username ';
  return TextEditingValue(
    text: value.text.replaceRange(match.start, end, mention),
    selection: TextSelection.collapsed(offset: match.start + mention.length),
  );
}

List<InlineSpan> commentMentionSpans(
  String text,
  Color color, {
  bool normalizeBraces = false,
}) {
  final spans = <InlineSpan>[];
  var offset = 0;
  for (final match in commentMentionPattern.allMatches(text)) {
    spans.add(TextSpan(text: text.substring(offset, match.start)));
    spans.add(
      TextSpan(
        text: normalizeBraces
            ? '@${match.group(1) ?? match.group(2)}'
            : match.group(0),
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
