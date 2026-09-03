import 'package:blobatar/flutter.dart' as blobatar;
import 'package:flutter/material.dart';

/// Privacy-safe avatar rendered from a user's stable Keihatsu ID.
///
/// Google profile photos are deliberately not used. A user's ID keeps the
/// default appearance deterministic while the persisted options let them
/// customize it without uploading another identifying image.
class UserBlobatar extends StatelessWidget {
  const UserBlobatar({
    super.key,
    required this.seed,
    required this.label,
    this.size,
    this.hue,
    this.shape,
    this.expression = 'happy',
    this.animated = false,
    this.background = blobatar.Backdrop.squircle,
  });

  final String seed;
  final String label;
  final double? size;
  final double? hue;
  final double? shape;
  final String expression;
  final bool animated;
  final blobatar.Backdrop background;

  static blobatar.Expression expressionFor(String? name) {
    return blobatar.expressions.firstWhere(
      (option) => option.name == name,
      orElse: () => blobatar.happy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = blobatar.BlobatarOptions(
      background: background,
      hue: hue,
      expression: expressionFor(expression),
      traits: shape == null ? null : <String, Object>{'shape': shape!},
    );
    final safeSeed = seed.trim().isEmpty ? 'keihatsu-reader' : seed;

    if (animated) {
      return blobatar.AnimatedBlobatar(
        name: safeSeed,
        size: size,
        semanticLabel: '$label avatar',
        animation: blobatar.BlobatarAnimation.always,
        options: options,
      );
    }

    return blobatar.Blobatar(
      name: safeSeed,
      size: size,
      semanticLabel: '$label avatar',
      options: options,
    );
  }
}
