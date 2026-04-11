import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/app_notification_model.dart';

class AppNotificationService {
  AppNotificationService._internal();

  static final AppNotificationService _instance = AppNotificationService._internal();

  factory AppNotificationService() => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  bool _listenersAttached = false;

  Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _saveCurrentFcmToken();

    if (_listenersAttached) {
      return;
    }
    _listenersAttached = true;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final user = _auth.currentUser;
      if (user == null) {
        return;
      }

      final title = message.notification?.title ?? 'SmartServe';
      final body = message.notification?.body ?? 'You have a new update.';
      final data = message.data;

      createNotification(
        userId: user.uid,
        title: title,
        body: body,
        type: (data['type'] ?? 'push').toString(),
        metadata: data,
      );
    });

    _messaging.onTokenRefresh.listen((token) async {
      final user = _auth.currentUser;
      if (user == null) {
        return;
      }
      await _db.collection('users').doc(user.uid).set(
        {
          'fcmTokens': FieldValue.arrayUnion([token]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> _saveCurrentFcmToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    await _db.collection('users').doc(user.uid).set(
      {
        'fcmTokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic> metadata = const {},
  }) async {
    final model = AppNotification(
      id: '',
      userId: userId,
      title: title,
      body: body,
      type: type,
      isRead: false,
      createdAt: DateTime.now(),
      metadata: metadata,
    );

    await _db.collection('notifications').add(model.toMap());
  }

  Future<void> broadcastNotificationToRole({
    required String role,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic> metadata = const {},
  }) async {
    final userSnapshot = await _db
        .collection('users')
        .where('role', isEqualTo: role)
        .get();

    if (userSnapshot.docs.isEmpty) {
      return;
    }

    final batch = _db.batch();

    for (final userDoc in userSnapshot.docs) {
      final notificationRef = _db.collection('notifications').doc();
      final model = AppNotification(
        id: notificationRef.id,
        userId: userDoc.id,
        title: title,
        body: body,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
        metadata: metadata,
      );
      batch.set(notificationRef, model.toMap());
    }

    await batch.commit();
  }

  Stream<List<AppNotification>> getUserNotifications(String userId) {
    final baseQuery = _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .limit(100);

    final orderedQuery = baseQuery.orderBy('createdAt', descending: true);

    return _streamNotificationsWithFallback(orderedQuery, baseQuery);
  }

  Stream<List<AppNotification>> _streamNotificationsWithFallback(
    Query<Map<String, dynamic>> orderedQuery,
    Query<Map<String, dynamic>> fallbackQuery,
  ) async* {
    try {
      await for (final snapshot in orderedQuery.snapshots()) {
        yield _mapNotificationDocs(snapshot.docs);
      }
    } on FirebaseException catch (error) {
      if (error.code != 'failed-precondition') {
        rethrow;
      }

      await for (final snapshot in fallbackQuery.snapshots()) {
        final notifications = _mapNotificationDocs(snapshot.docs);
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        yield notifications;
      }
    }
  }

  List<AppNotification> _mapNotificationDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs
        .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<int> getUnreadCount(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
