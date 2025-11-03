import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/feature/notification/student_provider.dart';

import '../../firebase/database.dart';
import '../calendar/constants/custom_colors.dart';
import '../calendar/constants/custom_styles.dart';
import '../calendar/widgets/alert_overlay.dart';
import 'answer_provider.dart';

class AnswerLibraryModal extends StatefulWidget {
  const AnswerLibraryModal({
    super.key,
    required this.tutorId,
    required this.studentId,
    required this.questionId,
    required this.questionName,
    required this.courseId,
  });

  final String tutorId;
  final String studentId;
  final String questionId;
  final String questionName;
  final String courseId;

  @override
  State<AnswerLibraryModal> createState() => _AnswerLibraryModalState();
}

class _AnswerLibraryModalState extends State<AnswerLibraryModal> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  FirebaseService firebaseService = FirebaseService();
  String? _selectedAnswerId;
  Map<String, dynamic>? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final answer = context.read<AnswerProvider>();
      await answer.fetchAnswersByTutor(widget.tutorId);
      answer.selectCourse(widget.courseId);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // responsive-ish: cap the modal size
          maxWidth: 720,
          maxHeight: media.height * 0.8,
        ),
        child: Consumer<AnswerProvider>(
          builder: (_, answer, __) {
            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('คลังคำตอบ',
                            style: CustomStyles.bold22Black363636),
                      ),
                      IconButton(
                        onPressed: () {
                          context.read<AnswerProvider>().selectCourse(null);
                          Navigator.of(context).pop(false);
                        },
                        icon: const Icon(Icons.close),
                        color: CustomColors.gray878787,
                        tooltip: 'ปิด',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Body
                Expanded(
                  child: RefreshIndicator(
                    key: _refreshIndicatorKey,
                    onRefresh: () async {
                      await answer.fetchAnswersByTutor(widget.tutorId);
                      await Future.delayed(const Duration(milliseconds: 150));
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: answer.isLoading
                          ? const _LoadingBlock()
                          : _answerGrid(answer.filteredAnswers),
                    ),
                  ),
                ),

                // Footer actions
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Row(
                    children: [
                      const Spacer(),
                      FilledButton(
                        onPressed: _selectedAnswer == null
                            ? null
                            : () async {
                                final ans = _selectedAnswer!;
                                // Safe reads + casts (use defaults if missing)
                                final courseId = ans['courseId'] as String? ?? '';
                                final courseName =
                                    ans['courseName'] as String? ?? '';
                                final lesson = (ans['lesson'] is int)
                                    ? ans['lesson'] as int
                                    : int.tryParse('${ans['lesson']}') ?? 0;
                                final page = (ans['page'] is int)
                                    ? ans['page'] as int
                                    : int.tryParse('${ans['page']}') ?? 0;
                                final solvepad = ans['solvepad'] as String? ?? '';
                                final tutorId = ans['tutorId'] as String? ?? '';
                                final qName = widget.questionName as String? ?? '';
                                final origQId =
                                    ans['questionId'] as String? ?? '';
                                final origAId = ans['id'] as String? ?? '';
                                final courseTime = ans['courseTime'] ?? 0;

                                // Optional: basic validation
                                if (courseId.isEmpty ||
                                    tutorId.isEmpty ||
                                    origAId.isEmpty) {
                                  debugPrint(
                                      'Missing required fields on selected answer');
                                  return;
                                }

                                try {
                                  await Alert.showOverlay(
                                    asyncFunction: () async {
                                      await firebaseService.addReuseAnswer(
                                        courseId: courseId,
                                        courseName: courseName,
                                        courseTime: courseTime,
                                        lesson: lesson,
                                        page: page,
                                        solvepad: solvepad,
                                        tutorId: tutorId,
                                        studentId: widget.studentId,         // target student (current question’s student)
                                        questionId: widget.questionId,       // NEW question id (target)
                                        questionName: qName,
                                        originalQuestionId: origQId,
                                        originalAnswerId: origAId,
                                      );
                                    },
                                    context: context,
                                    loadingWidget: Alert.getOverlayScreen(),
                                  );

                                  if (!mounted) return;
                                  context.read<AnswerProvider>().selectCourse(null);
                                  Navigator.of(context).pop(true);
                                } catch (e, st) {
                                  debugPrint('Failed to reuse answer: $e\n$st');
                                  if (!mounted) return;
                                  // keep modal open; show a toast/snackbar if you have one
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('บันทึกไม่สำเร็จ ลองอีกครั้ง')),
                                  );
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF20B153),
                          minimumSize: const Size(140, 40),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                        ),
                        child: const Text('เลือกคำตอบ'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _answerGrid(List<Map<String, dynamic>> answers) {
    return Consumer<StudentProvider>(
      builder: (_, students, __) {
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

                      final String answerId = (answer['id'] as String?) ?? '';
                      final bool isSelected = _selectedAnswerId == answerId;

                      return InkWell(
                        onTap: () {
                          _selectedAnswerId =
                              (_selectedAnswerId == answerId) ? null : answerId;
                          final answerMap = answers[
                              index]; // the same 'answer' you already have
                          setState(() {
                            if (_selectedAnswer != null &&
                                _selectedAnswer!['id'] == answerMap['id']) {
                              _selectedAnswer =
                                  null; // deselect if tapping the same
                            } else {
                              _selectedAnswer =
                                  answerMap; // store the whole object
                            }
                          });
                        },
                        child: _AnswerCard(
                          questionName: questionName,
                          studentName: studentName,
                          courseName: courseName,
                          courseImageUrl: courseImageUrl,
                          lesson: lesson,
                          pageNo: pageNo,
                          isSelected: isSelected,
                        ),
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

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 60, height: 60, child: CircularProgressIndicator()),
          SizedBox(height: 12),
          Text('กำลังโหลด...'),
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  final String questionName;
  final String studentName;
  final String courseName;
  final String? courseImageUrl;
  final int lesson;
  final int pageNo;
  final bool isSelected;

  const _AnswerCard({
    required this.questionName,
    required this.studentName,
    required this.courseName,
    required this.lesson,
    required this.pageNo,
    this.courseImageUrl,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isSelected ? const Color(0xFF20B153) : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
              ],
              border: Border.all(
                  color: borderColor, width: 2), // <-- green when selected
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: courseImageUrl != null && courseImageUrl!.isNotEmpty
                        ? Image.network(courseImageUrl!, fit: BoxFit.cover)
                        : Image.asset('assets/images/default_course_img.png',
                            fit: BoxFit.cover),
                  ),
                ),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text("Student: $studentName", maxLines: 1,),
                        Text("Course: $courseName", maxLines: 2,),
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

          // Checkmark badge when selected
          if (isSelected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF20B153),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4)
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.check, size: 18, color: Colors.white),
              ),
            ),
        ],
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
