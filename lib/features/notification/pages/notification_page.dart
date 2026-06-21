import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _allRead = false;

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    if (uid.isEmpty) return [];

    final List<Map<String, dynamic>> list = [];

    try {
      // 1. Fetch Scheduled DPA Consultations
      final notesSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('pa_notes')
          .orderBy('timestamp', descending: true)
          .get();

      for (var doc in notesSnap.docs) {
        final data = doc.data();
        final String topik = data['topik'] ?? 'Konsultasi';
        final String tanggal = data['tanggal'] ?? '';
        final String waktu = data['waktu'] ?? '';
        final timestamp = data['timestamp'];

        DateTime creationTime = DateTime.now();
        if (timestamp is Timestamp) {
          creationTime = timestamp.toDate();
        }

        list.add({
          "title": "Bimbingan PA Dijadwalkan 📅",
          "message": "Topik: $topik. Pelaksanaan pada tanggal $tanggal pukul $waktu WIB. Jangan telat ya!",
          "time": _formatTimeAgo(creationTime),
          "icon": Icons.calendar_month_rounded,
          "color": const Color(0xFF2B5CFA), // Biru
          "isRead": _allRead,
          "timestamp": creationTime,
        });
      }

      // 2. Fetch Low Grades Warnings
      final coursesSnap = await FirebaseFirestore.instance
          .collection('student_courses')
          .doc(uid)
          .collection('courses')
          .get();

      for (var doc in coursesSnap.docs) {
        final data = doc.data();
        final String status = data['status'] ?? '';
        final String grade = data['nilai'] ?? '';
        final String namaMatkul = data['nama'] ?? 'Mata Kuliah';

        // Check if grade is low (C, D, or E)
        if (status == 'Lulus' && (grade == 'C' || grade == 'D' || grade == 'E')) {
          list.add({
            "title": "Warning: Nilai Perlu Perbaikan ⚠️",
            "message": "Kamu dapet nilai $grade di mata kuliah $namaMatkul. Disarankan ambil ulang pas perbaikan IPK.",
            "time": "Peringatan Akademik",
            "icon": Icons.warning_rounded,
            "color": const Color(0xFFEF4444), // Merah untuk warning
            "isRead": _allRead,
            "timestamp": DateTime.now().subtract(const Duration(hours: 1)),
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading dynamic notifications: $e");
    }

    // 3. Fallback/Mock notifications to keep it rich
    list.add({
      "title": "KRS Semester Depan Dibuka 📝",
      "message": "Gas susun rencana studi lo! Kuota lo 24 SKS nih semester depan.",
      "time": "2 jam yang lalu",
      "icon": Icons.info_rounded,
      "color": const Color(0xFF10B981), // Ijo
      "isRead": _allRead,
      "timestamp": DateTime.now().subtract(const Duration(hours: 2)),
    });

    list.add({
      "title": "Update Sistem Gradventure 🚀",
      "message": "Fitur AI Chat udah bisa lo pake buat curhat masalah akademik. Cobain sekarang!",
      "time": "3 hari yang lalu",
      "icon": Icons.auto_awesome_rounded,
      "color": const Color(0xFF8B5CF6), // Ungu
      "isRead": true,
      "timestamp": DateTime.now().subtract(const Duration(days: 3)),
    });

    // Sort by timestamp
    list.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

    return list;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) {
      return "Barusan";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes} menit yang lalu";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} jam yang lalu";
    } else {
      return "${diff.inDays} hari yang lalu";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Notifikasi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3142),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Color(0xFF2B5CFA)),
            tooltip: 'Tandai semua dibaca',
            onPressed: () {
              setState(() {
                _allRead = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Semua notifikasi ditandai udah dibaca. 🧹")),
              );
            },
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2B5CFA)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("Tidak ada notifikasi baru.", style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notif = notifications[index];
              bool isRead = notif['isRead'];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isRead ? Colors.white : const Color(0xFF2B5CFA).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isRead ? Colors.grey.shade100 : const Color(0xFF2B5CFA).withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      // Handled tapping
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: notif['color'].withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(notif['icon'], color: notif['color'], size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notif['title'],
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF2D3142)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                      )
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notif['message'],
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  notif['time'],
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
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
          );
        },
      ),
    );
  }
}