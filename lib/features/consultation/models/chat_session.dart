import 'package:cloud_firestore/cloud_firestore.dart';

class AiChatMessage {
  final String role; // 'user' or 'model'
  final String text;
  final DateTime timestamp;

  AiChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });

  factory AiChatMessage.fromMap(Map<String, dynamic> map) {
    DateTime time;
    if (map['waktu'] is Timestamp) {
      time = (map['waktu'] as Timestamp).toDate();
    } else if (map['waktu'] is String) {
      time = DateTime.tryParse(map['waktu']) ?? DateTime.now();
    } else {
      time = DateTime.now();
    }

    return AiChatMessage(
      role: map['role'] ?? 'user',
      text: map['text'] ?? '',
      timestamp: time,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'text': text,
      'waktu': Timestamp.fromDate(timestamp),
    };
  }
}

class AiChatSession {
  final String id;
  final String judulSesi;
  final DateTime tanggalDiperbarui;
  final List<AiChatMessage> messages;

  AiChatSession({
    required this.id,
    required this.judulSesi,
    required this.tanggalDiperbarui,
    required this.messages,
  });

  factory AiChatSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    DateTime time;
    if (data['tanggal_diperbarui'] is Timestamp) {
      time = (data['tanggal_diperbarui'] as Timestamp).toDate();
    } else {
      time = DateTime.now();
    }

    final List<dynamic> rawMsgs = data['messages'] ?? [];
    final List<AiChatMessage> msgs = rawMsgs
        .map((m) => AiChatMessage.fromMap(m as Map<String, dynamic>))
        .toList();

    return AiChatSession(
      id: doc.id,
      judulSesi: data['judul_sesi'] ?? 'Percakapan Baru',
      tanggalDiperbarui: time,
      messages: msgs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'judul_sesi': judulSesi,
      'tanggal_diperbarui': Timestamp.fromDate(tanggalDiperbarui),
      'messages': messages.map((m) => m.toMap()).toList(),
    };
  }
}
