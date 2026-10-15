import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keihatsu/components/comment_mentions.dart';

void main() {
  test('picker inserts a plain mention and keeps the rest of the draft', () {
    final value = insertCommentMention(
      const TextEditingValue(
        text: 'Hello @dex, welcome',
        selection: TextSelection.collapsed(offset: 10),
      ),
      'dexgamingacct',
    );
    expect(value.text, 'Hello @dexgamingacct , welcome');
    expect(value.selection.baseOffset, 'Hello @dexgamingacct '.length);
    final legacy = insertCommentMention(
      const TextEditingValue(
        text: 'Hello @{dex}',
        selection: TextSelection.collapsed(offset: 11),
      ),
      'dexgamingacct',
    );
    expect(legacy.text, 'Hello @dexgamingacct ');
  });
  test('legacy posted mentions render without braces and stay themed', () {
    final spans = commentMentionSpans(
      'Hi @{reader}!',
      Colors.orange,
      normalizeBraces: true,
    ).cast<TextSpan>();
    expect(spans.map((s) => s.text).join(), 'Hi @reader!');
    expect(
      spans.where((s) => s.style?.color == Colors.orange).single.text,
      '@reader',
    );
  });
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
