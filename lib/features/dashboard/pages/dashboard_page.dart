import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/pages/login_page.dart';
import '../../courses/pages/course_page.dart';
import '../../progress/pages/progress_page.dart';
import '../../roadmap/pages/roadmap_page.dart';
import '../../recommendation/pages/recommendation_page.dart';
import '../../consultation/pages/consultation_page.dart';
import '../../profile/pages/profile_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<Map<String, dynamic>?> getUserData() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    return doc.data() as Map<String, dynamic>?;
  }

  Future<int> getTotalSKSLulus() async {
  String uid =
      FirebaseAuth.instance.currentUser!.uid;

  QuerySnapshot snapshot =
      await FirebaseFirestore.instance
          .collection('student_courses')
          .doc(uid)
          .collection('courses')
          .get();

  int totalSKS = 0;

  for (var doc in snapshot.docs) {
    final data =
        doc.data() as Map<String, dynamic>;

    totalSKS +=
        (data['sks'] ?? 0) as int;
  }

  return totalSKS;
}

Widget _menuCard(
  BuildContext context,
  String title,
  IconData icon,
  Widget page,
) {
  return Card(
    elevation: 3,
    child: InkWell(
      borderRadius:
          BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => page,
          ),
        );
      },
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gradventure"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginPage(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text("Data user tidak ditemukan"),
            );
          }

          final user = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  "Halo, ${user['nama']} 👋",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          "NIM : ${user['nim']}",
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Prodi : ${user['prodi']}",
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Angkatan : ${user['angkatan']}",
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                FutureBuilder<int>(
  future: getTotalSKSLulus(),
  builder: (context, sksSnapshot) {

    if (!sksSnapshot.hasData) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child:
                CircularProgressIndicator(),
          ),
        ),
      );
    }

    int sksLulus =
        sksSnapshot.data ?? 0;

    double progress =
        sksLulus / 144;

    return Card(
      elevation: 3,
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [

            const Text(
              "Progress Studi",
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "SKS Lulus : $sksLulus",
              style: const TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              "Target : 144 SKS",
            ),

            const SizedBox(height: 10),

            LinearProgressIndicator(
              value: progress,
            ),

            const SizedBox(height: 8),

            Text(
              "${(progress * 100).toStringAsFixed(1)} %",
            ),
          ],
        ),
      ),
    );
  },
),
                const SizedBox(height: 30),

               const Text(
  "Menu Utama",
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 15),

GridView.count(
  shrinkWrap: true,
  physics:
      const NeverScrollableScrollPhysics(),
  crossAxisCount: 2,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
  childAspectRatio: 1.2,
  children: [

    _menuCard(
      context,
      "Mata Kuliah",
      Icons.menu_book,
      const CoursePage(),
    ),

    _menuCard(
      context,
      "Progress",
      Icons.school,
      const ProgressPage(),
    ),

    _menuCard(
      context,
      "Roadmap",
      Icons.route,
      const RoadmapPage(),
    ),

    _menuCard(
      context,
      "Rekomendasi",
      Icons.lightbulb,
      const RecommendationPage(),
    ),

    _menuCard(
      context,
      "Konsultasi",
      Icons.forum,
      const ConsultationPage(),
    ),

    _menuCard(
      context,
      "Profil",
      Icons.person,
      const ProfilePage(),
    ),
  ],
)
              ],
            ),
          );
        },
      ),
    );
  }
}