import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keihatsu/components/comment_mentions.dart';

void main() {
  test(
    'plain and braced mentions use the theme colour without losing surrounding text',
    () {
      final spans = commentMentionSpans(
        'Hi @{dexgamingacct} and @reader!',
        Colors.orange,
      ).cast<TextSpan>();
      expect(
        spans.map((s) => s.text).join(),
        'Hi @{dexgamingacct} and @reader!',
      );
      expect(
        spans.where((s) => s.style?.color == Colors.orange).map((s) => s.text),
        ['@{dexgamingacct}', '@reader'],
      );
    },
  );
}
