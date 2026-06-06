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
    if (map['timestamp'] is Timestamp) {
      time = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      time = DateTime.tryParse(map['timestamp']) ?? DateTime.now();
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
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class AiChatSession {
  final String id;
  final String title;
  final DateTime timestamp;
  final List<AiChatMessage> messages;

  AiChatSession({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.messages,
  });

  factory AiChatSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    DateTime time;
    if (data['timestamp'] is Timestamp) {
      time = (data['timestamp'] as Timestamp).toDate();
    } else {
      time = DateTime.now();
    }

    final List<dynamic> rawMsgs = data['messages'] ?? [];
    final List<AiChatMessage> msgs = rawMsgs
        .map((m) => AiChatMessage.fromMap(m as Map<String, dynamic>))
        .toList();

    return AiChatSession(
      id: doc.id,
      title: data['title'] ?? 'Percakapan Baru',
      timestamp: time,
      messages: msgs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'timestamp': Timestamp.fromDate(timestamp),
      'messages': messages.map((m) => m.toMap()).toList(),
    };
  }
}
