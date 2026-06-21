import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/notification_service.dart';

class ConsultationPage extends StatefulWidget {
  const ConsultationPage({super.key});

  @override
  State<ConsultationPage> createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<ConsultationPage> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _topikController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _remind15MinsBefore = true;
  bool _isSubmitting = false;

  String? _topikError;
  String? _dateError;
  String? _timeError;

  Future<void> _pickDate(StateSetter setModalState) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF2B5CFA))),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateError = null;
      });
      setModalState(() {});
    }
  }

  Future<void> _pickTime(StateSetter setModalState) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2B5CFA)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeError = null;
      });
      setModalState(() {});
    }
  }

  Future<void> _saveNote(StateSetter setModalState) async {
    setModalState(() {
      _topikError = _topikController.text.trim().isEmpty ? "Agenda wajib diisi!" : null;
      _dateError = _selectedDate == null ? "Tanggal wajib dipilih!" : null;
      _timeError = _selectedTime == null ? "Waktu wajib dipilih!" : null;
    });

    if (_topikError != null || _dateError != null || _timeError != null) {
      return;
    }

    setState(() => _isSubmitting = true);
    setModalState(() {});

    try {
      final DateTime scheduledDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      String dateStr = "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}";
      String timeStr = "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}";

      // Save to Firestore
      DocumentReference docRef = await _firestore.collection('users').doc(uid).collection('pa_notes').add({
        'topik': _topikController.text.trim(),
        'catatan': _catatanController.text.trim(),
        'tanggal': dateStr,
        'waktu': timeStr,
        'timestamp': FieldValue.serverTimestamp(),
        'dateTime': scheduledDateTime.toIso8601String(),
        'reminderEnabled': true, // Always enable notification
        'remind15MinsBefore': _remind15MinsBefore,
        'calendarAdded': false,
      });

      if (!mounted) return;

      // 1. Integrasi Notifikasi Lokal
      await NotificationService().requestPermissions();
      
      // Notifikasi 1: Tepat waktu bimbingan
      if (scheduledDateTime.isAfter(DateTime.now())) {
        final int notificationIdExact = docRef.id.hashCode;
        await NotificationService().scheduleNotification(
          id: notificationIdExact,
          title: "Bimbingan PA Dimulai! ⏰",
          body: "Agenda: ${_topikController.text.trim()}\nJam: $timeStr WIB",
          scheduledDate: scheduledDateTime,
        );
      }

      // Notifikasi 2: 15 menit sebelum bimbingan (jika diaktifkan)
      if (_remind15MinsBefore) {
        DateTime reminderTime = scheduledDateTime.subtract(const Duration(minutes: 15));
        if (reminderTime.isAfter(DateTime.now())) {
          final int notificationIdReminder = docRef.id.hashCode + 1;
          await NotificationService().scheduleNotification(
            id: notificationIdReminder,
            title: "Pengingat Bimbingan PA (15 Menit Lagi) ⏰",
            body: "Agenda: ${_topikController.text.trim()}\nJam: $timeStr WIB",
            scheduledDate: reminderTime,
          );
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jadwal bimbingan berhasil disimpan! 🔔"), backgroundColor: Colors.green));
      _topikController.clear();
      _catatanController.clear();
      setState(() {
        _selectedDate = null;
        _selectedTime = null;
        _topikError = null;
        _dateError = null;
        _timeError = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e"), backgroundColor: Colors.redAccent));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteSchedule(String docId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Jadwal", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Apakah Anda yakin ingin menghapus jadwal bimbingan ini? Alarm yang dijadwalkan juga akan dibatalkan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text("Hapus", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final int notificationIdExact = docId.hashCode;
        final int notificationIdReminder = docId.hashCode + 1;
        await NotificationService().cancelNotification(notificationIdExact);
        await NotificationService().cancelNotification(notificationIdReminder);

        await _firestore.collection('users').doc(uid).collection('pa_notes').doc(docId).delete();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Jadwal bimbingan berhasil dihapus 🗑️"),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menghapus jadwal: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showAddNoteForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Buat Jadwal Bimbingan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                const SizedBox(height: 20),
                TextField(
                  controller: _topikController,
                  onChanged: (val) {
                    if (_topikError != null) {
                      setModalState(() {
                        _topikError = null;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: "Agenda / Topik Bimbingan",
                    errorText: _topikError,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () async { await _pickDate(setModalState); },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                border: Border.all(
                                  color: _dateError != null ? Colors.redAccent : const Color(0xFFE2E8F0),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF2B5CFA)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedDate == null 
                                          ? "Pilih Tanggal" 
                                          : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedDate == null ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_dateError != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8, top: 4),
                              child: Text(_dateError!, style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w500)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () async { await _pickTime(setModalState); },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                border: Border.all(
                                  color: _timeError != null ? Colors.redAccent : const Color(0xFFE2E8F0),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF2B5CFA)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedTime == null 
                                          ? "Pilih Waktu" 
                                          : "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedTime == null ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_timeError != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8, top: 4),
                              child: Text(_timeError!, style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w500)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: _catatanController, maxLines: 3, decoration: InputDecoration(labelText: "Catatan / Detail Kegiatan (Opsional)", alignLabelWithHint: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Ingatkan 15 Menit Sebelum", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                  subtitle: const Text("Kirimkan notifikasi tambahan 15 menit sebelum bimbingan", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  value: _remind15MinsBefore,
                  activeColor: const Color(0xFF2B5CFA),
                  onChanged: (bool value) {
                    setModalState(() {
                      _remind15MinsBefore = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _saveNote(setModalState),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B5CFA), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _isSubmitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("Simpan Jadwal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      });
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Jadwal Konsultasi Dosen", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3142),
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoteForm,
        backgroundColor: const Color(0xFF2B5CFA),
        icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
        label: const Text("Catat Jadwal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').doc(uid).collection('pa_notes').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF2B5CFA)));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("Belum ada jadwal konsultasi.", style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 80),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              bool hasNotification = data['reminderEnabled'] == true;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['topik'] ?? 'Topik Bimbingan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))),
                                if (hasNotification) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.notifications_active_rounded, size: 14, color: Color(0xFF2B5CFA)),
                                          SizedBox(width: 2),
                                          Text("Notifikasi Aktif", style: TextStyle(fontSize: 11, color: Color(0xFF2B5CFA), fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ],
                                  )
                                ]
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFF4F6F9), borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  "${data['tanggal'] ?? '-'}${data['waktu'] != null ? ' @ ${data['waktu']}' : ''}",
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                                onPressed: () => _deleteSchedule(snapshot.data!.docs[index].id),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                tooltip: "Hapus Jadwal",
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Text(
                        data['catatan']?.toString().isNotEmpty == true ? data['catatan'] : "Tidak ada detail jadwal.",
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
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