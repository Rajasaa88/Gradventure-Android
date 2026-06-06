import 'dart:convert'; // Wajib buat decode teks Base64 jadi gambar
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
      if (data['status'] == 'Lulus') {
        totalSKS += (data['sks'] ?? 0) as int;
      }
    }
    return totalSKS;
  }

  // Widget Card Menu yang udah di-upgrade biar lebih premium
  Widget _menuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color themeColor,
    Widget page,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.08),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          splashColor: themeColor.withValues(alpha: 0.1),
          highlightColor: themeColor.withValues(alpha: 0.05),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => page),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 28, color: themeColor),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF2D3142),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3142),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo2.png', height: 28),
            const SizedBox(width: 10),
            const Text(
              "Gradventure",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                fontSize: 20,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
            tooltip: 'Logout',
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
          const SizedBox(width: 8),
        ],
      ),
      // --- UPGRADE KE STREAMBUILDER BIAR REAL-TIME ---
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2B5CFA)));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Data user nggak ketemu nih 🥲"));
          }

          final user = snapshot.data!.data() as Map<String, dynamic>;
          
          // Ambil inisial nama buat fallback
          String initial = user['nama'].toString().isNotEmpty 
              ? user['nama'].toString()[0].toUpperCase() 
              : "U";

          // Ambil teks Base64 foto profil jika ada
          String? photoUrl = user.containsKey('photoUrl') ? user['photoUrl'] : null;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER SECTION ---
                  Row(
                    children: [
                      // --- DYNAMIC AVATAR (BASE64 / INITIAL TEXT) ---
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFF2B5CFA).withValues(alpha: 0.1),
                        backgroundImage: photoUrl != null 
                            ? MemoryImage(base64Decode(photoUrl)) 
                            : null,
                        child: photoUrl == null
                            ? Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2B5CFA),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Halo, ${user['nama'].toString().split(' ')[0]} 👋",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2D3142),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${user['nim']} • ${user['prodi']}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- SKS PROGRESS CARD ---
                  const Text(
                    "Target Kelulusan",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<int>(
                    future: getTotalSKSLulus(),
                    builder: (context, sksSnapshot) {
                      if (!sksSnapshot.hasData) {
                        return Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      }

                      int sksLulus = sksSnapshot.data ?? 0;
                      double progress = (sksLulus / 144).clamp(0.0, 1.0);

                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF334155)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E293B).withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      "SKS Terkumpul",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "${(progress * 100).toStringAsFixed(1)}%",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white.withValues(alpha: 0.15),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF50E3C2)),
                                minHeight: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "$sksLulus SKS",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  "144 SKS",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 35),

                  // --- MAIN MENU GRID ---
                  const Text(
                    "Layanan Academic",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.15,
                    children: [
                      _menuCard(context, "Mata\nKuliah", Icons.menu_book_rounded, const Color(0xFFF59E0B), const CoursePage()),
                      _menuCard(context, "Progress\nStudi", Icons.timeline_rounded, const Color(0xFF8B5CF6), const ProgressPage()),
                      _menuCard(context, "Roadmap\nKelulusan", Icons.route_rounded, const Color(0xFF3B82F6), const RoadmapPage()),
                      _menuCard(context, "Rekomendasi\nMatkul", Icons.lightbulb_rounded, const Color(0xFF10B981), const RecommendationPage()),
                      _menuCard(context, "Konsultasi\nDosen", Icons.forum_rounded, const Color(0xFFEC4899), const ConsultationPage()),
                      _menuCard(context, "Profil\nMahasiswa", Icons.person_rounded, const Color(0xFF64748B), const ProfilePage()),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}