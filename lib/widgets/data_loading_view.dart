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
            size: const Size(220, 180),
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
    final body = Paint()..color = const Color(0xFFFFAE00);
    final white = Paint()..color = Colors.white;
    canvas.scale(size.width / 220, size.height / 180);
    // A perspective flip: the complete wallet turns around its vertical axis,
    // rather than moving like a hinged door.
    final flip = (progress * 2 - 1) * .32;
    canvas.save();
    canvas.translate(110, 90);
    canvas.transform(
      (Matrix4.identity()
            ..setEntry(3, 2, .0015)
            ..rotateY(flip))
          .storage,
    );
    canvas.translate(-110, -90);
    // Main wallet body, clasp, and cut-out match the reference silhouette.
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(18, 44, 178, 118),
      const Radius.circular(28),
    );
    canvas.drawRRect(rect, body);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(162, 81, 58, 48),
        const Radius.circular(16),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(172, 86, 48, 38),
        const Radius.circular(13),
      ),
      white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(177, 91, 43, 28),
        const Radius.circular(11),
      ),
      body,
    );
    final dollar = TextPainter(
      text: const TextSpan(
        text: r'$',
        style: TextStyle(
          color: Colors.white,
          fontSize: 78,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    dollar.paint(canvas, const Offset(78, 52));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WalletPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
