import 'package:flutter/material.dart';

class RoadmapPage extends StatelessWidget {
  const RoadmapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Roadmap Kelulusan"),
      ),
      body: const Center(
        child: Text(
          "Roadmap Kelulusan\n(Coming Soon)",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}