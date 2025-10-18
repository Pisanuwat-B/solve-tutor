// lib/providers/answer_provider.dart
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../calendar/model/select_option_item.dart';

class AnswerProvider extends ChangeNotifier {
  bool isLoading = false;
  List<Map<String, dynamic>> _answers = [];

  List<Map<String, dynamic>> get answers => _answers;
  List<String> _courses = [];

  List<String> get courses => _courses;
  String? selectedCourse;

  List<SelectOptionItem> get courseOptions =>
      courses.map((c) => SelectOptionItem(id: c, name: c)).toList();
  String? selectedCourseId;

  void selectCourse(String? id) {
    selectedCourseId = id;
    notifyListeners();
  }

  Future<void> fetchAnswersByTutor(String tutorId) async {
    try {
      isLoading = true;
      notifyListeners();

      final snapshot = await FirebaseFirestore.instance
          .collection('answer_market')
          .where('tutorId', isEqualTo: tutorId)
          .orderBy('timestamp', descending: true)
          .get();
      _answers = snapshot.docs
          .where((doc) {
        final data = doc.data();
        return data['isReuse'] != true;
      }).map((doc) => {'id': doc.id, ...doc.data()}).toList();

      // extract unique course list
      _courses = _answers
          .map((e) => e['courseName'] as String? ?? '')
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      isLoading = false;
      notifyListeners();
    } catch (e, st) {
      log('fetchAnswersByTutor error: $e\n$st');
      isLoading = false;
      notifyListeners();
    }
  }

  String? get selectedCourseName => courseOptions
      .firstWhere(
        (o) => o.id == selectedCourseId,
        orElse: () => SelectOptionItem(id: '', name: ''),
      )
      .name;

  // Update your existing filtered getter to use selectedCourseId
  List<Map<String, dynamic>> get filteredAnswers {
    if (selectedCourseId == null || selectedCourseId!.isEmpty) return _answers;
    return _answers.where((a) => a['courseName'] == selectedCourseId).toList();
  }

  void clear() {
    _answers.clear();
    _courses.clear();
    selectedCourse = null;
    notifyListeners();
  }
}
