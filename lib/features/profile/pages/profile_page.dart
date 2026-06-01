import 'dart:convert'; // Tambahan buat Base64
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/pages/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController namaController = TextEditingController();
  final TextEditingController nimController = TextEditingController();
  final TextEditingController prodiController = TextEditingController();
  final TextEditingController angkatanController = TextEditingController();

  bool isUpdating = false;
  bool isUploadingPic = false;

  // --- FUNGSI UPLOAD FOTO VERSI JALAN NINJA (BASE64) ---
  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40, // Diturunin dikit biar size stringnya makin enteng di Firestore
    );

    if (pickedFile == null) return;

    setState(() => isUploadingPic = true);

    try {
      File imageFile = File(pickedFile.path);
      
      // 1. Ubah file gambar jadi bytes
      List<int> imageBytes = await imageFile.readAsBytes();
      
      // 2. Konversi bytes gambar jadi teks String Base64
      String base64Image = base64Encode(imageBytes);
      
      // 3. Simpan string teks ini langsung ke Firestore! Nggak butuh Storage lagi.
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'photoUrl': base64Image,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto profil berhasil diganti! 📸"), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal upload foto: $e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => isUploadingPic = false);
    }
  }

  // --- FUNGSI UPDATE DATA TEKS ---
  Future<void> _updateProfile() async {
    if (namaController.text.isEmpty || nimController.text.isEmpty || prodiController.text.isEmpty || angkatanController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data nggak boleh kosong ya!"), backgroundColor: Colors.redAccent),
      );
      return;
    }
    setState(() => isUpdating = true);
    try {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'nama': namaController.text.trim(),
        'nim': nimController.text.trim(),
        'prodi': prodiController.text.trim(),
        'angkatan': angkatanController.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil berhasil diupdate! 🎉"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal update: $e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => isUpdating = false);
    }
  }

  // --- UI BOTTOM SHEET BUAT EDIT ---
  void _showEditModal(Map<String, dynamic> currentData) {
    namaController.text = currentData['nama'] ?? '';
    nimController.text = currentData['nim'] ?? '';
    prodiController.text = currentData['prodi'] ?? '';
    angkatanController.text = currentData['angkatan'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Edit Profil", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2B5CFA))),
              const SizedBox(height: 20),
              TextField(controller: namaController, decoration: InputDecoration(labelText: "Nama Lengkap", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: nimController, decoration: InputDecoration(labelText: "NIM", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: prodiController, decoration: InputDecoration(labelText: "Program Studi", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: angkatanController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Angkatan", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isUpdating ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B5CFA), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: isUpdating ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("Simpan Perubahan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // --- FUNGSI DELETE DATA ---
  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Akun?"),
        content: const Text("Semua data lo bakal hilang. Yakin nih?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await _firestore.collection('users').doc(currentUser!.uid).delete();
                await currentUser!.delete();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
              } on FirebaseAuthException catch (e) {
                if (e.code == 'requires-recent-login') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lo harus login ulang dulu buat hapus akun!"), backgroundColor: Colors.redAccent));
                }
              }
            },
            child: const Text("Ya, Hapus"),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFF2B5CFA).withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: const Color(0xFF2B5CFA)),
      ),
      title: Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Center(child: Text("User belum login"));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profil Mahasiswa", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF2B5CFA)));
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Data profil nggak ketemu nih."));

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String initial = userData['nama'].toString().isNotEmpty ? userData['nama'].toString()[0].toUpperCase() : "U";
          
          String? photoUrl = userData.containsKey('photoUrl') ? userData['photoUrl'] : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          // --- FIX DISPLAY AVATAR DARI BASE64 TEXT ---
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFF2B5CFA).withOpacity(0.1),
                            // Kalo ada data string base64, kita decode balik jadi image memory
                            backgroundImage: photoUrl != null 
                                ? MemoryImage(base64Decode(photoUrl)) 
                                : null,
                            child: photoUrl == null 
                                ? Text(initial, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF2B5CFA)))
                                : null,
                          ),
                          if (isUploadingPic)
                            const Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.white,
                                child: Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2B5CFA)),
                                ),
                              ),
                            )
                          else
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _uploadProfilePicture,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2B5CFA),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(userData['nama'] ?? '-', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
                      Text(userData['email'] ?? currentUser!.email ?? '-', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Divider(),
                _buildInfoTile(Icons.badge_rounded, "NIM", userData['nim'] ?? '-'),
                _buildInfoTile(Icons.school_rounded, "Program Studi", userData['prodi'] ?? '-'),
                _buildInfoTile(Icons.date_range_rounded, "Angkatan", userData['angkatan'] ?? '-'),
                const Divider(),
                const SizedBox(height: 20),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditModal(userData),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text("Edit Profil", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B5CFA), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  ),
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _deleteAccount,
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                    label: const Text("Hapus Akun", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}