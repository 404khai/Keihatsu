import 'package:flutter/material.dart';
import 'package:material_shapes/material_shapes.dart';
import 'package:motor/motor.dart';

/// Touch-reactive button whose shape morphs on press — BunPod player style.
class ShapedActionButton extends StatefulWidget {
  const ShapedActionButton({
    super.key,
    required this.onTap,
    required this.child,
    required this.rest,
    required this.pressed,
    this.color,
    this.borderColor,
    this.outlined = false,
    this.height = 44,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final VoidCallback onTap;
  final Widget child;
  final RoundedPolygon rest;
  final RoundedPolygon pressed;
  final Color? color;
  final Color? borderColor;
  final bool outlined;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  State<ShapedActionButton> createState() => _ShapedActionButtonState();
}

class _ShapedActionButtonState extends State<ShapedActionButton> {
  bool _down = false;

  void _setDown(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  ShapeBorder _shapeAt(double t) {
    final MaterialShapeBorder rest = MaterialShapeBorder(shape: widget.rest);
    if (t <= 0) return rest;
    final MaterialShapeBorder pressed =
        MaterialShapeBorder(shape: widget.pressed);
    if (t >= 1) return pressed;
    return rest.lerpTo(pressed, t)!;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final Color fill = widget.color ?? Colors.transparent;
    final Color border = widget.borderColor ?? cs.outlineVariant;

    return AnimatedScale(
      scale: _down && !reduce ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: SingleMotionBuilder(
        motion: const MaterialSpringMotion.expressiveSpatialFast(),
        value: _down && !reduce ? 1.0 : 0.0,
        builder: (context, t, child) {
          return Transform.scale(
            scale: 1 - 0.04 * t,
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: _shapeAt(t)),
              child: child,
            ),
          );
        },
        child: Material(
          color: widget.outlined ? Colors.transparent : fill,
          shape: widget.outlined
              ? MaterialShapeBorder(
                  shape: widget.rest,
                  side: BorderSide(color: border),
                )
              : MaterialShapeBorder(shape: widget.rest),
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => _setDown(true),
            onTapUp: (_) => _setDown(false),
            onTapCancel: () => _setDown(false),
            splashColor: cs.primary.withValues(alpha: 0.12),
            child: SizedBox(
              height: widget.height,
              child: Padding(
                padding: widget.padding,
                child: Center(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
