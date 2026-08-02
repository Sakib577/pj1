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
          builder: (_, _) => _ThemeLoader(progress: _controller.value),
        ),
      ],
    ),
  );
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
        const Icon(
          Icons.currency_exchange_rounded,
          color: Color(0xFFF59E0B),
          size: 28,
        ),
      ],
    ),
  );
}
