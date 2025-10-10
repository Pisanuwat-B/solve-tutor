// lib/providers/notification_provider.dart
import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  bool _hasNewNotification = false;
  bool get hasNewNotification => _hasNewNotification;

  final List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => _notifications;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  void listenForNewQuestions(String tutorId) {
    _sub?.cancel(); // avoid multiple listeners
    _sub = FirebaseFirestore.instance
        .collection('question_market')
        .where('tutorId', isEqualTo: tutorId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        final doc = change.doc;
        final data = doc.data();
        if (data == null) continue;

        if (change.type == DocumentChangeType.added) {
          final item = {'id': doc.id, ...data};
          _notifications.insert(0, item);
          log('added: $item');
          _hasNewNotification = true;
        } else if (change.type == DocumentChangeType.modified) {
          final idx = _notifications.indexWhere((e) => e['id'] == doc.id);
          if (idx != -1) {
            _notifications[idx] = {'id': doc.id, ...data};
            log('modified: ${_notifications[idx]}');
          }
        } else if (change.type == DocumentChangeType.removed) {
          _notifications.removeWhere((e) => e['id'] == doc.id);
          log('removed: ${doc.id}');
        }
      }
      notifyListeners();
    });
  }

  void markAllAsRead() {
    _hasNewNotification = false;
    notifyListeners();
  }
}
