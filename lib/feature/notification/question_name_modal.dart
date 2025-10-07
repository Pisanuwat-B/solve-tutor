import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../constants/theme.dart';
import '../calendar/constants/custom_colors.dart';
import '../calendar/constants/custom_styles.dart';

class QuestionNameModal extends StatefulWidget {

  const QuestionNameModal({
    super.key,
  });

  @override
  State<QuestionNameModal> createState() => _QuestionNameModalState();
}

class _QuestionNameModalState extends State<QuestionNameModal> {
  final TextEditingController _textController = TextEditingController();

  bool _submitted = false;

  @override
  void dispose() {
    _textController.dispose(); // Always dispose controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 400, // Adjust max width for responsiveness
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: _buildQuestionForm(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Expanded(
              child: Center(
                child: Text(
                  "คำถามนี้ยังไม่มีชื่อ กรุณาตั้งชื่อ",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(Icons.close, color: Colors.black),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 10),
        const Text("ตั้งชื่อคำถามนี้ว่า: "),
        const SizedBox(height: 10),
        SizedBox(
          width: 200,
          child: TextFormField(
            controller: _textController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              fillColor: Colors.grey.shade100,
              filled: true,
              hintText: "ชื่อคำถามนี้",
              contentPadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: const BorderSide(color: primaryColor, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: const BorderSide(color: Colors.transparent, width: 1),
              ),
            ),
            onEditingComplete: () => FocusScope.of(context).unfocus(),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 150,
          height: 40,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CustomColors.greenPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onPressed: () async {
              // final questionText = _textController.text.trim();
              // if (questionText.isEmpty) return;
              //
              // log('Question text: $questionText');
              // log('Page number: ${widget.pageNo}');
              // log('Course ID: ${widget.courseId}');
              // log('Lesson ID: ${widget.lessonId}');
              // log('Tutor ID: ${widget.tutorId}');
              // log('Student ID: ${widget.studentId}');
              //
              // try {
              //   await FirebaseFirestore.instance.collection('question_market').add({
              //     'questionText': questionText,
              //     'courseId': widget.courseId,
              //     'lessonId': widget.lessonId,
              //     'pageNo': widget.pageNo,
              //     'tutorId': widget.tutorId,
              //     'studentId': widget.studentId,
              //     'timestamp': FieldValue.serverTimestamp(),
              //   });
              //
              //   setState(() {
              //     _submitted = true;
              //   });
              // } catch (e) {
              //   log('Failed to save question: $e');
              //   // Optionally show a snack bar or error dialog
              // }

              setState(() {
                _submitted = true;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('ส่งคำถาม', style: CustomStyles.bold14White),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward,
                  color: CustomColors.whitePrimary,
                  size: 20.0,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

}
