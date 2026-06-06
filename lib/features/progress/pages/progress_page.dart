import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart'; // Wajib import ini buat grafik

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

  // --- WIDGET KARTU STATISTIK (IPK & SKS) ---
  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Progress Studi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3142),
        elevation: 0,
        centerTitle: true,
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
            return const Center(child: Text("Belum ada matkul yang diambil nih."));
          }

          int totalSKS = 0;
          double totalBobot = 0.0;
          
          // Buat kalkulasi IPS per semester
          Map<int, int> sksPerSemester = {};
          Map<int, double> bobotPerSemester = {};
          List<Map<String, dynamic>> warningCourses = [];

          // --- LOGIKA KALKULASI IPK, IPS & SKS ---
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            String grade = data['nilai'] ?? 'Belum Diambil';
            int sks = data['sks'] ?? 0;
            int sem = int.tryParse(data['semester_tempuh']?.toString() ?? data['semester']?.toString() ?? '0') ?? 0;

            if (grade != 'Belum Diambil' && sem > 0) {
              totalSKS += sks;
              double bobotMatkul = _getGradeWeight(grade) * sks;
              totalBobot += bobotMatkul;

              // Kumpulin data per semester
              sksPerSemester[sem] = (sksPerSemester[sem] ?? 0) + sks;
              bobotPerSemester[sem] = (bobotPerSemester[sem] ?? 0.0) + bobotMatkul;

              // Masukin ke daftar warning kalo nilainya C, D, atau E
              if (grade == 'C' || grade == 'D' || grade == 'E') {
                warningCourses.add(data);
              }
            }
          }

          double ipk = totalSKS > 0 ? (totalBobot / totalSKS) : 0.0;

          // Siapin data buat Line Chart (FlSpot = Titik X dan Y di grafik)
          List<FlSpot> chartSpots = [];
          List<int> sortedSemesters = sksPerSemester.keys.toList()..sort();
          
          for (int sem in sortedSemesters) {
            double ips = bobotPerSemester[sem]! / sksPerSemester[sem]!;
            chartSpots.add(FlSpot(sem.toDouble(), ips));
          }

          // --- LOGIKA REWARD & PREDIKSI SKS ---
          String jatahSks = ipk >= 3.0 ? "24 SKS" : (ipk >= 2.5 ? "21 SKS" : "18 SKS");
          String pesanSks = ipk >= 3.0 
              ? "🔥 Gacor! IPK aman buat gas full SKS semester depan." 
              : "Tetep semangat Di! Atur strategi ambil matkul biar IPK naik.";
          Color statusColor = ipk >= 3.0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HIGHLIGHT CARDS ---
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard("IPK Saat Ini", ipk.toStringAsFixed(2), Icons.school_rounded, const Color(0xFF2B5CFA), "Skala 4.00"),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard("SKS Lulus", totalSKS.toString(), Icons.check_circle_rounded, const Color(0xFF10B981), "Dari total 144 SKS"),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- CARD PREDIKSI SKS ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor.withValues(alpha: 0.8), statusColor],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Hak SKS Semester Depan", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        Icon(Icons.auto_awesome_rounded, color: Colors.white.withValues(alpha: 0.8), size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(jatahSks, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(pesanSks, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.4)),
                  ],
                  ),
                  ),
                const SizedBox(height: 32),

                // --- GRAFIK TREN IPS ---
                if (chartSpots.isNotEmpty) ...[
                  const Text("Tren Indeks Prestasi Semester", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
                  const SizedBox(height: 16),
                  Container(
                    height: 250,
                    padding: const EdgeInsets.only(right: 20, left: 10, top: 24, bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade100, width: 2),
                    ),
                    child: LineChart(
                      LineChartData(
                        minY: 0, maxY: 4.0,
                        gridData: FlGridData(
                          show: true, 
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) => Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text('Sem ${value.toInt()}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(1), style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
                              reservedSize: 32,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: chartSpots,
                            isCurved: true, // Bikin garisnya smooth
                            color: const Color(0xFF2B5CFA),
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF2B5CFA).withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // --- WARNING SECTION (MATKUL PERLU PERHATIAN) ---
                const Text("Perlu Perhatian 👀", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
                const SizedBox(height: 16),
                if (warningCourses.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.celebration_rounded, color: Color(0xFF10B981)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text("Gacor! Nggak ada matkul yang dapet nilai C ke bawah.", style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: warningCourses.length,
                    itemBuilder: (context, index) {
                      var course = warningCourses[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: Text(course['nilai'], style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(course['nama'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                                  const SizedBox(height: 4),
                                  Text("Mungkin perlu diulang buat perbaikan IPK.", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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