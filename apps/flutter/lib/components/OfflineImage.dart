import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class OfflineImage extends StatelessWidget {
  final String? imageUrl;
  final String? localFilePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;
  final Widget? placeholder;
  final String? cacheKey;

  const OfflineImage({
    super.key,
    this.imageUrl,
    this.localFilePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallback,
    this.placeholder,
    this.cacheKey,
  });

  bool get _hasLocalFile {
    final path = localFilePath;
    return path != null && path.isNotEmpty && File(path).existsSync();
  }

  bool get _hasImageUrl {
    final url = imageUrl?.trim();
    return url != null && url.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_hasLocalFile) {
      child = Image.file(
        File(localFilePath!),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildFallback(context),
      );
    } else if (_hasImageUrl) {
      final resolvedUrl = imageUrl!.trim();
      if (resolvedUrl.startsWith('http')) {
        child = CachedNetworkImage(
          imageUrl: resolvedUrl,
          cacheKey: cacheKey ?? resolvedUrl,
          width: width,
          height: height,
          fit: fit,
          placeholder: (_, __) => _buildPlaceholder(context),
          errorWidget: (_, __, ___) => _buildFallback(context),
        );
      } else {
        child = Image.asset(
          resolvedUrl,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildFallback(context),
        );
      }
    } else {
      child = _buildFallback(context);
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }

    return child;
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholder != null) {
      return placeholder!;
    }

    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    if (fallback != null) {
      return fallback!;
    }

    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade600),
    );
  }
}
