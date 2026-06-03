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

  List<Map<String, dynamic>> recommendedCourses = [];
  Set<String> selectedCourseIds = {}; // Nyimpen ID matkul yang dicentang user

  @override
  void initState() {
    super.initState();
    _fetchAndCalculateRecommendations();
  }

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

  // --- LOGIKA UTAMA REKOMENDASI ---
  Future<void> _fetchAndCalculateRecommendations() async {
    try {
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

      for (var doc in studentSnapshot.docs) {
        var data = doc.data();
        String grade = data['nilai'] ?? 'Belum Diambil';
        int sks = data['sks'] ?? 0;
        String kode = data['kode'] ?? '';

        if (grade != 'Belum Diambil') {
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

      ipk = totalSksTaken > 0 ? (totalBobot / totalSksTaken) : 0.0;
      if (ipk >= 3.0) maxSks = 24;
      else if (ipk >= 2.5) maxSks = 21;
      else maxSks = 18;

      var masterSnapshot = await FirebaseFirestore.instance.collection('courses').get();
      List<Map<String, dynamic>> tempRecommendations = [];

      for (var doc in masterSnapshot.docs) {
        var data = doc.data();
        String courseId = doc.id;
        
        // Kalo matkul udah pernah diambil dan LULUS, skip
        if (takenCourseIds.contains(courseId) && !failedCourseIds.contains(courseId)) {
          continue;
        }

        bool isMengulang = failedCourseIds.contains(courseId);

        // --- PERBAIKAN LOGIKA PRASYARAT (HANDLE ARRAY) ---
        List<dynamic> prasyaratList = [];
        if (data['prasyarat'] != null) {
          if (data['prasyarat'] is List) {
            prasyaratList = data['prasyarat']; // Kalo bentuknya Array
          } else if (data['prasyarat'] is String) {
            String txtReq = data['prasyarat'].toString().trim();
            if (txtReq.isNotEmpty && txtReq != '-') {
              prasyaratList = [txtReq]; // Kalo bentuknya String, jadiin Array isi 1
            }
          }
        }

        // Kalo bukan matkul ngulang, cek SELURUH prasyaratnya
        if (!isMengulang && prasyaratList.isNotEmpty) {
          bool allPrereqsMet = true;
          for (var req in prasyaratList) {
            if (!passedCourseCodes.contains(req.toString())) {
              allPrereqsMet = false; // Ada satu aja prasyarat yg belum lulus, langsung gagal
              break;
            }
          }
          
          if (!allPrereqsMet) {
            continue; // Skip matkul ini dari rekomendasi
          }
        }
        // ------------------------------------------------

        tempRecommendations.add({
          'id': courseId,
          'kode': data['kode'] ?? '',
          'nama': data['nama'] ?? 'Mata Kuliah',
          'sks': data['sks'] ?? 0,
          'semester': data['semester'] ?? data['semester_tempuh'] ?? 0,
          'isMengulang': isMengulang,
        });
      }

      tempRecommendations.sort((a, b) {
        if (a['isMengulang'] && !b['isMengulang']) return -1;
        if (!a['isMengulang'] && b['isMengulang']) return 1;
        return (a['semester'] as int).compareTo(b['semester'] as int);
      });

      setState(() {
        recommendedCourses = tempRecommendations;
        isLoading = false;
      });

    } catch (e) {
      print("Error fetching recommendations: $e");
      setState(() => isLoading = false);
    }
  }

  // --- FUNGSI TOGGLE CHECKBOX SKS ---
  void _toggleCourseSelection(String courseId, int sks) {
    setState(() {
      if (selectedCourseIds.contains(courseId)) {
        // Batal milih
        selectedCourseIds.remove(courseId);
        usedSks -= sks;
      } else {
        // Mau milih, cek kuota dulu
        if (usedSks + sks > maxSks) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Kuota SKS tidak cukup! Maksimal $maxSks SKS berdasarkan IPK Anda."),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
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
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Rencana Studi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3142),
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2B5CFA)))
          : Column(
              children: [
                // --- HEADER QUOTA SKS ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Kuota SKS", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(usedSks.toString(), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF2B5CFA))),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
                                    child: Text("/ $maxSks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFF2B5CFA).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.shopping_bag_rounded, color: Color(0xFF2B5CFA), size: 32),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: maxSks > 0 ? (usedSks / maxSks) : 0,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            usedSks == maxSks ? const Color(0xFF10B981) : const Color(0xFF2B5CFA),
                          ),
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // --- LIST MATKUL REKOMENDASI ---
                Expanded(
                  child: recommendedCourses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text("Belum ada rekomendasi matkul saat ini.", style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: recommendedCourses.length,
                          itemBuilder: (context, index) {
                            var course = recommendedCourses[index];
                            bool isSelected = selectedCourseIds.contains(course['id']);
                            bool isMengulang = course['isMengulang'];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF2B5CFA).withOpacity(0.05) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF2B5CFA) : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _toggleCourseSelection(course['id'], course['sks']),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Checkbox interaktif
                                        Container(
                                          width: 28, height: 28,
                                          decoration: BoxDecoration(
                                            color: isSelected ? const Color(0xFF2B5CFA) : Colors.transparent,
                                            border: Border.all(color: isSelected ? const Color(0xFF2B5CFA) : Colors.grey.shade400, width: 2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: isSelected ? const Icon(Icons.check_rounded, size: 18, color: Colors.white) : null,
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  if (isMengulang)
                                                    Container(
                                                      margin: const EdgeInsets.only(right: 8),
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                                      child: const Text("NGULANG", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                                    ),
                                                  Expanded(
                                                    child: Text(
                                                      course['nama'],
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3142)),
                                                      maxLines: 2, overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(Icons.api_rounded, size: 14, color: Colors.grey.shade500),
                                                  const SizedBox(width: 4),
                                                  Text("${course['sks']} SKS", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                                  const SizedBox(width: 12),
                                                  Icon(Icons.label_outline_rounded, size: 14, color: Colors.grey.shade500),
                                                  const SizedBox(width: 4),
                                                  Text(course['kode'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}