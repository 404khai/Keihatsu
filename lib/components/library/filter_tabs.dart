import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_shapes/material_shapes.dart';
import 'package:motor/motor.dart';

class FilterTab {
  const FilterTab({
    required this.value,
    required this.label,
    required this.accent,
    required this.onAccent,
    this.image,
    this.shape,
    this.icon,
  });

  final String? value;
  final String label;
  final Color accent;
  final Color onAccent;
  final String? image;
  final RoundedPolygon? shape;
  final IconData? icon;
}

class FilterTabs extends StatefulWidget {
  const FilterTabs({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
    this.height = 44,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<FilterTab> tabs;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  State<FilterTabs> createState() => _FilterTabsState();
}

class _FilterTabsState extends State<FilterTabs>
    with SingleTickerProviderStateMixin {
  static const _nullId = '\u0000__all__';
  final _keys = <String, GlobalKey>{};
  final _scroll = ScrollController();

  late final SingleMotionController _scrollMotion = SingleMotionController(
    motion: MaterialSpringMotion.standardSpatialFast(),
    vsync: this,
  )..addListener(() {
      if (!_scroll.hasClients) return;
      final p = _scroll.position;
      _scroll.jumpTo(
        _scrollMotion.value.clamp(p.minScrollExtent, p.maxScrollExtent),
      );
    });

  String _idOf(String? value) => value ?? _nullId;
  GlobalKey _keyFor(String? value) =>
      _keys.putIfAbsent(_idOf(value), () => GlobalKey());

  @override
  void initState() {
    super.initState();
    if (widget.selected != null) _scrollToSelected();
  }

  @override
  void didUpdateWidget(FilterTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) _scrollToSelected();
  }

  @override
  void dispose() {
    _scrollMotion.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final keyContext = _keys[_idOf(widget.selected)]?.currentContext;
      final box = keyContext?.findRenderObject();
      if (box is! RenderBox) return;

      final p = _scroll.position;
      final viewport = RenderAbstractViewport.of(box);
      final current = _scroll.offset;

      final near = viewport.getOffsetToReveal(box, 0.25).offset;
      final far = viewport.getOffsetToReveal(box, 0.75).offset;
      final lo = far < near ? far : near;
      final hi = far < near ? near : far;
      if (current >= lo - 0.5 && current <= hi + 0.5) return;

      final target = (current < lo ? lo : hi).clamp(
        p.minScrollExtent,
        p.maxScrollExtent,
      );
      _scrollMotion.animateTo(target, from: current);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: widget.padding,
        itemCount: widget.tabs.length,
        itemBuilder: (context, i) {
          final tab = widget.tabs[i];
          return _FilterChip(
            key: _keyFor(tab.value),
            tab: tab,
            selected: tab.value == widget.selected,
            onTap: () => widget.onSelected(tab.value),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final FilterTab tab;
  final bool selected;
  final VoidCallback onTap;

  static const double _idleRadius = 12;
  static const double _pillRadius = 22;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SingleMotionBuilder(
        motion: MaterialSpringMotion.standardSpatialFast(),
        value: selected ? 1.0 : 0.0,
        builder: (context, t, _) {
          final tc = t.clamp(0.0, 1.0);
          final bg = Color.lerp(cs.surfaceContainerHigh, tab.accent, tc)!;
          final fg = Color.lerp(cs.onSurfaceVariant, tab.onAccent, tc)!;
          final radius = _idleRadius + (_pillRadius - _idleRadius) * t;

          return Material(
            color: bg,
            animationDuration: Duration.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(radius < 0 ? 0 : radius),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  tab.image != null ? 6 : 14,
                  6,
                  16,
                  6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tab.image != null) ...[
                      ClipPath(
                        clipper: ShapeBorderClipper(
                          shape: MaterialShapeBorder(
                            shape: selected
                                ? (tab.shape ?? MaterialShapes.circle)
                                : MaterialShapes.circle,
                          ),
                        ),
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: Image.asset(
                            tab.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) =>
                                ColoredBox(color: cs.surfaceContainerHighest),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ] else if (tab.icon != null) ...[
                      Icon(tab.icon, size: 18, color: fg),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      tab.label,
                      style: tt.labelLarge?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
