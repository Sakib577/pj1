import 'package:flutter/material.dart';

/// A floating action button that morphs between a compact circular "+" button
/// and an extended pill with a label. The width, shape and label animate
/// smoothly, so navigating from one page to another makes each page's button
/// appear to morph into the next.
///
/// All instances share the same [heroTag] so route transitions also fly the
/// button between pages.
class MorphingFab extends StatefulWidget {
  const MorphingFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.label,
    this.backgroundColor = const Color(0xFFF59E0B),
    this.foregroundColor = Colors.white,
    this.heroTag = 'app-add-fab',
    this.duration = const Duration(milliseconds: 320),
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String? label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Object heroTag;
  final Duration duration;

  @override
  State<MorphingFab> createState() => _MorphingFabState();
}

class _MorphingFabState extends State<MorphingFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _widthFactor;
  late String? _displayLabel;

  bool get _extended => widget.label != null;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _widthFactor = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _displayLabel = widget.label;
    if (_extended) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant MorphingFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.label == oldWidget.label) return;
    if (widget.label != null) _displayLabel = widget.label;
    if (widget.label == null) {
      _controller.reverse();
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Width of the fully-extended pill, measured from the current label so the
  // morph always ends exactly around its text.
  double _extendedWidth() {
    final style = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: widget.foregroundColor,
    );
    final painter = TextPainter(
      text: TextSpan(text: _displayLabel, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return 40 + 24 + 8 + painter.width + 2;
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: widget.heroTag,
      child: Material(
        color: widget.backgroundColor,
        elevation: 6,
        shadowColor: widget.backgroundColor.withValues(alpha: 0.4),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: InkWell(
          onTap: widget.onPressed,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _widthFactor.value;
              final width = 56 + (_extendedWidth() - 56) * t;
              return SizedBox(
                width: width,
                height: 56,
                // FittedBox keeps the pill from overflowing during a Hero
                // flight, when the button is transiently squeezed into a size
                // smaller than its content.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.icon,
                        size: 24,
                        color: widget.foregroundColor,
                      ),
                      ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: t,
                          child: Opacity(
                            opacity: t,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 8,
                                right: 20,
                              ),
                              child: Text(
                                _displayLabel ?? '',
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.fade,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: widget.foregroundColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
