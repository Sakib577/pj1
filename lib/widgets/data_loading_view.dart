import 'package:flutter/material.dart';

class DataLoadingView extends StatelessWidget {
  const DataLoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 14),
        Text('Loading your financial data…'),
      ],
    ),
  );
}
