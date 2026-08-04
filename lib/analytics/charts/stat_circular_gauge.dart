import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'chart_theme.dart';

/// A simple arc (circular) gauge used for ratio cards (DTI, budget, health).
///
/// [ratio] must be in 0..1 (clamped). The arc fills proportionally and the
/// color shifts through a low/mid/high set.
class StatCircularGauge extends StatelessWidget {
  const StatCircularGauge({
    super.key,
    required this.ratio,
    this.size = 120,
    this.strokeWidth = 12,
    this.centerLabel,
    this.centerSubtitle,
    this.lowColor = const Color(0xFF22C55E),
    this.midColor = const Color(0xFFF59E0B),
    this.highColor = const Color(0xFFEF4444),
  });

  /// 0..1 completion ratio.
  final double ratio;
  final double size;
  final double strokeWidth;
  final String? centerLabel;
  final String? centerSubtitle;
  final Color lowColor;
  final Color midColor;
  final Color highColor;

  double get _clamped => ratio.clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final palette = ChartPalette.of(context);
    final sweep = _clamped * 2 * math.pi;

    Widget arc(Color color, double from, double to) {
      return AnimatedBuilder(
        animation: const AlwaysStoppedAnimation(1),
        builder: (context, child) => CustomPaint(
          size: Size.square(size),
          painter: _ArcPainter(
            from: from,
            to: to,
            color: color,
            strokeWidth: strokeWidth,
            trackColor: palette.grid.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    final color = _clamped < 0.5
        ? Color.lerp(lowColor, midColor, _clamped * 2)!
        : Color.lerp(midColor, highColor, (_clamped - 0.5) * 2)!;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          arc(color, 0, sweep),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (centerLabel != null)
                Text(
                  centerLabel!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              if (centerSubtitle != null)
                Text(
                  centerSubtitle!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: palette.axisLabel,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.from,
    required this.to,
    required this.color,
    required this.strokeWidth,
    required this.trackColor,
  });

  final double from;
  final double to;
  final Color color;
  final double strokeWidth;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.width - strokeWidth) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    // Background track.
    paint.color = trackColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * math.pi,
      false,
      paint,
    );

    // Progress arc from -90deg.
    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      to,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.from != from ||
      old.to != to ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}