import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecommendationPage extends StatefulWidget {
  const RecommendationPage({super.key});

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  bool isLoading = true;
  double ipk = 0.0;
  int maxSks = 0;
  int usedSks = 0;
  int currentStudentSemester = 1;

  List<Map<String, dynamic>> recommendedCourses = [];
  Set<String> selectedCourseIds = {};

  @override
  void initState() {
    super.initState();
    _fetchAndCalculateRecommendations();
  }

  // Fungsi pembantu untuk konversi tipe data yang aman (handle null, String, int, double)
  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

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

  Future<void> _fetchAndCalculateRecommendations() async {
    try {
      // 1. Ambil Progres Akademik
      var studentSnapshot = await FirebaseFirestore.instance
          .collection('student_courses')
          .doc(uid)
          .collection('courses')
          .get();

      int totalSksTaken = 0;
      double totalBobot = 0.0;
      Set<String> passedCourseCodes = {};
      Set<String> failedCourseIds = {};
      Set<String> takenCourseIds = {};
      int maxSemesterCompleted = 0;

      for (var doc in studentSnapshot.docs) {
        var data = doc.data();
        String grade = data['nilai'] ?? 'Belum Diambil';
        int sks = _safeInt(data['sks']);
        String kode = data['kode'] ?? '';
        int sem = _safeInt(data['semester_tempuh']);

        if (grade != 'Belum Diambil') {
          if (sem > maxSemesterCompleted) maxSemesterCompleted = sem;
          totalSksTaken += sks;
          totalBobot += (_getGradeWeight(grade) * sks);
          takenCourseIds.add(doc.id);

          if (grade == 'D' || grade == 'E') {
            failedCourseIds.add(doc.id);
          } else {
            passedCourseCodes.add(kode);
          }
        }
      }

      // Semester aktif yang akan ditempuh (misal lulus smt 2, maka sekarang menyusun smt 3)
      currentStudentSemester = maxSemesterCompleted + 1;

      // 2. Kalkulasi Beban SKS
      ipk = totalSksTaken > 0 ? (totalBobot / totalSksTaken) : 0.0;
      if (ipk >= 3.0) maxSks = 24;
      else if (ipk >= 2.5) maxSks = 21;
      else if (ipk >= 2.0) maxSks = 18;
      else maxSks = 15;

      // 3. Ambil Master Kurikulum
      var masterSnapshot = await FirebaseFirestore.instance.collection('courses').get();
      List<Map<String, dynamic>> tempRecommendations = [];

      for (var doc in masterSnapshot.docs) {
        var data = doc.data();
        String courseId = doc.id;

        int courseSemester = _safeInt(data['semester']);
        int courseSks = _safeInt(data['sks']);

        // A. Skip jika sudah lulus (kecuali mengulang)
        if (takenCourseIds.contains(courseId) && !failedCourseIds.contains(courseId)) continue;

        // B. FILTER: Aturan Ganjil-Ganjil / Genap-Genap
        // Pastikan paritas semester mata kuliah cocok dengan semester mahasiswa saat ini
        if (courseSemester != 0 && (courseSemester % 2 != currentStudentSemester % 2)) {
          continue;
        }

        // C. FILTER: Batasan Semester 1 & 2 (Belum boleh ambil mata kuliah semester atas)
        if (currentStudentSemester < 3 && courseSemester > currentStudentSemester) {
          continue;
        }

        bool isMengulang = failedCourseIds.contains(courseId);

        // D. Cek Prasyarat
        List<dynamic> prasyaratList = data['prasyarat'] is List ? data['prasyarat'] : [];
        bool allPrereqsMet = true;
        for (var req in prasyaratList) {
          if (!passedCourseCodes.contains(req.toString())) {
            allPrereqsMet = false;
            break;
          }
        }

        if (!allPrereqsMet && !isMengulang) continue;

        int priority = 0;
        String reason = "";

        if (isMengulang) {
          priority = 3;
          reason = "Wajib mengulang (Faktor: Perbaikan Nilai)";
        } else if (courseSemester == currentStudentSemester) {
          priority = 2;
          reason = "Mata kuliah paket semester ini";
        } else if (courseSemester < currentStudentSemester) {
          priority = 1;
          reason = "Mata kuliah tertinggal (Prioritas Kelulusan)";
        } else {
          priority = 0;
          reason = "Akselerasi Semester Atas (Faktor Kapasitas)";
        }

        tempRecommendations.add({
          'id': courseId,
          'kode': data['kode'] ?? '',
          'nama': data['nama'] ?? 'Mata Kuliah',
          'sks': courseSks,
          'semester': courseSemester,
          'isMengulang': isMengulang,
          'priority': priority,
          'reason': reason,
        });
      }

      tempRecommendations.sort((a, b) {
        int res = (b['priority'] as int).compareTo(a['priority'] as int);
        return res != 0 ? res : (a['semester'] as int).compareTo(b['semester'] as int);
      });

      setState(() {
        recommendedCourses = tempRecommendations;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _toggleCourseSelection(String courseId, int sks) {
    setState(() {
      if (selectedCourseIds.contains(courseId)) {
        selectedCourseIds.remove(courseId);
        usedSks -= sks;
      } else {
        if (usedSks + sks > maxSks) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Batas SKS tercapai!")));
        } else {
          selectedCourseIds.add(courseId);
          usedSks += sks;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Rekomendasi Matkul", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildAcademicSummary()),
          recommendedCourses.isEmpty
              ? const SliverFillRemaining(child: Center(child: Text("Tidak ada rekomendasi.")))
              : SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildCourseCard(recommendedCourses[index]),
                childCount: recommendedCourses.length,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActionBottomBar(),
    );
  }

  Widget _buildAcademicSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem("IPK", ipk.toStringAsFixed(2), Colors.blue),
              _summaryItem("Batas SKS", "$maxSks", Colors.orange),
              _summaryItem("Semester", "$currentStudentSemester", Colors.green),
            ],
          ),
          const SizedBox(height: 20),
          _buildSksProgress(),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildSksProgress() {
    double progress = maxSks > 0 ? (usedSks / maxSks) : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Beban Studi Dipilih", style: TextStyle(fontWeight: FontWeight.w600)),
            Text("$usedSks / $maxSks SKS", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(usedSks > maxSks ? Colors.red : Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    bool isSelected = selectedCourseIds.contains(course['id']);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade200, width: 2),
      ),
      child: InkWell(
        onTap: () => _toggleCourseSelection(course['id'], course['sks']),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildPriorityIndicator(course['priority']),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course['nama'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text("${course['kode']} • Smtr ${course['semester']} • ${course['sks']} SKS",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.blue.shade300),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(course['reason'],
                              style: TextStyle(color: Colors.blue.shade700, fontSize: 11, fontStyle: FontStyle.italic)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(isSelected ? Icons.check_circle : Icons.add_circle_outline,
                  color: isSelected ? Colors.blue : Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(int priority) {
    Color color;
    String label;
    if (priority == 3) { color = Colors.red; label = "Wajib"; }
    else if (priority == 2) { color = Colors.blue; label = "Utama"; }
    else { color = Colors.grey; label = "Pilihan"; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
      child: ElevatedButton(
        onPressed: selectedCourseIds.isEmpty ? null : () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text("Simpan Rencana Studi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
