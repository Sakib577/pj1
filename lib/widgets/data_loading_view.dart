import 'dart:async';

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

  Timer? _slowTimer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    // If loading is still in progress after this window, surface a message
    // instead of a silent blank screen so a stuck state is never invisible.
    _slowTimer = Timer(const Duration(seconds: 12), () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (_, _) => _ThemeLoader(progress: _controller.value),
          ),
          if (_slow) ...[
            const SizedBox(height: 20),
            const Text(
              'Still syncing your data…',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Check your connection.\nYour data will appear as soon as it loads.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThemeLoader extends StatelessWidget {
  const _ThemeLoader({required this.progress});
  final double progress;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 76,
    height: 76,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: progress * 6.283,
          child: const SizedBox(
            width: 68,
            height: 68,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              color: Color(0xFFF59E0B),
              backgroundColor: Color(0xFFFFF0CE),
            ),
          ),
        ),
      ],
    ),
  );
}
