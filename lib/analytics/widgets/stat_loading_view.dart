import 'package:flutter/material.dart';

/// A simple skeleton/spinner used inside stat cards while data is loading.
class StatLoadingView extends StatelessWidget {
  const StatLoadingView({super.key, this.height = 90});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}