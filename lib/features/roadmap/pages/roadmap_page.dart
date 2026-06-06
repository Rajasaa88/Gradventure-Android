import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoadmapPage extends StatefulWidget {
  const RoadmapPage({super.key});

  @override
  State<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends State<RoadmapPage> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  // Fungsi buat ngambil data dari Master Courses dan Student Courses barengan
  Future<Map<int, Map<String, dynamic>>> _getRoadmapData() async {
    Map<int, Map<String, dynamic>> roadmapData = {}; // Format: { Semester: { 'total': x, 'lulus': y, 'courses': [...] } }

    try {
      // 1. Tarik semua data dari Gudang Master
      var masterSnapshot = await FirebaseFirestore.instance.collection('courses').get();
      
      // 2. Tarik data dari koper Mahasiswa
      var studentSnapshot = await FirebaseFirestore.instance
          .collection('student_courses')
          .doc(uid)
          .collection('courses')
          .get();

      // Bikin map buat nyari status matkul mahasiswa dengan cepet
      Map<String, String> studentStatusMap = {};
      for (var doc in studentSnapshot.docs) {
        studentStatusMap[doc.id] = doc.data()['status'] ?? 'Belum Diambil';
      }

      // 3. Kelompokkin matkul master ke dalam semester-semesternya
      for (var doc in masterSnapshot.docs) {
        var data = doc.data();
        int sem = int.tryParse(data['semester']?.toString() ?? data['semester_tempuh']?.toString() ?? '0') ?? 0;
        
        if (sem > 0 && sem <= 8) { // Fokus semester 1 sampe 8 aja
          String status = studentStatusMap[doc.id] ?? 'Belum Diambil';
          bool isLulus = status == 'Lulus';

          if (!roadmapData.containsKey(sem)) {
            roadmapData[sem] = {'total': 0, 'lulus': 0, 'courses': []};
          }

          roadmapData[sem]!['total'] += 1;
          if (isLulus) roadmapData[sem]!['lulus'] += 1;
          
          roadmapData[sem]!['courses'].add({
            'kode': data['kode'] ?? doc.id,
            'nama': data['nama'] ?? 'Mata Kuliah',
            'sks': data['sks'] ?? 0,
            'status': status,
            'isLulus': isLulus,
          });
        }
      }

      return roadmapData;
    } catch (e) {
      debugPrint("Error fetching roadmap: $e");
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Roadmap Kelulusan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3142),
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<int, Map<String, dynamic>>>(
        future: _getRoadmapData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2B5CFA)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.route_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("Data master kurikulum belum lengkap nih.", style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          var roadmapData = snapshot.data!;
          List<int> semesters = roadmapData.keys.toList()..sort();

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            itemCount: semesters.length,
            itemBuilder: (context, index) {
              int sem = semesters[index];
              var semData = roadmapData[sem]!;
              bool isCompleted = semData['lulus'] == semData['total'];
              bool isOnProgress = semData['lulus'] > 0 && !isCompleted;
              
              Color cardColor = isCompleted ? const Color(0xFF10B981) : (isOnProgress ? const Color(0xFF2B5CFA) : Colors.white);
              Color textColor = isCompleted || isOnProgress ? Colors.white : const Color(0xFF2D3142);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isCompleted || isOnProgress ? cardColor : Colors.grey.shade200, width: 2),
                  boxShadow: [
                    if (isCompleted || isOnProgress) 
                      BoxShadow(color: cardColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // Ngilangin border pas di-expand
                  child: ExpansionTile(
                    iconColor: textColor,
                    collapsedIconColor: textColor,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isCompleted || isOnProgress ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFF4F6F9),
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
                                "${semData['lulus']} dari ${semData['total']} Matkul Selesai",
                                style: TextStyle(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.w600,
                                  color: isCompleted || isOnProgress ? Colors.white.withValues(alpha: 0.8) : Colors.grey.shade500,
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
                          children: (semData['courses'] as List).map<Widget>((course) {
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
          );
        },
      ),
    );
  }
}
