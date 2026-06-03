import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConsultationPage extends StatefulWidget {
  const ConsultationPage({super.key});

  @override
  State<ConsultationPage> createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<ConsultationPage> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controller buat form Catatan PA
  final TextEditingController _topikController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  DateTime? _selectedDate;

  bool _isSubmitting = false;

  // --- FUNGSI PILIH TANGGAL KONSUL ---
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      setState(() => _selectedDate = picked);
    }
  }

  // --- FUNGSI SIMPAN CATATAN KE FIRESTORE ---
  Future<void> _saveNote() async {
    if (_topikController.text.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Topik dan Tanggal wajib diisi!"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String dateStr = "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}";

      // Simpen ke sub-collection khusus catatan pribadi
      await _firestore.collection('users').doc(uid).collection('pa_notes').add({
        'topik': _topikController.text.trim(),
        'catatan': _catatanController.text.trim(),
        'tanggal': dateStr,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context); // Tutup bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Catatan berhasil disimpan! 📝"), backgroundColor: Colors.green),
      );

      _topikController.clear();
      _catatanController.clear();
      setState(() => _selectedDate = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan: $e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // --- UI BOTTOM SHEET FORM CATATAN ---
  void _showAddNoteForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Buat Catatan Konsul", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _topikController,
                    decoration: InputDecoration(labelText: "Agenda / Topik", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _pickDate();
                        setModalState(() {}); 
                      },
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: Text(_selectedDate == null ? "Pilih Tanggal Konsultasi" : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _catatanController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: "Hasil Diskusi / Pesan Dosen", 
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _saveNote,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B5CFA), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _isSubmitting 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                          : const Text("Simpan Catatan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      },
    );
  }

  // --- TAB 1: MOCKUP CHAT AI ---
  Widget _buildAITab() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Chat dari AI
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16, right: 40),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Text(
                    "Halo! Gue asisten AI Gradventure. Ada yang mau diomongin soal KRS, milih matkul, atau keluh kesah tugas numpuk?",
                    style: TextStyle(color: Color(0xFF2D3142), height: 1.4),
                  ),
                ),
              ),
              // Chat dari User (Dummy)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16, left: 40),
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2B5CFA),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(20)),
                  ),
                  child: const Text(
                    "Mending ambil matkul apaan ya buat perbaikan IPK?",
                    style: TextStyle(color: Colors.white, height: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Input Box AI
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -4))],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Tanya AI...",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: const Color(0xFFF4F6F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: const Color(0xFF2B5CFA),
                radius: 24,
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur AI segera hadir! 🤖")));
                  },
                ),
              ),
            ],
          ),
        ),
      ],
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
                    Text("Belum ada catatan konsultasi.", style: TextStyle(color: Colors.grey.shade500)),
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
                            Text(data['topik'] ?? 'Topik Konsultasi', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFF4F6F9), borderRadius: BorderRadius.circular(8)),
                              child: Text(data['tanggal'] ?? '-', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Text(
                          data['catatan']?.toString().isNotEmpty == true ? data['catatan'] : "Tidak ada catatan detail.",
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
            icon: const Icon(Icons.edit_document, color: Colors.white),
            label: const Text("Tulis Catatan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: const Text("Pusat Konsultasi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2D3142),
          elevation: 0,
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Color(0xFF2B5CFA),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF2B5CFA),
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Tanya AI"),
              Tab(text: "Catatan DPA"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAITab(),
            _buildNotesTab(),
          ],
        ),
      ),
    );
  }
}