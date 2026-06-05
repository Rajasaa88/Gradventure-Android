import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  int selectedSemester = 1;

  final List<String> gradeOptions = ['A', 'B+', 'B', 'C+', 'C', 'D', 'E', 'Sedang Ditempuh', 'Belum Diambil'];

  // --- FUNGSI UPDATE NILAI KE FIRESTORE PRIBADI ---
  Future<void> _updateGrade(String courseId, Map<String, dynamic> masterData, String newGrade) async {
    String newStatus;
    if (newGrade == 'Belum Diambil' || newGrade == 'E') {
      newStatus = 'Belum Diambil';
    } else if (newGrade == 'Sedang Ditempuh') {
      newStatus = 'Sedang Ditempuh'; // <-- Status baru masuk sini
    } else {
      newStatus = 'Lulus';
    }

    try {
      // Kita pake .set() dengan merge: true. 
      // Artinya: Kalo matkulnya belum ada di koper user, bakal DIBUAT. Kalo udah ada, bakal DIUPDATE.
      await FirebaseFirestore.instance
          .collection('student_courses')
          .doc(uid)
          .collection('courses')
          .doc(courseId)
          .set({
        'kode': masterData['kode'] ?? courseId,
        'nama': masterData['nama'] ?? 'Mata Kuliah',
        'sks': masterData['sks'] ?? 0,
        // Antisipasi jaga-jaga kalo fieldnya bernama semester atau semester_tempuh
        'semester_tempuh': masterData['semester'] ?? masterData['semester_tempuh'] ?? selectedSemester,
        'nilai': newGrade,
        'status': newStatus,
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context); // Tutup pop-up
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nilai berhasil diupdate! 🚀"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal update: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  // --- BOTTOM SHEET BUAT PILIH NILAI ---
  void _showGradePicker(BuildContext context, String courseId, Map<String, dynamic> masterData, String currentGrade) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                masterData['nama'] ?? 'Mata Kuliah',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
              ),
              const SizedBox(height: 4),
              Text("Pilih nilai akhir untuk matkul ini", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12, runSpacing: 12,
                children: gradeOptions.map((grade) {
                  bool isSelected = grade == currentGrade;
                  return ChoiceChip(
                    label: Text(
                      grade,
                      style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF2B5CFA),
                    backgroundColor: Colors.grey.shade100,
                    onSelected: (selected) {
                      if (selected) _updateGrade(courseId, masterData, grade);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A': return const Color(0xFF10B981); // Hijau
      case 'B+':
      case 'B': return const Color(0xFF3B82F6); // Biru
      case 'C+':
      case 'C': return const Color(0xFFF59E0B); // Kuning
      case 'D':
      case 'E': return const Color(0xFFEF4444); // Merah
      default: return Colors.grey.shade400;     // Abu-abu
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Daftar Mata Kuliah", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3142),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- FILTER SEMESTER CHIPS ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(8, (index) {
                  int sem = index + 1;
                  bool isSelected = selectedSemester == sem;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => selectedSemester = sem),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2B5CFA) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? const Color(0xFF2B5CFA) : Colors.grey.shade300, width: 1.5),
                          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF2B5CFA).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                        ),
                        child: Text(
                          "Semester $sem",
                          style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey.shade600),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // --- LIST DATA MATKUL ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // 1. NGAMBIL DARI GUDANG UTAMA (MASTER COURSES)
              stream: FirebaseFirestore.instance.collection('courses').snapshots(),
              builder: (context, masterSnapshot) {
                if (masterSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF2B5CFA)));
                }

                if (!masterSnapshot.hasData || masterSnapshot.data!.docs.isEmpty) {
                  return Center(child: Text("Master data matkul belum ada nih.", style: TextStyle(color: Colors.grey.shade500)));
                }

                // 2. FILTER BERDASARKAN SEMESTER
                var semesterCourses = masterSnapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  // Ambil field semester atau semester_tempuh dari master
                  int sem = int.tryParse(data['semester']?.toString() ?? data['semester_tempuh']?.toString() ?? '0') ?? 0;
                  return sem == selectedSemester;
                }).toList();

                if (semesterCourses.isEmpty) {
                  return Center(child: Text("Kosong nih di semester ini ✨", style: TextStyle(color: Colors.grey.shade500)));
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: semesterCourses.length,
                  itemBuilder: (context, index) {
                    var masterCourse = semesterCourses[index];
                    var masterData = masterCourse.data() as Map<String, dynamic>;

                    // 3. CEK KOPER PRIBADI (STUDENT COURSES) BUAT TAU NILAINYA
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('student_courses')
                          .doc(uid)
                          .collection('courses')
                          .doc(masterCourse.id) // Nyocokin ID matkulnya
                          .snapshots(),
                      builder: (context, studentSnapshot) {
                        
                        // Default kalo dokumennya belum ada di koper
                        String grade = 'Belum Diambil'; 

                        // Kalo ketemu di koper, ambil nilainya
                        if (studentSnapshot.hasData && studentSnapshot.data!.exists) {
                          var studentData = studentSnapshot.data!.data() as Map<String, dynamic>;
                          grade = studentData['nilai'] ?? 'Belum Diambil';
                        }

                        Color gradeColor = _getGradeColor(grade);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _showGradePicker(context, masterCourse.id, masterData, grade),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: gradeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                                      child: Icon(Icons.class_rounded, color: gradeColor),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            masterData['nama'] ?? 'Mata Kuliah',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142)),
                                            maxLines: 2, overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(Icons.api_rounded, size: 14, color: Colors.grey.shade500),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${masterData['sks'] ?? 0} SKS",
                                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: gradeColor,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [BoxShadow(color: gradeColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))],
                                      ),
                                      child: Text(
                                        grade == 'Belum Diambil' ? '-' : grade,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}