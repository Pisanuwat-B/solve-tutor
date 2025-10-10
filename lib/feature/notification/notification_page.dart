import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/constants/theme.dart';
import 'package:solve_tutor/feature/notification/question_notification_card.dart';
import 'package:solve_tutor/feature/notification/record_answer.dart';
import 'package:solve_tutor/feature/notification/student_provider.dart';
import 'package:solve_tutor/feature/notification/view_question.dart';
import 'package:solve_tutor/widgets/sizer.dart';

import '../../firebase/database.dart';
import '../calendar/controller/create_course_controller.dart';
import '../calendar/model/course_model.dart';
import '../calendar/model/student_model.dart';
import 'notification_provider.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {

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
          final questionId = data['id'] as String;
          final courseId  = data['courseId'] as String;
          final studentId = data['studentId'] as String;
          final lessonId  = int.tryParse('${data['lessonId']}') ?? 0;
          final pageNo    = int.tryParse('${data['pageNo']}') ?? 0;
          final questionName = (data['questionName'] as String?) ?? '';

          final courseController = context.read<CourseController>();
          final studentProvider  = context.read<StudentProvider>();

          // Fetch both in parallel
          final future = Future.wait([
            courseController.getCourseById(courseId),       // CourseModel
            studentProvider.fetchStudentById(studentId),    // StudentModel?
          ]);

          return FutureBuilder<List<dynamic>>(
            future: future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                // skeleton while loading
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError || !snap.hasData) {
                return const ListTile(title: Text('Failed to load notification data'));
              }

              final course  = snap.data![0] as CourseModel;
              final student = snap.data![1] as StudentModel?;
              final courseName     = course.courseName ?? 'Unknown Course';
              final courseImageUrl = course.thumbnailUrl; // may be null
              final studentName    = student?.name ?? 'Unknown Student';

              // Resolve the lesson object now (so ViewQuestion can use it directly)
              final lesson = course.lessons?.firstWhere(
                    (l) => l.lessonId == lessonId,
                orElse: () => Lessons(lessonId: lessonId, lessonName: "Unknown"),
              );

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewQuestion(
                          questionId: questionId,
                          course: course,
                          lesson: lesson!,
                          studentId: studentId,
                          studentName: studentName,
                          questionName: questionName,
                          solvepadId: data['solvepadId'],
                        ),
                      ),
                    );
                  },
                  child: QuestionNotificationCard(
                    questionName: questionName,
                    studentName: studentName,
                    courseName: courseName,
                    courseImageUrl: courseImageUrl,
                    lesson: lessonId,
                    pageNo: pageNo,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
