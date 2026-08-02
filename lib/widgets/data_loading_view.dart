import 'package:flutter/material.dart';

class DataLoadingView extends StatefulWidget {
  const DataLoadingView({super.key});
  @override
  State<DataLoadingView> createState() => _DataLoadingViewState();
}

class _DataLoadingViewState extends State<DataLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (_, _) => CustomPaint(
            size: const Size(112, 82),
            painter: _WalletPainter(_controller.value),
          ),
        ),
        const SizedBox(height: 16),
        const Text(''),
      ],
    ),
  );
}

class _WalletPainter extends CustomPainter {
  const _WalletPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()..color = const Color(0xFFF59E0B);
    final dark = Paint()..color = const Color(0xFFB45309);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 25, 96, 49),
      const Radius.circular(13),
    );
    canvas.drawRRect(rect, body);
    canvas.save();
    canvas.translate(16, 28);
    canvas.rotate(-.55 * progress);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, -13, 78, 25),
        const Radius.circular(10),
      ),
      dark,
    );
    canvas.restore();
    canvas.drawCircle(const Offset(82, 49), 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _WalletPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
