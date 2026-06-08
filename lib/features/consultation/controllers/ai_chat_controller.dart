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

  /// Fetches real-time academic info of the logged-in student, performs all business calculations hardcoded in Dart,
  /// and constructs a minimal, high-value prompt context for the Gemini API.
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

      // Create mapping of code to course catalog info
      final Map<String, Map<String, dynamic>> catalogMap = {};
      final List<Map<String, dynamic>> catalog = [];
      for (var doc in globalCoursesSnapshot.docs) {
        final data = doc.data();
        final String kode = data['kode'] ?? doc.id;
        final mapData = {
          'kode': kode,
          'nama': data['nama'] ?? 'Mata Kuliah',
          'sks': int.tryParse(data['sks']?.toString() ?? '0') ?? 0,
          'semester': int.tryParse(data['semester']?.toString() ?? '0') ?? 0,
          'prasyarat': data['prasyarat'] ?? [],
        };
        catalogMap[kode] = mapData;
        catalog.add(mapData);
      }

      // Parse student course history
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

      // 4. Calculate Current Semester active/upcoming
      // Rule: Terendah dari matkul yang sedang ditempuh, atau jika tidak ada maka semester + 1 dari semester tertinggi yang sudah lulus.
      // Jika keduanya tidak ada, default ke semester 1.
      int? minActiveSemester;
      for (var c in activeCourses) {
        final catCourse = catalogMap[c['kode']];
        if (catCourse != null) {
          final sem = catCourse['semester'] as int;
          if (minActiveSemester == null || sem < minActiveSemester) {
            minActiveSemester = sem;
          }
        }
      }

      int maxPassedSemester = 0;
      for (var c in passedCourses) {
        final catCourse = catalogMap[c['kode']];
        if (catCourse != null) {
          final sem = catCourse['semester'] as int;
          if (sem > maxPassedSemester) {
            maxPassedSemester = sem;
          }
        }
      }

      int currentSemester = 1;
      if (minActiveSemester != null) {
        currentSemester = minActiveSemester;
      } else if (passedCourses.isNotEmpty) {
        currentSemester = maxPassedSemester + 1;
      }

      // 5. Calculate Cumlaude Eligibility
      // Rule: IPK >= 3.5, maksimal mengulang 2 kali, tidak ada nilai di bawah B
      bool isCumlaudeEligible = true;
      final List<String> cumlaudeFailReasons = [];

      if (ipk < 3.5) {
        isCumlaudeEligible = false;
        cumlaudeFailReasons.add("IPK saat ini (${ipk.toStringAsFixed(2)}) kurang dari syarat minimal 3.50");
      }

      // Check if there are any grades below B (points < 3.0)
      bool hasDisallowedGrade = false;
      for (var c in passedCourses) {
        final String grade = c['nilai'] ?? '';
        final double point = _gradeToPoint(grade);
        if (point < 3.0) {
          hasDisallowedGrade = true;
          cumlaudeFailReasons.add("Mata kuliah ${c['nama']} (${c['kode']}) mendapat nilai $grade (nilai di bawah B)");
        }
      }
      if (hasDisallowedGrade) {
        isCumlaudeEligible = false;
      }

      // Check repeats
      final Map<String, int> courseAttempts = {};
      for (var doc in studentCoursesSnapshot.docs) {
        final data = doc.data();
        final String kode = data['kode'] ?? doc.id;
        courseAttempts[kode] = (courseAttempts[kode] ?? 0) + 1;
      }
      bool hasExceededRepeats = false;
      courseAttempts.forEach((kode, attempts) {
        if (attempts > 3) { // taken more than 3 times means repeated more than 2 times
          hasExceededRepeats = true;
          final String name = catalogMap[kode]?['nama'] ?? kode;
          cumlaudeFailReasons.add("Mata kuliah $name ($kode) diambil sebanyak $attempts kali (maksimal mengulang 2 kali)");
        }
      });
      if (hasExceededRepeats) {
        isCumlaudeEligible = false;
      }

      // 6. Calculate courses eligible to be taken next (Prerequisites checked)
      // Rule: Untuk mengambil matkul prasyarat, pastikan matkul prasyaratnya sudah diambil dan minimal nilai C (2.0).
      final List<String> eligibleCourses = [];
      for (var c in catalog) {
        final String code = c['kode'];
        
        // If student has already passed this course with grade >= C, no need to retake
        final passedSelf = passedCourses.firstWhere((pc) => pc['kode'] == code, orElse: () => {});
        if (passedSelf.isNotEmpty && _gradeToPoint(passedSelf['nilai'] ?? '') >= 2.0) {
          continue;
        }

        // Check prerequisites
        bool prereqMet = true;
        final List<dynamic> prereqs = c['prasyarat'] ?? [];
        for (var pre in prereqs) {
          final passedPre = passedCourses.firstWhere((pc) => pc['kode'] == pre, orElse: () => {});
          if (passedPre.isEmpty || _gradeToPoint(passedPre['nilai'] ?? '') < 2.0) {
            prereqMet = false;
            break;
          }
        }

        if (prereqMet) {
          eligibleCourses.add("- ${c['nama']} (${c['kode']}) - SKS: ${c['sks']}, Semester Penawaran: ${c['semester']}");
        }
      }

      // Format clean markdown string for Gemini context injection
      final buffer = StringBuffer();
      buffer.writeln("[PROFIL MAHASISWA SAAT INI]");
      buffer.writeln("- Nama: $nama");
      buffer.writeln("- NIM: $nim");
      buffer.writeln("- Program Studi: $prodi");
      buffer.writeln("- Semester Aktif/Akan Datang: Semester $currentSemester");
      buffer.writeln("- Total SKS Lulus: $totalSksLulus SKS");
      buffer.writeln("- Estimasi IPK: ${ipk.toStringAsFixed(2)}");
      
      buffer.writeln("\n[STATUS KELULUSAN]");
      if (totalSksLulus >= 144) {
        buffer.writeln("- Mahasiswa telah memenuhi batas minimal kelulusan 144 SKS.");
      } else {
        buffer.writeln("- Mahasiswa membutuhkan ${144 - totalSksLulus} SKS lagi untuk memenuhi syarat kelulusan 144 SKS.");
      }

      buffer.writeln("\n[STATUS PRESTASI CUMLAUDE]");
      if (isCumlaudeEligible) {
        buffer.writeln("- Mahasiswa memenuhi syarat untuk predikat Cumlaude.");
      } else {
        buffer.writeln("- Mahasiswa TIDAK memenuhi syarat untuk predikat Cumlaude karena:");
        for (var reason in cumlaudeFailReasons) {
          buffer.writeln("  * $reason");
        }
      }

      buffer.writeln("\n[RIWAYAT MATA KULIAH LULUS]");
      if (passedCourses.isEmpty) {
        buffer.writeln("- Belum ada mata kuliah yang lulus.");
      } else {
        for (var c in passedCourses) {
          buffer.writeln("- ${c['nama']} (${c['kode']}) - SKS: ${c['sks']}, Nilai: ${c['nilai']}");
        }
      }

      buffer.writeln("\n[MATA KULIAH SEDANG DITEMPUH]");
      if (activeCourses.isEmpty) {
        buffer.writeln("- Tidak ada mata kuliah yang sedang ditempuh.");
      } else {
        for (var c in activeCourses) {
          buffer.writeln("- ${c['nama']} (${c['kode']}) - SKS: ${c['sks']}");
        }
      }

      buffer.writeln("\n[MATA KULIAH YANG DAPAT DIAMBIL BERDASARKAN SYARAT PRASYARAT]");
      if (eligibleCourses.isEmpty) {
        buffer.writeln("- Tidak ada mata kuliah di katalog yang prasyaratnya terpenuhi.");
      } else {
        buffer.writeln(eligibleCourses.join("\n"));
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
          "Berikut adalah hasil perhitungan akademik mahasiswa saat ini yang telah dihitung secara hardcoded dan valid di sistem backend. "
          "Gunakan hasil perhitungan ini secara langsung untuk menjawab pertanyaan mahasiswa (termasuk rekomendasi semester depan, prasyarat, kelayakan cumlaude, semester aktif, dan SKS/IPK) "
          "agar jawaban Anda sangat akurat tanpa perlu melakukan perhitungan manual lagi:\n\n"
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
