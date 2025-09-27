// lib/providers/notification_provider.dart
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  bool _hasNewNotification = false;
  bool get hasNewNotification => _hasNewNotification;

  final List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => _notifications;

  void listenForNewQuestions(String tutorId) {
    // log('check notification');
    FirebaseFirestore.instance
        .collection('question_market')
        .where('tutorId', isEqualTo: tutorId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (final docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.added) {
          final data = docChange.doc.data();
          log(data.toString());
          if (data != null) {
            // log('listening to question');
            // log(data.toString());
            _notifications.insert(0, data);
            _hasNewNotification = true;
            notifyListeners();
          }
        }
      }
    });
  }

  void markAllAsRead() {
    _hasNewNotification = false;
    notifyListeners();
  }
}
