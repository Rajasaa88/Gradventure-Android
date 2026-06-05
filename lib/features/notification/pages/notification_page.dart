import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Data dummy biar UI-nya kelihatan idup
    final List<Map<String, dynamic>> notifications = [
      {
        "title": "Jadwal Konsul Disetujui ✨",
        "message": "Dosen PA lo udah nge-acc jadwal konsultasi buat besok jam 10:00. Jangan sampe telat ngab!",
        "time": "Barusan",
        "icon": Icons.check_circle_rounded,
        "color": const Color(0xFF10B981), // Ijo
        "isRead": false,
      },
      {
        "title": "KRS Semester Depan Dibuka",
        "message": "Gas susun rencana studi lo! Kuota lo 24 SKS nih semester depan.",
        "time": "2 jam yang lalu",
        "icon": Icons.info_rounded,
        "color": const Color(0xFF2B5CFA), // Biru
        "isRead": false,
      },
      {
        "title": "Warning: Matkul Perlu Diulang 👀",
        "message": "Ada matkul yang dapet nilai D. Cek halaman Rekomendasi buat masukin ke list ngulang.",
        "time": "1 hari yang lalu",
        "icon": Icons.warning_rounded,
        "color": const Color(0xFFF59E0B), // Kuning
        "isRead": true,
      },
      {
        "title": "Update Sistem Gradventure",
        "message": "Fitur AI Chat udah bisa lo pake buat curhat masalah akademik. Cobain sekarang!",
        "time": "3 hari yang lalu",
        "icon": Icons.auto_awesome_rounded,
        "color": const Color(0xFF8B5CF6), // Ungu
        "isRead": true,
      },
    ];

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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Semua notifikasi ditandai udah dibaca. 🧹")),
              );
            },
          )
        ],
      ),
      body: ListView.builder(
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
                  // Aksi pas notifnya diklik
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
      ),
    );
  }
}