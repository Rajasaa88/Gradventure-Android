import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/percent_indicator.dart';

class RoadmapPage extends StatefulWidget {
  const RoadmapPage({super.key});

  @override
  State<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends State<RoadmapPage> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  // --- FUNGSI AMBIL & OLAH DATA ROADMAP ---
  Future<Map<String, dynamic>> _getRoadmapData() async {
    Map<int, Map<String, dynamic>> roadmapData = {};
    int sksLulus = 0;
    int currentSemester = 1; // Default
    int targetSemester = 8; // Default lulus S1
    int totalSksTarget = 144;

    try {
      var masterSnapshot = await FirebaseFirestore.instance.collection('courses').get();
      var studentSnapshot = await FirebaseFirestore.instance
          .collection('student_courses')
          .doc(uid)
          .collection('courses')
          .get();

      Map<String, Map<String, dynamic>> studentDataMap = {};
      for (var doc in studentSnapshot.docs) {
        studentDataMap[doc.id] = doc.data();
      }

      for (var doc in masterSnapshot.docs) {
        var data = doc.data();
        int sem = int.tryParse(data['semester']?.toString() ?? data['semester_tempuh']?.toString() ?? '0') ?? 0;
        int sks = data['sks'] ?? 0;
        
        if (sem > 0 && sem <= targetSemester) {
          var studentCourse = studentDataMap[doc.id];
          String status = studentCourse?['status'] ?? 'Belum Diambil';
          bool isLulus = status == 'Lulus';
          bool isSedangDitempuh = status == 'Sedang Ditempuh';

          // Kalkulasi SKS & Semester Saat Ini
          if (isLulus) {
            sksLulus += sks;
            // Kalau lulus, asumsi kita udah ngelewatin semester itu
            if (sem >= currentSemester) currentSemester = sem + 1; 
          } else if (isSedangDitempuh) {
            // Kalau ada yang lagi ditempuh, fix itu semester kita sekarang
            if (sem > currentSemester) currentSemester = sem;
          }

          if (!roadmapData.containsKey(sem)) {
            roadmapData[sem] = {'total_sks': 0, 'lulus_sks': 0, 'courses': []};
          }

          roadmapData[sem]!['total_sks'] += sks;
          if (isLulus) roadmapData[sem]!['lulus_sks'] += sks;
          
          roadmapData[sem]!['courses'].add({
            'kode': data['kode'] ?? doc.id,
            'nama': data['nama'] ?? 'Mata Kuliah',
            'sks': sks,
            'status': status,
            'isLulus': isLulus,
            'isSedangDitempuh': isSedangDitempuh,
          });
        }
      }

      // Pastikan currentSemester gak lebih dari target (mentok 8)
      if (currentSemester > targetSemester) currentSemester = targetSemester;

      return {
        'roadmap': roadmapData,
        'sksLulus': sksLulus,
        'currentSemester': currentSemester,
        'targetSemester': targetSemester,
        'totalSksTarget': totalSksTarget,
      };
    } catch (e) {
      print("Error fetching roadmap: $e");
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Background terang
      appBar: AppBar(
        title: const Text("Roadmap Kelulusan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF1E293B)),
            onPressed: () {},
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getRoadmapData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2B5CFA)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Data kurikulum belum lengkap."));
          }

          var data = snapshot.data!;
          Map<int, dynamic> roadmap = data['roadmap'];
          int sksLulus = data['sksLulus'];
          int currentSemester = data['currentSemester'];
          int targetSemester = data['targetSemester'];
          int totalSksTarget = data['totalSksTarget'];

          int sisaSks = totalSksTarget - sksLulus;
          int sisaSemester = targetSemester - currentSemester + 1;
          // Hindari pembagian dengan 0
          int rataRataSks = sisaSemester > 0 ? (sisaSks / sisaSemester).ceil() : 0; 
          double percent = (sksLulus / totalSksTarget).clamp(0.0, 1.0);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HERO CARD (Target Lulus) ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE0E7FF), Color(0xFFF5F7FF)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFD1D5DB).withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      // Kiri: Info Target
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.flag_rounded, color: Color(0xFF2B5CFA), size: 20),
                                const SizedBox(width: 8),
                                Text("Target Lulus", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text("Semester 8", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF1E293B))),
                            const SizedBox(height: 4),
                            Text("Agustus 2027", style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2B5CFA).withOpacity(0.2))),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.trending_up_rounded, color: Color(0xFF2B5CFA), size: 14),
                                  SizedBox(width: 6),
                                  Text("Kamu on track! 👏", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2B5CFA))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Kanan: Circular Progress
                      CircularPercentIndicator(
                        radius: 45.0,
                        lineWidth: 10.0,
                        animation: true,
                        percent: percent,
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: const Color(0xFF2B5CFA),
                        backgroundColor: Colors.white,
                        center: Text(
                          "${(percent * 100).toInt()}%",
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF1E293B)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- STAT ROW (Sisa SKS & Rata-rata) ---
                Row(
                  children: [
                    _buildStatBox("Sisa SKS", "$sisaSks"),
                    const SizedBox(width: 12),
                    _buildStatBox("Rata-rata perlu", "$rataRataSks SKS", subtitle: "/ semester"),
                    const SizedBox(width: 12),
                    _buildStatBox("Estimasi Lulus", "Sem $targetSemester"),
                  ],
                ),
                const SizedBox(height: 32),

                // --- TIMELINE HEADER ---
                const Text("Perjalanan Akademik", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                const SizedBox(height: 16),

                // --- TIMELINE LIST ---
                Stack(
                  children: [
                    // Garis Vertikal Timeline
                    Positioned(
                      left: 19, // Posisi presisi di tengah icon bulat
                      top: 20,
                      bottom: 40,
                      child: Container(width: 2, color: Colors.grey.shade300),
                    ),
                    // Item Semester
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: targetSemester,
                      itemBuilder: (context, index) {
                        int sem = index + 1;
                        var semData = roadmap[sem] ?? {'total_sks': 0, 'lulus_sks': 0, 'courses': []};
                        
                        bool isCompleted = sem < currentSemester;
                        bool isCurrent = sem == currentSemester;
                        bool isFuture = sem > currentSemester;

                        // Desain icon bulat
                        Widget timelineNode;
                        if (isCompleted) {
                          timelineNode = Container(
                            width: 24, height: 24,
                            decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                          );
                        } else if (isCurrent) {
                          timelineNode = Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF2B5CFA), width: 6)),
                          );
                        } else {
                          timelineNode = Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade400, width: 3)),
                            child: sem == targetSemester ? Icon(Icons.flag_rounded, color: Colors.grey.shade400, size: 14) : null,
                          );
                        }

                        // Ngambil contoh matkul buat subtitle (mirip di mockup)
                        String subtitleStr = "";
                        if (isCurrent || isFuture) {
                          List courses = semData['courses'];
                          if (courses.isNotEmpty) {
                            var sample = courses.take(2).map((c) => c['nama']).join(", ");
                            subtitleStr = courses.length > 2 ? "$sample, ..." : sample;
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Area Icon & Background Putih biar garis ketutup
                              Container(
                                color: const Color(0xFFFAFAFA),
                                padding: const EdgeInsets.only(left: 8, right: 16, top: 12, bottom: 12),
                                child: timelineNode,
                              ),
                              // Area Kartu Konten
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                                  ),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                      iconColor: Colors.grey.shade600,
                                      collapsedIconColor: Colors.grey.shade400,
                                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      title: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    "Semester $sem",
                                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isCurrent ? const Color(0xFF2B5CFA) : const Color(0xFF1E293B)),
                                                  ),
                                                  if (isCurrent) ...[
                                                    const SizedBox(width: 6),
                                                    Text("(Saat Ini)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2B5CFA).withOpacity(0.8))),
                                                  ]
                                                ],
                                              ),
                                              if (subtitleStr.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                SizedBox(
                                                  width: 140, // Batasin lebar biar gak nabrak SKS
                                                  child: Text(subtitleStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                ),
                                              ]
                                            ],
                                          ),
                                          Text(
                                            isCompleted ? "${semData['total_sks']} SKS" : (isCurrent ? "${semData['total_sks']} SKS" : "18-24 SKS"),
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
                                          child: Column(
                                            children: (semData['courses'] as List).map<Widget>((course) {
                                              bool courseLulus = course['isLulus'];
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 8),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      courseLulus ? Icons.check_circle_rounded : Icons.circle_outlined,
                                                      color: courseLulus ? const Color(0xFF10B981) : Colors.grey.shade400,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        course['nama'],
                                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: courseLulus ? const Color(0xFF1E293B) : Colors.grey.shade600),
                                                      ),
                                                    ),
                                                    Text("${course['sks']} SKS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- MILESTONE KELULUSAN ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Milestone Kelulusan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                    Text("Lihat semua", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade400)),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildMilestoneItem(Icons.check_rounded, "100 SKS", true),
                      _buildMilestoneItem(Icons.check_rounded, "Kerja Praktik", true),
                      _buildMilestoneItem(Icons.hourglass_empty_rounded, "Seminar Proposal", false, isWarning: true),
                      _buildMilestoneItem(Icons.lock_rounded, "Skripsi", false),
                      _buildMilestoneItem(Icons.lock_rounded, "Sidang", false),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // --- INSIGHT GRADVENTURE BANNER ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFF3E8FF), Color(0xFFE0E7FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6), size: 18),
                                SizedBox(width: 8),
                                Text("Insight Gradventure", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF4C1D95))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text("Untuk lulus di Semester $targetSemester, usahakan ambil minimal $rataRataSks SKS setiap semester ya!", style: const TextStyle(fontSize: 12, color: Color(0xFF5B21B6), height: 1.4)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF2B5CFA), size: 32),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper function buat Kotak Statistik
  Widget _buildStatBox(String title, String value, {String? subtitle}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
            ]
          ],
        ),
      ),
    );
  }

  // Helper function buat Milestone Item
  Widget _buildMilestoneItem(IconData icon, String title, bool isCompleted, {bool isWarning = false}) {
    Color bgColor = isCompleted ? const Color(0xFF10B981).withOpacity(0.1) : (isWarning ? const Color(0xFFF59E0B).withOpacity(0.1) : Colors.grey.shade100);
    Color iconColor = isCompleted ? const Color(0xFF10B981) : (isWarning ? const Color(0xFFF59E0B) : Colors.grey.shade400);
    
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), textAlign: TextAlign.center, maxLines: 2),
          ),
        ],
      ),
    );
  }
}