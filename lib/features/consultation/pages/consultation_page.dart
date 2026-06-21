import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/notification_service.dart';
import '../controllers/ai_chat_controller.dart';
import '../models/chat_session.dart';

class ConsultationPage extends StatefulWidget {
  const ConsultationPage({super.key});

  @override
  State<ConsultationPage> createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<ConsultationPage> with SingleTickerProviderStateMixin {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers for Note Scheduling
  final TextEditingController _topikController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _remind15MinsBefore = true;
  bool _isSubmitting = false;

  String? _topikError;
  String? _dateError;
  String? _timeError;

  // Tab controller
  late final TabController _tabController;

  // AI Chat States
  final TextEditingController _aiTextController = TextEditingController();
  final ScrollController _aiScrollController = ScrollController();
  late final AiChatController _aiChatController;

  final List<String> _suggestions = [
    "Mending ambil matkul apaan ya buat perbaikan IPK?",
    "Cara ngajuin judul skripsi ke dosen PA gimana?",
    "Syarat minimal SKS buat lulus Universitas Mataram berapa?",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _aiChatController = AiChatController();
    _aiChatController.addListener(_onAiControllerChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _aiChatController.removeListener(_onAiControllerChanged);
    _aiChatController.dispose();
    _aiScrollController.dispose();
    _aiTextController.dispose();
    _topikController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  void _onAiControllerChanged() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_aiScrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _aiScrollController.animateTo(
          _aiScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  List<InlineSpan> _parseMarkdown(String text, bool isUser) {
    final List<InlineSpan> spans = [];
    final color = isUser ? Colors.white : const Color(0xFF2D3142);
    final RegExp regExp = RegExp(
      r'(\*\*(.*?)\*\*)|(\*(.*?)\*)|(_(.*?)_)|(`(.*?)`)',
      dotAll: true,
    );
    int start = 0;
    for (final Match match in regExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: TextStyle(color: color, height: 1.4, fontSize: 14),
        ));
      }
      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            height: 1.4,
            fontSize: 14,
          ),
        ));
      } else if (match.group(3) != null) {
        spans.add(TextSpan(
          text: match.group(4),
          style: TextStyle(
            color: color,
            fontStyle: FontStyle.italic,
            height: 1.4,
            fontSize: 14,
          ),
        ));
      } else if (match.group(5) != null) {
        spans.add(TextSpan(
          text: match.group(6),
          style: TextStyle(
            color: color,
            decoration: TextDecoration.underline,
            height: 1.4,
            fontSize: 14,
          ),
        ));
      } else if (match.group(7) != null) {
        spans.add(TextSpan(
          text: match.group(8),
          style: TextStyle(
            color: isUser ? Colors.white : Colors.pinkAccent,
            fontFamily: 'monospace',
            backgroundColor: isUser ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
            height: 1.4,
            fontSize: 13,
          ),
        ));
      }
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: TextStyle(color: color, height: 1.4, fontSize: 14),
      ));
    }
    return spans;
  }

  Future<void> _handleSendMessage() async {
    final text = _aiTextController.text.trim();
    if (text.isEmpty) return;

    _aiTextController.clear();
    await _aiChatController.sendMessage(text);
  }

  Future<bool?> _showDeleteConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Riwayat?"),
        content: const Text("Apakah kamu yakin ingin menghapus percakapan ini secara permanen?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- METHODS FOR NOTES SCHEDULING (PRESERVED FROM MAIN) ---
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

  // --- TAB 1: REAL CHAT AI ---
  Widget _buildAITab() {
    return Column(
      children: [
        Expanded(
          child: _aiChatController.messages.isEmpty
              ? _buildWelcomeScreen()
              : _buildChatList(),
        ),

        // Visual Loading / Typing Indicator
        if (_aiChatController.isLoading) _buildTypingIndicator(),

        // Input Area
        _buildInputArea(),
      ],
    );
  }

  // Welcome Screen inside Tab
  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2B5CFA).withOpacity(0.08),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: const Icon(Icons.smart_toy_rounded, size: 48, color: Color(0xFF2B5CFA)),
          ),
          const SizedBox(height: 16),
          const Text(
            "Halo! Mau tanya apa hari ini? 👋",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Tanya apa saja seputar akademik, KRS, strategi SKS, dosen PA, atau kehidupan kampus Universitas Mataram.",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFF2B5CFA)),
                const SizedBox(width: 8),
                Text(
                  "Pertanyaan Rekomendasi",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Render Suggestions Cards
          ..._suggestions.map((suggestion) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  _aiTextController.text = suggestion;
                  _handleSendMessage();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          suggestion,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2D3142),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF2B5CFA)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Messages Chat List inside Tab
  Widget _buildChatList() {
    return ListView.builder(
      controller: _aiScrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
      itemCount: _aiChatController.messages.length,
      itemBuilder: (context, index) {
        final message = _aiChatController.messages[index];
        final isUser = message.role == 'user';

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(
              bottom: 16,
              left: isUser ? 60 : 0,
              right: isUser ? 0 : 60,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF2B5CFA) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                      ),
                      border: isUser ? null : Border.all(color: Colors.grey.shade200),
                      boxShadow: isUser
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                    ),
                    child: RichText(
                      textAlign: TextAlign.justify,
                      text: TextSpan(
                        children: _parseMarkdown(message.text, isUser),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Typing/Loading Indicator Widget inside Tab
  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 20, right: 80),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "AI sedang berpikir",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  _AnimatedDots(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Message Input Bar inside Tab
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _aiTextController,
              decoration: InputDecoration(
                hintText: "Ketik pesan ke AI...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF4F6F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: (_) => _handleSendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: const Color(0xFF2B5CFA),
            radius: 24,
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _handleSendMessage,
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: CATATAN & JADWAL PA ---
  Widget _buildNotesTab() {
    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .doc(uid)
              .collection('pa_notes')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF2B5CFA)));
            }

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
                                    const Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Row(
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
        // Tombol nambah catatan ngambang di bawah
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.extended(
            onPressed: _showAddNoteForm,
            backgroundColor: const Color(0xFF2B5CFA),
            icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
            label: const Text("Catat Jadwal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      endDrawer: _tabController.index == 0 ? Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 24, left: 24, right: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2B5CFA), Color(0xFF4C7BFE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Gradventure AI",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Asisten Akademik Pintarmu 🎓",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            
            // New Chat Button inside Drawer
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  _aiChatController.startNewChat();
                  Navigator.pop(context); // Close drawer
                },
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text("Mulai Percakapan Baru", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B5CFA),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(),
            ),

            // History Label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Text(
                    "Riwayat Percakapan",
                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),

            // History List
            Expanded(
              child: StreamBuilder<List<AiChatSession>>(
                stream: _aiChatController.getSessionsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF2B5CFA)));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        "Belum ada riwayat chat",
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      ),
                    );
                  }

                  final sessions = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final isSelected = session.id == _aiChatController.currentSessionId;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2B5CFA).withOpacity(0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          leading: Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: isSelected ? const Color(0xFF2B5CFA) : Colors.grey.shade600,
                            size: 18,
                          ),
                          title: Text(
                            session.judulSesi,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF2B5CFA) : const Color(0xFF2D3142),
                              fontSize: 13,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent.withOpacity(0.7)),
                            onPressed: () async {
                              final confirm = await _showDeleteConfirmDialog(context);
                              if (confirm == true) {
                                await _aiChatController.deleteSession(session.id);
                              }
                            },
                          ),
                          onTap: () async {
                            Navigator.pop(context); // close drawer
                            await _aiChatController.loadSession(session.id);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ) : null,
      appBar: AppBar(
        title: const Text("Pusat Konsultasi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3142),
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_tabController.index == 0)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF2B5CFA)),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                tooltip: 'Riwayat Chat',
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2B5CFA),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2B5CFA),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Tanya AI"),
            Tab(text: "Catatan DPA"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAITab(),
          _buildNotesTab(),
        ],
      ),
    );
  }
}

class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double animVal = _controller.value;
            double opacity = 0.2;
            if (index == 0 && animVal < 0.33) opacity = 1.0;
            if (index == 1 && animVal >= 0.33 && animVal < 0.66) opacity = 1.0;
            if (index == 2 && animVal >= 0.66) opacity = 1.0;
            return Opacity(
              opacity: opacity,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFF2B5CFA),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}