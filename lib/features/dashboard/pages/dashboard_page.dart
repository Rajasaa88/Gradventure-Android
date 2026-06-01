import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Pastikan import ini sesuai sama path lo ya
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
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data() as Map<String, dynamic>?;
  }

  Future<int> getTotalSKSLulus() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('student_courses')
        .doc(uid)
        .collection('courses')
        .get();

    int totalSKS = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      // Validasi biar yang dihitung cuma yang beneran "Lulus"
      if (data['status'] == 'Lulus') {
        totalSKS += (data['sks'] ?? 0) as int;
      }
    }
    return totalSKS;
  }

  // Widget buat bikin Card Menu yang lebih aesthetic
  Widget _menuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color iconColor,
    Widget page,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Nanti ini bisa diganti pake context.push('/namaroute') kalo GoRouter udah ready
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => page),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: iconColor),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Warna background abu-abu super soft
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          "Gradventure",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("Data user nggak ketemu nih 🥲"));
          }

          final user = snapshot.data!;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Profile Area
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Halo, ${user['nama']} 👋",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${user['nim']} • ${user['prodi']}",
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // SKS Progress Tracker
                      FutureBuilder<int>(
                        future: getTotalSKSLulus(),
                        builder: (context, sksSnapshot) {
                          if (!sksSnapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          int sksLulus = sksSnapshot.data ?? 0;
                          double progress = (sksLulus / 144).clamp(0.0, 1.0);

                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4A90E2).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Progress Studi",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      "${(progress * 100).toStringAsFixed(1)}%",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.3),
                                    valueColor: const AlwaysStoppedAnimation<
                                        Color>(Colors.white),
                                    minHeight: 10,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "$sksLulus / 144 SKS Lulus",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Main Menu Area
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Eksplor Fitur",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1, // Biar kotaknya proporsional
                        children: [
                          _menuCard(context, "Mata Kuliah", Icons.menu_book_rounded, Colors.orange, const CoursePage()),
                          _menuCard(context, "Progress", Icons.timeline_rounded, Colors.purple, const ProgressPage()),
                          _menuCard(context, "Roadmap", Icons.route_rounded, Colors.blue, const RoadmapPage()),
                          _menuCard(context, "Rekomendasi", Icons.lightbulb_rounded, Colors.amber, const RecommendationPage()),
                          _menuCard(context, "Konsultasi", Icons.forum_rounded, Colors.teal, const ConsultationPage()),
                          _menuCard(context, "Profil", Icons.person_rounded, Colors.grey, const ProfilePage()),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}