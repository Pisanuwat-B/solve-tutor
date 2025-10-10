import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/feature/calendar/constants/constants.dart';
// import your styles/colors as needed
import 'package:solve_tutor/feature/calendar/widgets/dropdown.dart';
import 'package:solve_tutor/feature/calendar/widgets/widgets.dart';

import '../../calendar/controller/create_course_controller.dart';
import '../../calendar/model/select_option_item.dart';
import '../../notification/answer_provider.dart';
import '../../notification/student_provider.dart';

class AnswerLibrary extends StatefulWidget {
  const AnswerLibrary({super.key, required this.tutorId});

  final String tutorId;

  @override
  State<AnswerLibrary> createState() => _AnswerLibraryState();
}

class _AnswerLibraryState extends State<AnswerLibrary> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    // kick off the first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnswerProvider>().fetchAnswersByTutor(widget.tutorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnswerProvider>(
      builder: (_, answer, __) {
        return Scaffold(
          appBar: AppBar(
            leading: InkWell(
              onTap: () => Navigator.of(context).pop(),
              child:
                  const Icon(Icons.arrow_back, color: CustomColors.gray878787),
            ),
            centerTitle: false,
            backgroundColor: CustomColors.whitePrimary,
            elevation: 6,
            title: Text('คลังคำตอบ', style: CustomStyles.bold22Black363636),
          ),
          body: SafeArea(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: () async {
                await answer.fetchAnswersByTutor(widget.tutorId);
                await Future.delayed(const Duration(milliseconds: 250));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  S.h(10.0),
                  // One dropdown: courses that have answers by this tutor
                  _courseDropdown(answer),
                  Expanded(
                    child: answer.isLoading
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 60,
                                height: 60,
                                child: CircularProgressIndicator(),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: Text('กำลังโหลด...'),
                              ),
                            ],
                          )
                        : _answerGrid(answer.filteredAnswers),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _courseDropdown(AnswerProvider answer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Dropdown(
              items: answer.courseOptions, // List<SelectOptionItem>
              selectedValue: answer.selectedCourseId ?? '', // String id
              hintText: '-- เลือกคอร์ส --',
              onChanged: (opt) => answer.selectCourse(
                // opt is SelectOptionItem?
                (opt as SelectOptionItem?)?.id,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _answerGrid(List<Map<String, dynamic>> answers) {
    return Consumer2<CourseController, StudentProvider>(
      builder: (_, courses, students, __) {
        if (answers.isEmpty) {
          return const Center(child: Text('ยังไม่มีคำตอบในคลังของคุณ'));
        }
        students.preloadStudents(
            answers.map((a) => a['studentId'] as String).toSet().toList());

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            final crossAxisCount =
                isNarrow ? 1 : 2; // 50% width on normal screens

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                itemCount: answers.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  // Card height:width ratio (tweak to your taste)
                  childAspectRatio: isNarrow ? 16 / 9 : 16 / 6.5,
                ),
                itemBuilder: (context, index) {
                  final answer = answers[index];

                  final String questionName =
                      (answer['questionName'] as String?) ?? '';
                  final String studentId =
                      (answer['studentId'] as String?) ?? '';
                  final String studentName = students.getStudentName(studentId);

                  final String courseId = (answer['courseId'] as String?) ?? '';
                  final String courseName =
                      (answer['courseName'] as String?) ?? '';

                  // Find course image from CourseController (best-effort)
                  return FutureBuilder<String?>(
                    future: _CourseThumbCache.getThumb(courseId),
                    builder: (context, snap) {
                      final courseImageUrl =
                          snap.data; // null while loading or if missing

                      final int lesson = (answer['lesson'] as int?) ?? 0;
                      final int pageNo = (answer['page'] as int?) ?? 0;

                      return _AnswerCardHalfWidth(
                        questionName: questionName,
                        studentName: studentName,
                        courseName: courseName,
                        courseImageUrl: courseImageUrl,
                        lesson: lesson,
                        pageNo: pageNo,
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _AnswerCardHalfWidth extends StatelessWidget {
  final String questionName;
  final String studentName;
  final String courseName;
  final String? courseImageUrl;
  final int lesson;
  final int pageNo;

  const _AnswerCardHalfWidth({
    required this.questionName,
    required this.studentName,
    required this.courseName,
    required this.lesson,
    required this.pageNo,
    this.courseImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Left image uses tile width, not screen width
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 1, // square-ish thumb area
                child: courseImageUrl != null && courseImageUrl!.isNotEmpty
                    ? Image.network(courseImageUrl!, fit: BoxFit.cover)
                    : Image.asset('assets/images/default_course_img.png',
                        fit: BoxFit.cover),
              ),
            ),

            // Right info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 10.0, right: 12.0, top: 10, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      questionName.isEmpty
                          ? 'UNNAMED QUESTION From: $studentName'
                          : 'คำตอบของ: $questionName',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text("Student: $studentName"),
                    Text("Course: $courseName"),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text("Lesson: $lesson"),
                        const SizedBox(width: 16),
                        Text("Page: $pageNo"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseThumbCache {
  static final Map<String, String?> _thumbByCourseId = {};

  static Future<String?> getThumb(String courseId) async {
    if (_thumbByCourseId.containsKey(courseId)) {
      return _thumbByCourseId[courseId];
    }
    final doc = await FirebaseFirestore.instance
        .collection('course')
        .doc(courseId)
        .get();

    final url = (doc.data()?['thumbnail_url'] as String?)?.trim();
    _thumbByCourseId[courseId] = (url == null || url.isEmpty) ? null : url;
    return _thumbByCourseId[courseId];
  }
}
