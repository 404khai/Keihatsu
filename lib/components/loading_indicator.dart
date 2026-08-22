import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_shapes/material_shapes.dart';
import 'package:provider/provider.dart';

import '../theme_provider.dart';

/// Default polygon sequence from M3 [LoadingIndicatorDefaults.IndeterminateIndicatorPolygons].
final List<RoundedPolygon> kIndeterminateIndicatorPolygons = [
  MaterialShapes.softBurst,
  MaterialShapes.cookie9Sided,
  MaterialShapes.pentagon,
  MaterialShapes.pill,
  MaterialShapes.sunny,
  MaterialShapes.cookie4Sided,
  MaterialShapes.oval,
];

const double _kContainerSize = 48;
const double _kActiveIndicatorScale = 30 / _kContainerSize;
const int _kMorphIntervalMs = 650;
const int _kGlobalRotationMs = 4666;
const double _kQuarterRotation = 90;

/// Material 3 expressive loading indicator that morphs between polygon shapes.
///
/// Ported from Compose Material 3 [LoadingIndicator].
class KeihatsuLoadingIndicator extends StatefulWidget {
  KeihatsuLoadingIndicator({
    super.key,
    this.color,
    this.size = _kContainerSize,
    List<RoundedPolygon>? polygons,
    this.contained = false,
    this.containerColor,
  }) : polygons = polygons ?? kIndeterminateIndicatorPolygons;

  final Color? color;
  final double size;
  final List<RoundedPolygon> polygons;
  final bool contained;
  final Color? containerColor;

  @override
  State<KeihatsuLoadingIndicator> createState() =>
      _KeihatsuLoadingIndicatorState();
}

class _KeihatsuLoadingIndicatorState extends State<KeihatsuLoadingIndicator>
    with TickerProviderStateMixin {
  late List<Morph> _morphSequence;
  late final double _scaleFactor;
  late final AnimationController _morphController;
  late final AnimationController _rotationController;
  int _morphIndex = 0;
  double _morphRotationTarget = _kQuarterRotation;

  @override
  void initState() {
    super.initState();
    _morphSequence = _buildMorphSequence(widget.polygons, circular: true);
    _scaleFactor = _calculateScaleFactor(widget.polygons) * _kActiveIndicatorScale;

    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addStatusListener(_onMorphStatus);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _kGlobalRotationMs),
    )..repeat();

    _startMorphLoop();
  }

  void _onMorphStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    setState(() {
      _morphIndex = (_morphIndex + 1) % _morphSequence.length;
      _morphRotationTarget =
          (_morphRotationTarget + _kQuarterRotation) % 360;
    });
    _morphController.value = 0;
    _scheduleNextMorph();
  }

  Future<void> _startMorphLoop() async {
    await Future<void>.delayed(const Duration(milliseconds: _kMorphIntervalMs));
    if (!mounted) return;
    _morphController.forward(from: 0);
  }

  Future<void> _scheduleNextMorph() async {
    await Future<void>.delayed(const Duration(milliseconds: _kMorphIntervalMs));
    if (!mounted || _morphController.isAnimating) return;
    _morphController.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant KeihatsuLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.polygons != widget.polygons) {
      _morphSequence = _buildMorphSequence(widget.polygons, circular: true);
      _morphIndex = 0;
      _morphRotationTarget = _kQuarterRotation;
    }
  }

  @override
  void dispose() {
    _morphController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color indicatorColor =
        widget.color ?? themeProvider.brandColor;
    final Color containerColor =
        widget.containerColor ?? cs.surfaceContainerHigh;

    final Widget indicator = AnimatedBuilder(
      animation: Listenable.merge([_morphController, _rotationController]),
      builder: (context, child) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _LoadingIndicatorPainter(
            morph: _morphSequence[_morphIndex],
            morphProgress: Curves.easeOut.transform(_morphController.value),
            rotationDegrees: _morphController.value * _kQuarterRotation +
                _morphRotationTarget +
                _rotationController.value * 360,
            color: indicatorColor,
            scaleFactor: _scaleFactor,
          ),
        );
      },
    );

    if (!widget.contained) return indicator;

    return ClipPath(
      clipper: ShapeBorderClipper(shape: MaterialShapeBorder(shape: MaterialShapes.circle)),
      child: Container(
        width: widget.size,
        height: widget.size,
        color: containerColor,
        alignment: Alignment.center,
        child: indicator,
      ),
    );
  }
}

class _LoadingIndicatorPainter extends CustomPainter {
  const _LoadingIndicatorPainter({
    required this.morph,
    required this.morphProgress,
    required this.rotationDegrees,
    required this.color,
    required this.scaleFactor,
  });

  final Morph morph;
  final double morphProgress;
  final double rotationDegrees;
  final Color color;
  final double scaleFactor;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = morph.toPath(progress: morphProgress);
    final Rect bounds = path.getBounds();

    final double scale = size.shortestSide * scaleFactor /
        math.max(bounds.width, bounds.height);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotationDegrees * math.pi / 180);
    canvas.scale(scale);
    canvas.translate(-bounds.center.dx, -bounds.center.dy);
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LoadingIndicatorPainter oldDelegate) {
    return oldDelegate.morphProgress != morphProgress ||
        oldDelegate.rotationDegrees != rotationDegrees ||
        oldDelegate.color != color ||
        oldDelegate.morph != morph;
  }
}

List<Morph> _buildMorphSequence(
  List<RoundedPolygon> polygons, {
  required bool circular,
}) {
  assert(polygons.length > 1);
  final List<Morph> sequence = [];
  for (var i = 0; i < polygons.length; i++) {
    if (i + 1 < polygons.length) {
      sequence.add(Morph(polygons[i].normalized(), polygons[i + 1].normalized()));
    } else if (circular) {
      sequence.add(Morph(polygons[i].normalized(), polygons[0].normalized()));
    }
  }
  return sequence;
}

double _calculateScaleFactor(List<RoundedPolygon> polygons) {
  var scaleFactor = 1.0;
  final bounds = List<double>.filled(4, 0);
  final maxBounds = List<double>.filled(4, 0);

  for (final polygon in polygons) {
    polygon.calculateBounds(bounds: bounds);
    polygon.calculateMaxBounds(maxBounds);
    final scaleX = (bounds[2] - bounds[0]) / (maxBounds[2] - maxBounds[0]);
    final scaleY = (bounds[3] - bounds[1]) / (maxBounds[3] - maxBounds[1]);
    scaleFactor = math.min(scaleFactor, math.max(scaleX, scaleY));
  }
  return scaleFactor;
}
