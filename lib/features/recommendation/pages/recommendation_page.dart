import 'package:flutter/material.dart';

class RecommendationPage extends StatelessWidget {
  const RecommendationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rekomendasi Mata Kuliah"),
      ),
      body: const Center(
        child: Text(
          "Rekomendasi Mata Kuliah\n(Coming Soon)",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}