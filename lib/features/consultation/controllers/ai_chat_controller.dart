import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/gemini_config.dart';
import '../models/chat_session.dart';

class AiChatController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  List<AiChatMessage> _messages = [];
  List<AiChatMessage> get messages => _messages;

  String? _currentSessionId;
  String? get currentSessionId => _currentSessionId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  late final GenerativeModel _model;
  bool _isModelInitialized = false;

  AiChatController() {
    _initGemini();
  }

  void _initGemini() {
    final key = GeminiConfig.apiKey;
    if (key.isEmpty || key == 'YOUR_GEMINI_API_KEY_HERE') {
      debugPrint('Warning: Gemini API Key is not configured yet.');
      return;
    }

    try {
      _model = GenerativeModel(
        model: GeminiConfig.modelName,
        apiKey: key,
        systemInstruction: Content.system(GeminiConfig.systemInstruction),
      );
      _isModelInitialized = true;
    } catch (e) {
      debugPrint('Error initializing Gemini Model: $e');
    }
  }

  /// Get stream of chat sessions for history
  Stream<List<AiChatSession>> getSessionsStream() {
    if (_uid.isEmpty) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('chat_sessions')
        .orderBy('tanggal_diperbarui', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => AiChatSession.fromFirestore(doc)).toList();
        });
  }

  /// Create a new session
  void startNewChat() {
    _messages = [];
    _currentSessionId = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Load messages from a specific session
  Future<void> loadSession(String sessionId) async {
    if (_uid.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('chat_sessions')
          .doc(sessionId)
          .get();

      if (doc.exists) {
        final session = AiChatSession.fromFirestore(doc);
        _messages = session.messages;
        _currentSessionId = sessionId;
      }
    } catch (e) {
      debugPrint('Error loading chat session: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a chat session
  Future<void> deleteSession(String sessionId) async {
    if (_uid.isEmpty) return;
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('chat_sessions')
          .doc(sessionId)
          .delete();
      
      if (_currentSessionId == sessionId) {
        startNewChat();
      }
    } catch (e) {
      debugPrint('Error deleting session: $e');
    }
  }

  /// Helper to map letter grades to GPA points
  double _gradeToPoint(String grade) {
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

  /// Fetches real-time academic info of the logged-in student and full course catalog
  Future<String> _fetchAcademicContext() async {
    if (_uid.isEmpty) return 'Konteks akademik tidak tersedia (User ID kosong).';

    try {
      // 1. Fetch student profile (Nama, NIM, Prodi)
      final userDoc = await _firestore.collection('users').doc(_uid).get();
      final userData = userDoc.data() ?? {};
      final String nama = userData['nama'] ?? 'Mahasiswa';
      final String nim = userData['nim'] ?? '-';
      final String prodi = userData['prodi'] ?? '-';

      // 2. Fetch student's course history from student_courses -> courses
      final studentCoursesSnapshot = await _firestore
          .collection('student_courses')
          .doc(_uid)
          .collection('courses')
          .get();

      // 3. Fetch all catalog courses
      final globalCoursesSnapshot = await _firestore.collection('courses').get();

      // Parse student courses history
      final List<Map<String, dynamic>> passedCourses = [];
      final List<Map<String, dynamic>> activeCourses = [];
      int totalSksLulus = 0;
      double totalPoints = 0.0;

      for (var doc in studentCoursesSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? '';
        final grade = data['nilai'] ?? 'Belum Diambil';
        final sks = int.tryParse(data['sks']?.toString() ?? '0') ?? 0;
        final kode = data['kode'] ?? doc.id;
        final namaMatkul = data['nama'] ?? 'Mata Kuliah';

        if (status == 'Lulus') {
          passedCourses.add({
            'kode': kode,
            'nama': namaMatkul,
            'sks': sks,
            'nilai': grade,
          });
          totalSksLulus += sks;
          totalPoints += _gradeToPoint(grade) * sks;
        } else if (status == 'Sedang Ditempuh' || grade == 'Sedang Ditempuh') {
          activeCourses.add({
            'kode': kode,
            'nama': namaMatkul,
            'sks': sks,
          });
        }
      }

      final double ipk = totalSksLulus > 0 ? (totalPoints / totalSksLulus) : 0.0;

      // Parse global university curriculum catalog
      final List<Map<String, dynamic>> catalog = [];
      for (var doc in globalCoursesSnapshot.docs) {
        final data = doc.data();
        catalog.add({
          'kode': data['kode'] ?? doc.id,
          'nama': data['nama'] ?? 'Mata Kuliah',
          'sks': int.tryParse(data['sks']?.toString() ?? '0') ?? 0,
          'semester': int.tryParse(data['semester']?.toString() ?? '0') ?? 0,
          'prasyarat': data['prasyarat'] ?? [],
        });
      }

      // Format clean markdown string for Gemini context injection
      final buffer = StringBuffer();
      buffer.writeln("[PROFIL MAHASISWA SAAT INI]");
      buffer.writeln("- Nama: $nama");
      buffer.writeln("- NIM: $nim");
      buffer.writeln("- Program Studi: $prodi");
      buffer.writeln("- Total SKS Lulus: $totalSksLulus SKS");
      buffer.writeln("- Estimasi IPK: ${ipk.toStringAsFixed(2)}");
      
      buffer.writeln("\n[RIWAYAT MATA KULIAH LULUS]");
      if (passedCourses.isEmpty) {
        buffer.writeln("- Belum ada mata kuliah yang lulus.");
      } else {
        for (var c in passedCourses) {
          buffer.writeln("- Kode: ${c['kode']}, Nama: ${c['nama']}, SKS: ${c['sks']}, Nilai: ${c['nilai']}");
        }
      }

      buffer.writeln("\n[MATA KULIAH SEDANG DITEMPUH]");
      if (activeCourses.isEmpty) {
        buffer.writeln("- Tidak ada mata kuliah yang sedang ditempuh.");
      } else {
        for (var c in activeCourses) {
          buffer.writeln("- Kode: ${c['kode']}, Nama: ${c['nama']}, SKS: ${c['sks']}");
        }
      }

      buffer.writeln("\n[KURIKULUM & DAFTAR MATA KULIAH SE-UNIVERSITAS]");
      if (catalog.isEmpty) {
        buffer.writeln("- Katalog mata kuliah kosong.");
      } else {
        for (var c in catalog) {
          final String prasyaratText = (c['prasyarat'] as List).isEmpty 
              ? "Tidak ada" 
              : (c['prasyarat'] as List).join(", ");
          buffer.writeln("- Kode: ${c['kode']}, Nama: ${c['nama']}, SKS: ${c['sks']}, Semester Penawaran: ${c['semester']}, Prasyarat: $prasyaratText");
        }
      }

      return buffer.toString();
    } catch (e) {
      debugPrint("Error fetching academic context: $e");
      return "Gagal memuat konteks akademik terbaru: $e";
    }
  }

  /// Send message to Gemini and save to Firestore
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _uid.isEmpty) return;

    // 1. Add user message locally
    final userMessage = AiChatMessage(
      role: 'user',
      text: text.trim(),
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    _isLoading = true;
    notifyListeners();

    // Check configuration
    if (!_isModelInitialized) {
      final errorMessage = AiChatMessage(
        role: 'model',
        text: '⚠️ API Key Gemini belum dikonfigurasi. Harap tambahkan API Key Anda di file lib/features/consultation/config/gemini_config.dart agar fitur chat dapat berfungsi.',
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // 2. Fetch real-time student academic context
      final String academicContext = await _fetchAcademicContext();

      // Combine default instructions with dynamic data context
      final String dynamicSystemInstruction = 
          "${GeminiConfig.systemInstruction}\n\n"
          "Berikut adalah data akademik mahasiswa saat ini yang sedang login beserta seluruh daftar mata kuliah di kurikulum. "
          "Gunakan data ini untuk memberikan rekomendasi pengambilan mata kuliah yang akurat, "
          "hitung kelayakan prasyarat (mahasiswa hanya boleh mengambil suatu matkul jika kode matkul prasyaratnya sudah tercantum dalam [RIWAYAT MATA KULIAH LULUS] dengan nilai minimal selain E), "
          "dan jawab pertanyaan seputar SKS atau IPK mereka secara personal:\n\n"
          "$academicContext";

      // 3. Format history for Google Gemini API
      final List<Content> historyContents = [];
      for (int i = 0; i < _messages.length - 1; i++) {
        final m = _messages[i];
        if (m.role == 'user' || m.role == 'model') {
          historyContents.add(
            m.role == 'user'
                ? Content.text(m.text)
                : Content.model([TextPart(m.text)]),
          );
        }
      }

      // 4. Request Gemini API with robust retry and fallback mechanism
      GenerateContentResponse? response;
      final List<String> modelsToTry = [
        GeminiConfig.modelName, // 'gemini-2.5-flash'
        'gemini-1.5-flash',
        'gemini-1.5-pro',
      ];

      for (String model in modelsToTry) {
        int retryCount = 0;
        const int maxRetries = 3;
        int backoffMs = 1000;
        bool success = false;

        while (retryCount < maxRetries) {
          try {
            debugPrint('Trying Gemini API call with model: $model (Attempt ${retryCount + 1}/$maxRetries)');
            final dynamicModel = GenerativeModel(
              model: model,
              apiKey: GeminiConfig.apiKey,
              systemInstruction: Content.system(dynamicSystemInstruction),
            );
            final chat = dynamicModel.startChat(history: historyContents);
            response = await chat.sendMessage(Content.text(text.trim()));
            success = true;
            break; // Success! Break the retry loop
          } catch (e) {
            final errStr = e.toString().toLowerCase();
            // Check if it is a transient server error (503, high demand, unavailable, or rate limit)
            if (errStr.contains('503') || errStr.contains('demand') || errStr.contains('unavailable') || errStr.contains('quota') || errStr.contains('limit')) {
              retryCount++;
              if (retryCount < maxRetries) {
                debugPrint('Gemini transient error with $model: $e. Retrying in ${backoffMs}ms...');
                await Future.delayed(Duration(milliseconds: backoffMs));
                backoffMs *= 2; // Exponential backoff
                continue;
              }
            }
            debugPrint('Failed to generate content with model $model: $e');
            break; // Break retry loop to try the next fallback model
          }
        }

        if (success && response != null) {
          break; // Break the outer model loop if successful
        }
      }

      if (response == null) {
        throw Exception("Semua model Gemini sedang mengalami beban tinggi (High Demand). Silakan coba lagi beberapa saat lagi.");
      }

      final responseText = response.text ?? 'Maaf, saya tidak menerima jawaban.';

      // 5. Add model message locally
      final modelMessage = AiChatMessage(
        role: 'model',
        text: responseText,
        timestamp: DateTime.now(),
      );
      _messages.add(modelMessage);

      // 6. Persist to Firestore
      await _saveCurrentSessionToFirestore();
    } catch (e) {
      debugPrint('Error calling Gemini: $e');
      final errorMessage = AiChatMessage(
        role: 'model',
        text: '⚠️ Terjadi kesalahan saat menghubungi asisten AI: $e',
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save session to Firestore
  Future<void> _saveCurrentSessionToFirestore() async {
    if (_uid.isEmpty || _messages.isEmpty) return;

    try {
      final title = _messages.first.text.length > 20
          ? '${_messages.first.text.substring(0, 20)}...'
          : _messages.first.text;

      final sessionData = {
        'judul_sesi': title,
        'tanggal_diperbarui': FieldValue.serverTimestamp(),
        'messages': _messages.map((m) => m.toMap()).toList(),
      };

      if (_currentSessionId == null) {
        // Create new session document
        final docRef = await _firestore
            .collection('users')
            .doc(_uid)
            .collection('chat_sessions')
            .add(sessionData);
        _currentSessionId = docRef.id;
      } else {
        // Update existing session document
        await _firestore
            .collection('users')
            .doc(_uid)
            .collection('chat_sessions')
            .doc(_currentSessionId)
            .set(sessionData, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving session to Firestore: $e');
    }
  }
}
