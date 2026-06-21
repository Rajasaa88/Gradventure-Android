import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/percent_indicator.dart';

class RoadmapPage extends StatefulWidget {
  final bool openFilter;
  const RoadmapPage({super.key, this.openFilter = false});

  @override
  State<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends State<RoadmapPage> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  int _targetSemester = 8;
  String _statusFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    if (widget.openFilter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFilterSheet(context);
      });
    }
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Filter & Target Roadmap",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Target Semester Kelulusan",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [6, 7, 8, 9, 10].map((sem) {
                        bool isSelected = _targetSemester == sem;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text("Sem $sem"),
                            selected: isSelected,
                            selectedColor: const Color(0xFF2B5CFA),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  _targetSemester = sem;
                                });
                                setState(() {});
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Filter Status Mata Kuliah",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['Semua', 'Lulus', 'Belum Lulus'].map((status) {
                      bool isSelected = _statusFilter == status;
                      return ChoiceChip(
                        label: Text(status),
                        selected: isSelected,
                        selectedColor: const Color(0xFF2B5CFA),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              _statusFilter = status;
                            });
                            setState(() {});
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B5CFA),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Terapkan",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAllMilestones(BuildContext context, double currentPercent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Semua Milestone Kelulusan",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildDetailedMilestoneTile(
                      Icons.check_rounded,
                      "100 SKS Terlampaui",
                      "Syarat utama mengajukan proposal tugas akhir dan kerja praktik.",
                      true,
                    ),
                    const Divider(),
                    _buildDetailedMilestoneTile(
                      Icons.check_rounded,
                      "Kerja Praktik (KP)",
                      "Penerapan ilmu di dunia profesional / magang industri.",
                      true,
                    ),
                    const Divider(),
                    _buildDetailedMilestoneTile(
                      Icons.hourglass_empty_rounded,
                      "Seminar Proposal (Sempro)",
                      "Presentasi rencana penelitian tugas akhir / skripsi di depan penguji.",
                      false,
                      isWarning: true,
                    ),
                    const Divider(),
                    _buildDetailedMilestoneTile(
                      Icons.lock_rounded,
                      "Skripsi / Tugas Akhir",
                      "Penyusunan laporan akhir penelitian bersama dosen pembimbing.",
                      false,
                    ),
                    const Divider(),
                    _buildDetailedMilestoneTile(
                      Icons.lock_rounded,
                      "Sidang Akhir",
                      "Ujian akhir kelulusan untuk memperoleh gelar Sarjana.",
                      false,
                    ),
                    const Divider(),
                    _buildDetailedMilestoneTile(
                      Icons.lock_rounded,
                      "Wisuda",
                      "Pernyataan kelulusan resmi dan wisuda.",
                      false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailedMilestoneTile(IconData icon, String title, String description, bool isCompleted, {bool isWarning = false}) {
    Color bgColor = isCompleted ? const Color(0xFF10B981).withOpacity(0.1) : (isWarning ? const Color(0xFFF59E0B).withOpacity(0.1) : Colors.grey.shade100);
    Color iconColor = isCompleted ? const Color(0xFF10B981) : (isWarning ? const Color(0xFFF59E0B) : Colors.grey.shade400);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isCompleted ? "Selesai" : (isWarning ? "Siap Diambil" : "Terkunci"),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI AMBIL & OLAH DATA ROADMAP ---
  Future<Map<String, dynamic>> _getRoadmapData() async {
    Map<int, Map<String, dynamic>> roadmapData = {};
    int sksLulus = 0;
    int currentSemester = 1; // Default
    int targetSemester = _targetSemester;
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
      debugPrint("Error fetching roadmap: $e");
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
            onPressed: () {
              _showFilterSheet(context);
            },
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
                        var coursesList = (semData['courses'] as List).where((course) {
                          if (_statusFilter == 'Lulus') {
                            return course['isLulus'] == true;
                          } else if (_statusFilter == 'Belum Lulus') {
                            return course['isLulus'] == false;
                          }
                          return true;
                        }).toList();

                        bool isCompleted = sem < currentSemester;
                        bool isOnProgress = sem == currentSemester;
                        bool isFuture = sem > currentSemester;

                        Color cardColor = isCompleted || isOnProgress
                            ? const Color(0xFF2B5CFA)
                            : Colors.white;
                        Color textColor = isCompleted || isOnProgress
                            ? Colors.white
                            : const Color(0xFF1E293B);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isCompleted || isOnProgress ? cardColor : Colors.grey.shade200, width: 2),
                            boxShadow: [
                              if (isCompleted || isOnProgress)
                                BoxShadow(color: cardColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              iconColor: textColor,
                              collapsedIconColor: textColor,
                              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isCompleted || isOnProgress ? Colors.white.withOpacity(0.2) : const Color(0xFFF4F6F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isCompleted ? Icons.check_circle_rounded : Icons.flag_rounded,
                                      color: isCompleted || isOnProgress ? Colors.white : Colors.grey.shade400,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Semester $sem",
                                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textColor),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${semData['lulus_sks']} dari ${semData['total_sks']} SKS Lulus",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isCompleted || isOnProgress ? Colors.white.withOpacity(0.8) : Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                                  ),
                                  child: Column(
                                    children: coursesList.map<Widget>((course) {
                                      bool courseLulus = course['isLulus'];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          children: [
                                            Icon(
                                              courseLulus ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                              color: courseLulus ? const Color(0xFF10B981) : Colors.grey.shade300,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                course['nama'],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: courseLulus ? const Color(0xFF2D3142) : Colors.grey.shade500,
                                                  decoration: courseLulus ? TextDecoration.none : TextDecoration.lineThrough,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF4F6F9),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                "${course['sks']} SKS",
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
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
