import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/constants/theme.dart';
import 'package:solve_tutor/feature/notification/question_notification_card.dart';
import 'package:solve_tutor/feature/notification/record_answer.dart';
import 'package:solve_tutor/widgets/sizer.dart';

import '../calendar/controller/create_course_controller.dart';
import '../calendar/model/course_model.dart';
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
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () async {
                final courseId = data['courseId'];
                final studentId = data['studentId'];
                final lessonId = int.tryParse(data['lessonId'].toString()) ?? 0;

                // Get CourseModel from provider
                final courseController = Provider.of<CourseController>(context, listen: false);
                final course = await courseController.getCourseById(courseId);

                final lesson = course.lessons?.firstWhere(
                      (l) => l.lessonId == lessonId,
                  orElse: () => Lessons(lessonId: lessonId, lessonName: "Unknown"),
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecordAnswer(
                      course: course,
                      lesson: lesson!,
                      studentId: studentId,
                      questionText: data['questionText'],
                    ),
                  ),
                );
              },
              child: QuestionNotificationCard(
                questionText: data['questionText'],
                studentId: data['studentId'],
                courseId: data['courseId'],
                lesson: data['lessonId'],
              ),
            ),
          );
        },
      ),
    );
  }
}
