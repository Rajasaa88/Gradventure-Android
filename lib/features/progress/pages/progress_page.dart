import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  String _selectedChartFilter = '5 Semester Terakhir';

  void _showProgressInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFF2B5CFA)),
            SizedBox(width: 8),
            Text("Info Progress Kelulusan"),
          ],
        ),
        content: const Text(
          "Progress Kelulusan dihitung berdasarkan jumlah SKS mata kuliah dengan status 'Lulus' dibandingkan dengan target kelulusan Sarjana (S1) sebanyak 144 SKS.\n\nStatus 'On Track' menandakan bahwa Anda berada pada laju pengambilan SKS yang stabil untuk lulus dalam 8 semester.",
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B5CFA))),
          ),
        ],
      ),
    );
  }

  void _showRequirementDetails(
    BuildContext context,
    int totalSks,
    int sksWajib,
    int sksPilihan,
    bool hasKP,
    bool hasSkripsi,
    bool hasSidang,
  ) {
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
                    "Detail Persyaratan Kelulusan",
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
                    _buildDetailRequirementTile(
                      "SKS Total",
                      "Minimal 144 SKS untuk kelulusan program studi Sarjana.",
                      "$totalSks / 144 SKS",
                      totalSks >= 144,
                    ),
                    const Divider(),
                    _buildDetailRequirementTile(
                      "Mata Kuliah Wajib",
                      "Semua mata kuliah wajib kurikulum program studi harus lulus.",
                      "$sksWajib SKS Lulus",
                      sksWajib > 0,
                    ),
                    const Divider(),
                    _buildDetailRequirementTile(
                      "Mata Kuliah Pilihan",
                      "Mengambil mata kuliah peminatan/pilihan pendukung karir.",
                      "$sksPilihan SKS Lulus",
                      sksPilihan > 0,
                    ),
                    const Divider(),
                    _buildDetailRequirementTile(
                      "Kerja Praktik",
                      "Mengambil mata kuliah Kerja Praktik lapangan pada instansi/perusahaan.",
                      hasKP ? "Sudah Terpenuhi" : "Belum Terpenuhi",
                      hasKP,
                    ),
                    const Divider(),
                    _buildDetailRequirementTile(
                      "Skripsi",
                      "Menyusun tugas akhir / skripsi penelitian dan lulus bimbingan.",
                      hasSkripsi ? "Sudah Terpenuhi" : "Belum Terpenuhi",
                      hasSkripsi,
                    ),
                    const Divider(),
                    _buildDetailRequirementTile(
                      "Sidang Tugas Akhir",
                      "Mempertahankan skripsi di depan dewan penguji.",
                      hasSidang ? "Sudah Terpenuhi" : "Belum Terpenuhi",
                      hasSidang,
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

  Widget _buildDetailRequirementTile(String title, String description, String statusText, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isCompleted ? const Color(0xFF10B981) : Colors.grey.shade400,
            size: 22,
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
            statusText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFE11D48),
            ),
          ),
        ],
      ),
    );
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

  // --- WIDGET HELPER BUAT RINGKASAN AKADEMIK ---
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 2),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  // --- WIDGET HELPER BUAT LIST PERSYARATAN ---
  Widget _buildRequirementRow(String title, String value, IconData icon, Color iconColor, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: isCompleted ? iconColor : Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(icon, color: isCompleted ? Colors.white : Colors.grey.shade400, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isCompleted ? const Color(0xFF1E293B) : Colors.grey.shade500)),
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
            onPressed: () {},
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('student_courses').doc(uid).collection('courses').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2B5CFA)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada data akademik."));
          }

          int totalSKS = 0;
          double totalBobot = 0.0;
          int matkulLulus = 0;

          int sksWajib = 0;
          int sksPilihan = 0;
          bool hasKP = false;
          bool hasSkripsi = false;
          bool hasSidang = false;

          Map<int, int> sksPerSemester = {};
          Map<int, double> bobotPerSemester = {};

          // --- LOGIKA KALKULASI IPK & PERSYARATAN ---
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'Belum Diambil';
            String grade = data['nilai'] ?? '-';
            int sks = data['sks'] ?? 0;
            int sem = int.tryParse(data['semester_tempuh']?.toString() ?? data['semester']?.toString() ?? '0') ?? 0;
            String nama = (data['nama'] ?? '').toString().toLowerCase();
            String kategori = data['kategori'] ?? 'Wajib'; // Default wajib kalo field belum ada

            if (status == 'Lulus' && sem > 0) {
              totalSKS += sks;
              matkulLulus++;
              double bobotMatkul = _getGradeWeight(grade) * sks;
              totalBobot += bobotMatkul;

              sksPerSemester[sem] = (sksPerSemester[sem] ?? 0) + sks;
              bobotPerSemester[sem] = (bobotPerSemester[sem] ?? 0.0) + bobotMatkul;

              // Cek Kategori & Matkul Spesial
              if (kategori == 'Pilihan') {
                sksPilihan += sks;
              } else {
                sksWajib += sks;
              }

              if (nama.contains('kerja praktik') || nama.contains('kp')) hasKP = true;
              if (nama.contains('skripsi')) hasSkripsi = true;
              if (nama.contains('sidang')) hasSidang = true;
            }
          }

          double ipk = totalSKS > 0 ? (totalBobot / totalSKS) : 0.0;
          double percentLulus = (totalSKS / 144).clamp(0.0, 1.0);
          int sisaSks = 144 - totalSKS;
          if (sisaSks < 0) sisaSks = 0;

          // Siapin data Line Chart
          List<FlSpot> chartSpots = [];
          List<int> sortedSemesters = sksPerSemester.keys.toList()..sort();
          
          List<int> semestersToDisplay = sortedSemesters;
          if (_selectedChartFilter == '5 Semester Terakhir' && sortedSemesters.length > 5) {
            semestersToDisplay = sortedSemesters.sublist(sortedSemesters.length - 5);
          }

          for (int sem in semestersToDisplay) {
            double ips = bobotPerSemester[sem]! / sksPerSemester[sem]!;
            chartSpots.add(FlSpot(sem.toDouble(), ips));
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HERO CARD (BIRU TUA) ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => _showProgressInfoDialog(context),
                            child: const Row(
                              children: [
                                Text("Progress Kelulusan", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                                SizedBox(width: 4),
                                Icon(Icons.help_outline_rounded, color: Colors.white70, size: 14),
                              ],
                            ),
                          ),
                          Icon(Icons.school_rounded, color: Colors.white.withOpacity(0.8), size: 40),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("$totalSKS / 144 SKS", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text("${(percentLulus * 100).toStringAsFixed(1)}%", style: const TextStyle(color: Color(0xFF34D399), fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percentLulus,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Estimasi Lulus", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              const Text("Semester 8", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Status", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFF34D399).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 14),
                                    SizedBox(width: 4),
                                    Text("On Track", style: TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // --- RINGKASAN AKADEMIK ---
                const Text("Ringkasan Akademik", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.65,
                  children: [
                    _buildSummaryCard("IPK Saat Ini", ipk.toStringAsFixed(2), Icons.school_rounded, const Color(0xFF8B5CF6)),
                    _buildSummaryCard("SKS Lulus", "$totalSKS", Icons.check_circle_rounded, const Color(0xFF10B981)),
                    _buildSummaryCard("Mata Kuliah", "$matkulLulus", Icons.menu_book_rounded, const Color(0xFF2B5CFA)),
                    _buildSummaryCard("Sisa SKS", "$sisaSks", Icons.access_time_filled_rounded, const Color(0xFFF59E0B)),
                  ],
                ),
                const SizedBox(height: 32),

                // --- PERSYARATAN KELULUSAN ---
                const Text("Persyaratan Kelulusan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    children: [
                      _buildRequirementRow("SKS Total", "$totalSKS / 144 SKS", Icons.check_rounded, const Color(0xFF10B981), totalSKS >= 144),
                      const Divider(height: 20),
                      _buildRequirementRow("Mata Kuliah Wajib", "$sksWajib SKS", Icons.check_rounded, const Color(0xFF10B981), sksWajib > 0),
                      const Divider(height: 20),
                      _buildRequirementRow("Mata Kuliah Pilihan", "$sksPilihan SKS", Icons.access_time_rounded, const Color(0xFFF59E0B), sksPilihan > 0),
                      const Divider(height: 20),
                      _buildRequirementRow("Kerja Praktik", hasKP ? "Selesai" : "Belum ditempuh", hasKP ? Icons.check_rounded : Icons.access_time_rounded, const Color(0xFFF59E0B), hasKP),
                      const Divider(height: 20),
                      _buildRequirementRow("Skripsi", hasSkripsi ? "Selesai" : "Belum ditempuh", hasSkripsi ? Icons.check_rounded : Icons.close_rounded, const Color(0xFFEF4444), hasSkripsi),
                      const Divider(height: 20),
                      _buildRequirementRow("Sidang", hasSidang ? "Selesai" : "Belum ditempuh", hasSidang ? Icons.check_rounded : Icons.close_rounded, const Color(0xFFEF4444), hasSidang),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () {
                          _showRequirementDetails(context, totalSKS, sksWajib, sksPilihan, hasKP, hasSkripsi, hasSidang);
                        },
                        child: Row(
                          children: [
                            Text("Lihat Detail", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF2B5CFA).withOpacity(0.8))),
                            const Spacer(),
                            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // --- ANALISIS GRADVENTURE ---
                const Text("Analisis Gradventure", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: Color(0xFF10B981), size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Kamu berada pada jalur yang sesuai untuk lulus di Semester 8.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF047857), height: 1.4)),
                            const SizedBox(height: 8),
                            Text("Pertahankan rata-rata 18 SKS per semester dan IPK-mu!", style: TextStyle(fontSize: 12, color: const Color(0xFF047857).withOpacity(0.8), height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // --- TREN IPK ---
                if (chartSpots.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Tren IPK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                      PopupMenuButton<String>(
                        onSelected: (String value) {
                          setState(() {
                            _selectedChartFilter = value;
                          });
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem(
                            value: '5 Semester Terakhir',
                            child: Text('5 Semester Terakhir'),
                          ),
                          const PopupMenuItem(
                            value: 'Semua Semester',
                            child: Text('Semua Semester'),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Text(_selectedChartFilter, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.only(right: 20, left: 10, top: 24, bottom: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                    child: LineChart(
                      LineChartData(
                        minY: 0, maxY: 4.0,
                        gridData: FlGridData(
                          show: true, drawVerticalLine: false, horizontalInterval: 1,
                          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
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
                                child: Text('Sem ${value.toInt()}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true, interval: 1, reservedSize: 32,
                              getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(2), style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: chartSpots,
                            isCurved: false, // Dibikin kaku garisnya biar persis mockup
                            color: const Color(0xFF2B5CFA),
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: const Color(0xFF2B5CFA), strokeWidth: 2, strokeColor: Colors.white),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF2B5CFA).withOpacity(0.05),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}