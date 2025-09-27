import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/constants/theme.dart';
import 'package:solve_tutor/feature/notification/question_notification_card.dart';
import 'package:solve_tutor/feature/notification/record_answer.dart';
import 'package:solve_tutor/widgets/sizer.dart';

import '../../firebase/database.dart';
import '../calendar/controller/create_course_controller.dart';
import '../calendar/model/course_model.dart';
import 'notification_provider.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context);
    final notifications = provider.notifications;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'แจ้งเตือน',
          style: TextStyle(
            color: appTextPrimaryColor,
          ),
        ),
      ),
      body: notifications.isEmpty
          ? SizedBox(
        width: Sizer(context).w,
        height: Sizer(context).h,
        child: Column(
          children: [
            SizedBox(height: Sizer(context).h * 0.35),
            const Icon(
              CupertinoIcons.cube_box,
              size: 50,
              color: Colors.grey,
            ),
            const SizedBox(height: 10),
            const Text("ไม่มีแจ้งเตือน"),
          ],
        ),
      )
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final data = notifications[index];
          final courseId  = data['courseId'] as String;
          final studentId = data['studentId'] as String;
          final lessonId  = int.tryParse('${data['lessonId']}') ?? 0;

          final courseNameFuture = firebaseService.getCourseNameCached(courseId);

          return FutureBuilder<String?>(
            future: courseNameFuture,
            builder: (context, snap) {
              final hasName  = snap.connectionState == ConnectionState.done && snap.hasData;
              final hasError = snap.hasError;
              final courseName = snap.data ?? '';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: (!hasName || hasError)
                      ? null // block until loaded (or if error)
                      : () async {
                    // also make sure CourseModel is loaded before entering RecordAnswer
                    final courseController = context.read<CourseController>();
                    final course = await courseController.getCourseById(courseId);

                    final lesson = course.lessons?.firstWhere(
                          (l) => l.lessonId == lessonId,
                      orElse: () => Lessons(lessonId: lessonId, lessonName: "Unknown"),
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecordAnswer(
                          course: course,
                          lesson: lesson!,
                          studentId: studentId,
                          questionText: courseName, // pass the loaded name
                        ),
                      ),
                    );
                  },
                  child: hasError
                      ? _QuestionCardError(
                    studentId: studentId,
                    courseId: courseId,
                    lesson: lessonId,
                  )
                      : hasName
                      ? QuestionNotificationCard(
                    questionText: courseName,   // show course name here
                    studentId: studentId,
                    courseId: courseId,
                    lesson: lessonId,
                  )
                      : const _QuestionCardSkeleton(), // skeleton while loading
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _QuestionCardSkeleton extends StatelessWidget {
  const _QuestionCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SkeletonLine(width: 180),
          SizedBox(height: 8),
          _SkeletonLine(width: 120),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({this.width});
  final double? width;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 0.6,
      duration: const Duration(milliseconds: 800),
      child: Container(
        height: 14,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

class _QuestionCardError extends StatelessWidget {
  const _QuestionCardError({
    required this.studentId,
    required this.courseId,
    required this.lesson,
  });

  final String studentId;
  final String courseId;
  final int lesson;

  @override
  Widget build(BuildContext context) {
    return QuestionNotificationCard(
      questionText: 'Unable to load course name',
      studentId: studentId,
      courseId: courseId,
      lesson: lesson,
    );
  }
}