import 'package:flutter/material.dart';

/// Centred progress indicator for screens that are loading.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(semanticsLabel: 'Loading'),
    );
  }
}
