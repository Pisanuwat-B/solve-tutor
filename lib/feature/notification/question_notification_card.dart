import 'package:flutter/material.dart';

class QuestionNotificationCard extends StatelessWidget {
  final String questionName;
  final String studentName;
  final String courseName;
  final String? courseImageUrl; // nullable → fall back to local asset
  final int lesson;
  final int pageNo;

  const QuestionNotificationCard({
    super.key,
    required this.questionName,
    required this.studentName,
    required this.courseName,
    required this.lesson,
    required this.pageNo,
    this.courseImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Left: image
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.3,
              height: 100,
              child: courseImageUrl != null && courseImageUrl!.isNotEmpty
                  ? Image.network(courseImageUrl!, fit: BoxFit.cover)
                  : Image.asset('assets/images/default_course.png', fit: BoxFit.cover),
            ),
          ),

          // Right: info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 12.0, top: 10, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    questionName.isEmpty ? 'UNNAMED QUESTION From: $studentName' : questionName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text("Student: $studentName"),
                  Text("Course: $courseName"),
                  Row(
                    children: [
                      Text("Lesson: $lesson"),
                      const SizedBox(width: 20),
                      Text("Page: $pageNo"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
