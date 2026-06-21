import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../auth/pages/login_page.dart';
import '../../courses/pages/course_page.dart';
import '../../progress/pages/progress_page.dart';
import '../../roadmap/pages/roadmap_page.dart';
import '../../recommendation/pages/recommendation_page.dart';
import '../../consultation/pages/consultation_page.dart';
import '../../profile/pages/profile_page.dart';
import '../../consultation/pages/ai_chat_page.dart'; 
import '../../notification/pages/notification_page.dart'; // Sesuaikan sama folder lo ya

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0; // Buat state Bottom Navbar

  // --- FUNGSI AMBIL DATA PROGRESS SEKALIGUS ---
  Future<Map<String, dynamic>> getProgressData() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('student_courses')
        .doc(uid)
        .collection('courses')
        .get();

    int totalSKS = 0;
    int matkulLulus = 0;
    int matkulBerjalan = 0; // Asumsi matkul yang statusnya bukan Lulus/Belum Diambil

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['status'] == 'Lulus') {
        totalSKS += (data['sks'] ?? 0) as int;
        matkulLulus++;
      } else if (data['status'] != 'Belum Diambil' && data['status'] != null) {
        matkulBerjalan++;
      }
    }
    
    // Default total matkul di TI biasanya sekitar 86
    return {
      'totalSKS': totalSKS,
      'matkulLulus': matkulLulus,
      'matkulBerjalan': matkulBerjalan,
    };
  }

  // --- WIDGET MENU CARD ---
  Widget _menuCard(BuildContext context, String title, String subtitle, IconData icon, Color iconColor, Color bgColor, Widget page) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500, height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET STAT ITEM KECIL DI CARD PROGRESS ---
  Widget _statItem(IconData icon, Color iconColor, Color bgColor, String title, String value, {String? total}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
            Row(
              children: [
                Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: iconColor)),
                if (total != null) Text(" / $total", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Background super terang ala mockup
      
      // --- APP BAR CUSTOM ---
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        titleSpacing: 24,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFF2B5CFA), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text("Gradventure", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1E293B))),
          ],
        ),
        actions: [
          IconButton(
            padding: const EdgeInsets.only(right: 24),
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B), size: 28),
                Positioned(
                  right: 2, top: 2,
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  ),
                ),
              ],
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPage())),
          ),
        ],
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2B5CFA)));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();

          final user = snapshot.data!.data() as Map<String, dynamic>;
          String initial = user['nama'].toString().isNotEmpty ? user['nama'].toString()[0].toUpperCase() : "U";
          String? photoUrl = user.containsKey('photoUrl') ? user['photoUrl'] : null;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- PROFILE HEADER ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: const Color(0xFF2B5CFA).withOpacity(0.1),
                      backgroundImage: photoUrl != null ? MemoryImage(base64Decode(photoUrl)) : null,
                      child: photoUrl == null ? Text(initial, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2B5CFA))) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Halo, ${user['nama'].toString().split(' ')[0]}",
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(width: 6),
                              const Text("👋", style: TextStyle(fontSize: 20)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text("${user['nim']} • ${user['prodi']}", style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          // Pill Target Lulus
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.track_changes_rounded, size: 14, color: Color(0xFF2B5CFA)),
                                const SizedBox(width: 6),
                                const Text("Target Lulus: Semester 8", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                                const SizedBox(width: 12),
                                Text("Ubah", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2B5CFA).withOpacity(0.8))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // --- PROGRESS KELULUSAN CARD ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: getProgressData(),
                    builder: (context, progressSnap) {
                      int sksLulus = progressSnap.data?['totalSKS'] ?? 0;
                      int matkulLulus = progressSnap.data?['matkulLulus'] ?? 0;
                      int matkulBerjalan = progressSnap.data?['matkulBerjalan'] ?? 0;
                      double percent = (sksLulus / 144).clamp(0.0, 1.0);

                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Ringkasan Progres", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                              InkWell(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoadmapPage())),
                                child: Text("Lihat Detail >", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2B5CFA).withOpacity(0.8))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              // Circular Chart
                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: [
                                    const Text("Progress Kelulusan", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                                    const SizedBox(height: 12),
                                    CircularPercentIndicator(
                                      radius: 50.0,
                                      lineWidth: 10.0,
                                      animation: true,
                                      percent: percent,
                                      circularStrokeCap: CircularStrokeCap.round,
                                      progressColor: const Color(0xFF2B5CFA),
                                      backgroundColor: const Color(0xFF2B5CFA).withOpacity(0.1),
                                      center: Text(
                                        "${(percent * 100).toStringAsFixed(1)}%",
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B)),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text("$sksLulus", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B5CFA), fontSize: 13)),
                                        Text(" / 144 SKS", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade600, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Vertical Stats
                              Expanded(
                                flex: 6,
                                child: Container(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Column(
                                    children: [
                                      InkWell(
                                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressPage())),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: _statItem(Icons.check_circle_rounded, const Color(0xFF10B981), const Color(0xFF10B981).withOpacity(0.1), "Mata Kuliah Selesai", "$matkulLulus", total: "86"),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      InkWell(
                                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoursePage())),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: _statItem(Icons.access_time_filled_rounded, const Color(0xFFF59E0B), const Color(0xFFF59E0B).withOpacity(0.1), "Sedang Ditempuh", "$matkulBerjalan Matkul"),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      InkWell(
                                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoadmapPage())),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: _statItem(Icons.track_changes_rounded, const Color(0xFF8B5CF6), const Color(0xFF8B5CF6).withOpacity(0.1), "Estimasi Lulus", "Semester 8"),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Alert Box Bawah
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(color: const Color(0xFF2B5CFA).withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                const Icon(Icons.bar_chart_rounded, color: Color(0xFF2B5CFA), size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Kamu berada di jalur yang sesuai", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2B5CFA))),
                                      Text("Pertahankan progresmu!", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFF2B5CFA), size: 16),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // --- MENU UTAMA GRID ---
                const Text("Menu Utama", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9, // Disesuaikan biar proporsi kartunya pas
                  children: [
                    _menuCard(context, "Mata Kuliah", "Lihat & kelola mata\nkuliah kamu", Icons.menu_book_rounded, const Color(0xFF8B5CF6), const Color(0xFF8B5CF6).withOpacity(0.1), const CoursePage()),
                    _menuCard(context, "Progress Studi", "Pantau perkembangan\nstudi kamu", Icons.insert_chart_rounded, const Color(0xFF10B981), const Color(0xFF10B981).withOpacity(0.1), const ProgressPage()),
                    _menuCard(context, "Roadmap Kelulusan", "Rencana perjalananmu\nsampai lulus", Icons.map_rounded, const Color(0xFF3B82F6), const Color(0xFF3B82F6).withOpacity(0.1), const RoadmapPage()),
                    _menuCard(context, "Rekomendasi Matkul", "Dapatkan rekomendasi\nmatkul terbaik", Icons.lightbulb_rounded, const Color(0xFFF59E0B), const Color(0xFFF59E0B).withOpacity(0.1), const RecommendationPage()),
                    _menuCard(context, "Konsultasi AI", "Tanya apapun seputar\nstudi ke AI", Icons.smart_toy_rounded, const Color(0xFFEC4899), const Color(0xFFEC4899).withOpacity(0.1), const AiChatPage()),
                    _menuCard(context, "Konsultasi Dosen", "Catat jadwal & riwayat\nkonsultasi", Icons.calendar_month_rounded, const Color(0xFF14B8A6), const Color(0xFF14B8A6).withOpacity(0.1), const ConsultationPage()),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),

      // --- MOCKUP BOTTOM NAVIGATION BAR ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Buka AI Chat pas FAB dipencet
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatPage()));
        },
        backgroundColor: const Color(0xFF2B5CFA),
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 20,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavButton(Icons.home_rounded, "Beranda", 0),
              _buildNavButton(Icons.calendar_today_rounded, "Kalender", 1),
              const SizedBox(width: 40), // Space buat FAB di tengah
              _buildNavButton(Icons.notifications_none_rounded, "Notifikasi", 2, badge: "3"),
              _buildNavButton(Icons.person_outline_rounded, "Profil", 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, String label, int index, {String? badge}) {
    bool isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _currentIndex = index);
        
        if (index == 1) { 
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ConsultationPage()))
              .then((_) => setState(() => _currentIndex = 0)); 
        } else if (index == 2) { // <-- UBAH BAGIAN INI
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPage()))
              .then((_) => setState(() => _currentIndex = 0));
        } else if (index == 3) { 
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()))
              .then((_) => setState(() => _currentIndex = 0));
        }
      },
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Icon(icon, color: isSelected ? const Color(0xFF2B5CFA) : Colors.grey.shade400, size: 24),
                if (badge != null)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF2B5CFA) : Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}