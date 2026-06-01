import 'package:flutter/material.dart';

class ConsultationPage extends StatelessWidget {
  const ConsultationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Konsultasi Akademik"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          Card(
            child: ListTile(
              leading: const Icon(Icons.smart_toy),
              title: const Text("AI Academic Advisor"),
              subtitle: const Text(
                "Konsultasi akademik dengan AI",
              ),
              onTap: () {},
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text("Jadwal Konsultasi"),
              subtitle: const Text(
                "Ajukan jadwal bimbingan",
              ),
              onTap: () {},
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.note_alt),
              title: const Text("Riwayat Bimbingan"),
              subtitle: const Text(
                "Catatan hasil konsultasi",
              ),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}