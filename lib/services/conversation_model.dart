import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final List<Participant> participants;
  final LastMessage lastMessage;
  final Map<String, int> unreadCount;

  Conversation({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.unreadCount,
  });

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Conversation(
      id: doc.id,
      participants: (data['participants'] as List)
          .map((p) => Participant.fromMap(p))
          .toList(),
      lastMessage: LastMessage.fromMap(data['lastMessage']),
      unreadCount: Map<String, int>.from(data['unreadCount']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants.map((p) => p.toMap()).toList(),
      'lastMessage': lastMessage.toMap(),
      'unreadCount': unreadCount,
    };
  }
}

class Participant {
  final String userId;
  final String role;

  Participant({required this.userId, required this.role});

  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      userId: map['userId'],
      role: map['role'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role,
    };
  }
}

class LastMessage {
  final String content;
  final Timestamp timestamp;
  final String senderId;

  LastMessage({
    required this.content,
    required this.timestamp,
    required this.senderId,
  });

  factory LastMessage.fromMap(Map<String, dynamic> map) {
    return LastMessage(
      content: map['content'],
      timestamp: map['timestamp'],
      senderId: map['senderId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'timestamp': timestamp,
      'senderId': senderId,
    };
  }
}

class Message {
  final String id;
  final String senderId;
  final String content;
  final Timestamp timestamp;
  final String type;
  final String? fileUrl;
  final String? fileName;

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.type,
    this.fileUrl,
    this.fileName,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'],
      content: data['content'],
      timestamp: data['timestamp'],
      type: data['type'],
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp,
      'type': type,
      'fileUrl': fileUrl,
      'fileName': fileName,
    };
  }
}