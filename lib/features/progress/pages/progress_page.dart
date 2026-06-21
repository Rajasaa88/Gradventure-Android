import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../roadmap/pages/roadmap_page.dart';
import '../../notification/pages/notification_page.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  // --- FUNGSI KONVERSI NILAI KE BOBOT ANGKA ---
  double _getGradeWeight(String grade) {
    switch (grade) {
      case 'A': return 4.0;
      case 'B+': return 3.5;
      case 'B': return 3.0;
      case 'C+': return 2.5;
      case 'C': return 2.0;
      case 'D': return 1.0;
      case 'E': return 0.0;
      default: return 0.0;
    }
  }

  // --- WIDGET HELPER BUAT CARD STATISTIK ---
  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 2),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF2D3142))),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text("Progress Studi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPage()));
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('student_courses')
            .doc(uid)
            .collection('courses')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2B5CFA)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada data akademik."));
          }

          // 1. Tentukan Semester Aktif/Saat Ini secara dinamis
          int currentSemester = 1;
          List<int> activeSemesters = [];
          
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? '';
            String grade = data['nilai'] ?? '';
            int sem = int.tryParse(data['semester_tempuh']?.toString() ?? data['semester']?.toString() ?? '0') ?? 0;
            
            if ((status == 'Sedang Ditempuh' || grade == 'Sedang Ditempuh') && sem > 0) {
              activeSemesters.add(sem);
            }
          }

          if (activeSemesters.isNotEmpty) {
            // Gunakan semester aktif tertinggi
            currentSemester = activeSemesters.reduce((a, b) => a > b ? a : b);
          } else {
            // Fallback ke max semester lulus + 1
            int maxPassedSem = 0;
            for (var doc in snapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              String status = data['status'] ?? '';
              int sem = int.tryParse(data['semester_tempuh']?.toString() ?? data['semester']?.toString() ?? '0') ?? 0;
              if (status == 'Lulus' && sem > maxPassedSem) {
                maxPassedSem = sem;
              }
            }
            currentSemester = maxPassedSem > 0 ? maxPassedSem : 1;
          }

          // 2. Kumpulkan Mata Kuliah Semester Ini & Hitung Statistiknya
          List<Map<String, dynamic>> thisSemesterCourses = [];
          int totalSksSemesterIni = 0;
          int sksLulusSemesterIni = 0;
          int sksAktifSemesterIni = 0;
          double totalBobotSemesterIni = 0.0;
          List<Map<String, dynamic>> warningCoursesSemesterIni = [];

          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            int sem = int.tryParse(data['semester_tempuh']?.toString() ?? data['semester']?.toString() ?? '0') ?? 0;
            String status = data['status'] ?? 'Belum Diambil';
            String grade = data['nilai'] ?? '-';
            int sks = data['sks'] ?? 0;

            // Masuk dalam kategori semester ini jika semesternya cocok
            if (sem == currentSemester) {
              thisSemesterCourses.add({
                'id': doc.id,
                'nama': data['nama'] ?? 'Mata Kuliah',
                'kode': data['kode'] ?? '-',
                'sks': sks,
                'status': status,
                'nilai': grade,
              });

              totalSksSemesterIni += sks;

              if (status == 'Lulus') {
                sksLulusSemesterIni += sks;
                totalBobotSemesterIni += _getGradeWeight(grade) * sks;
                
                if (grade == 'C' || grade == 'D' || grade == 'E') {
                  warningCoursesSemesterIni.add({
                    'nama': data['nama'] ?? 'Mata Kuliah',
                    'nilai': grade,
                  });
                }
              } else if (status == 'Sedang Ditempuh') {
                sksAktifSemesterIni += sks;
              }
            }
          }

          double ipsSemesterIni = sksLulusSemesterIni > 0 
              ? (totalBobotSemesterIni / sksLulusSemesterIni) 
              : 0.0;

          double percentLulusSem = totalSksSemesterIni > 0 
              ? (sksLulusSemesterIni / totalSksSemesterIni).clamp(0.0, 1.0) 
              : 0.0;

          Color semColor = const Color(0xFF2B5CFA); // default biru

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HERO CARD SEMESTER INI ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [semColor.withOpacity(0.85), semColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: semColor.withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Semester $currentSemester Aktif 🎓",
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "$sksLulusSemesterIni dari $totalSksSemesterIni SKS Lulus",
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: percentLulusSem,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${(percentLulusSem * 100).toStringAsFixed(1)}% Selesai",
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // --- DETAIL STATS GRID ---
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "IPS Sementara",
                        ipsSemesterIni.toStringAsFixed(2),
                        Icons.star_rounded,
                        const Color(0xFFF59E0B), // Kuning emas
                        "IPS semester ini",
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        "SKS Ditempuh",
                        "$sksAktifSemesterIni SKS",
                        Icons.menu_book_rounded,
                        const Color(0xFF10B981), // Ijo
                        "Sedang berjalan",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // --- DAFTAR MATA KULIAH SEMESTER INI ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Mata Kuliah Semester Ini",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RoadmapPage()));
                      },
                      child: Text(
                        "Roadmap Kelulusan >",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: semColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (thisSemesterCourses.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100, width: 2),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.layers_clear_rounded, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          "Tidak ada mata kuliah untuk semester ini.",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: thisSemesterCourses.length,
                    itemBuilder: (context, index) {
                      final course = thisSemesterCourses[index];
                      final status = course['status'];
                      final grade = course['nilai'];

                      Color statusBgColor = Colors.grey.shade100;
                      Color statusTxtColor = Colors.grey.shade600;
                      String statusText = "Belum Diambil";

                      if (status == 'Lulus') {
                        statusBgColor = const Color(0xFF10B981).withOpacity(0.12);
                        statusTxtColor = const Color(0xFF047857);
                        statusText = "Lulus (Nilai $grade)";
                      } else if (status == 'Sedang Ditempuh') {
                        statusBgColor = const Color(0xFF2B5CFA).withOpacity(0.12);
                        statusTxtColor = const Color(0xFF1D4ED8);
                        statusText = "Sedang Ditempuh";
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100, width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course['nama'],
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${course['kode']} • ${course['sks']} SKS",
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(color: statusTxtColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 28),

                // --- PERLU PERHATIAN / WARNINGS ---
                const Text(
                  "Perlu Perhatian Semester Ini 👀",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 16),
                
                if (warningCoursesSemesterIni.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.celebration_rounded, color: Color(0xFF10B981)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: const Text(
                            "Hebat! Tidak ada nilai di bawah B- untuk semester ini. 🚀",
                            style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: warningCoursesSemesterIni.length,
                    itemBuilder: (context, index) {
                      final course = warningCoursesSemesterIni[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.12), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: Colors.redAccent.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
                              child: Text(
                                course['nilai'],
                                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course['nama'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142), fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Nilai kurang memuaskan. Mungkin perlu diulang di semester penawaran berikutnya.",
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}