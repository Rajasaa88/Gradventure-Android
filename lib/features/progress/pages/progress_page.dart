import 'package:flutter/material.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Progress Studi"),
      ),
      body: const Center(
        child: Text(
          "Progress Studi\n(Coming Soon)",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}