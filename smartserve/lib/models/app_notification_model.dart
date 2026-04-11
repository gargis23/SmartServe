import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      userId: (map['userId'] ?? '').toString(),
      title: (map['title'] ?? 'Notification').toString(),
      body: (map['body'] ?? '').toString(),
      type: (map['type'] ?? 'general').toString(),
      isRead: map['isRead'] == true,
      createdAt: _parseDate(map['createdAt']),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? const {}),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
