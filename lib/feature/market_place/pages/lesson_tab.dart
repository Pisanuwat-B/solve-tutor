import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/feature/calendar/constants/constants.dart';
import 'package:solve_tutor/feature/calendar/controller/create_course_controller.dart';
import 'package:solve_tutor/feature/calendar/helper/utility_helper.dart';
import 'package:solve_tutor/feature/calendar/model/chapter_model.dart';
import 'package:solve_tutor/feature/calendar/model/document_model.dart';
import 'package:solve_tutor/feature/calendar/pages/dialog_file_manager_live.dart';
import 'package:solve_tutor/feature/calendar/pages/preview_document.dart';
import 'package:solve_tutor/feature/calendar/widgets/widgets.dart';
import 'package:solve_tutor/feature/market_place/pages/dialog_file_manager.dart';

enum Select { form, quiz, video }

class LessonTab extends StatefulWidget {
  const LessonTab({
    Key? key,
  }) : super(key: key);

  @override
  State<LessonTab> createState() => _LessonTabState();
}

class _LessonTabState extends State<LessonTab> {
  final _util = UtilityHelper();
  var courseController = CourseController();
  TextEditingController courseName = TextEditingController();
  TextEditingController chapterName = TextEditingController();
  TextEditingController chapterDetail = TextEditingController();
  Select selected = Select.form;
  List<dynamic> chapterList = [];
  Map<String, String> chapterIdMapGlobal = {};
  Map<String, List<ChapterPart>> chapterPartsMap = {};
  List<dynamic> subjects = [];
  List<dynamic> chapters = [];
  String? selectedSubject;
  String? selectedChapter;
  String? selectedChapterId;

  @override
  void initState() {
    super.initState();
    courseController = Provider.of<CourseController>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseController>(builder: (_, controller, child) {
      return GestureDetector(
        onTap: () => _util.hideKeyboard(context),
        child: Scaffold(
          backgroundColor: const Color(0xffFFFFFF),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: courseController.courseData?.document != null
                      ? _docLesson(courseController.courseData?.document)
                      : courseController.courseData?.document != null
                          ? _docLesson(
                              courseController.courseData?.document,
                            )
                          : _addLesson(),
                ),
                S.h(32.0),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _docLesson(DocumentModel? document) {
    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "เอกสารประกอบการเรียน",
                style: _util.isTablet()
                    ? CustomStyles.bold22Black363636
                    : CustomStyles.bold18Black363636,
              ),
              if (_util.isTablet() == false) ...[
                _buttonChangeDoc(),
              ]
            ],
          ),
          S.h(10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (courseController.courseData?.courseType == 'vdo') ...[
                Row(
                  children: [iconSolveVdo()],
                )
              ],
              if (courseController.courseData?.courseType == 'pad') ...[
                Row(
                  children: [iconSolvePad()],
                )
              ],
              S.w(10),
              Text(
                "เอกสารประกอบการเรียน: ${courseController.courseData?.document != null ? courseController.courseData?.document?.data?.documentName : courseController.courseData?.document?.data?.documentName}",
                textAlign: TextAlign.center,
                style: CustomStyles.med14Black363636
                    .copyWith(fontSize: _util.addMinusFontSize(18)),
              ),
              const SizedBox(width: 20),
              Expanded(child: Container()),
              if (_util.isTablet()) ...[
                _buttonChangeDoc(),
              ],
            ],
          ),
          S.h(20),
          Expanded(
            child: GridView(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2 / 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 8,
              ),
              children: List.generate(
                document?.data?.docFiles?.length ?? 0,
                (index) {
                  return InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PreviewDocument(
                            images: document?.data?.docFiles ?? [],
                            index: index,
                            name: document?.data?.documentName ?? '',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5.0),
                        border: Border.all(color: Colors.grey),
                        image: document?.data?.docFiles != null
                            ? DecorationImage(
                                image: NetworkImage(
                                    document?.data?.docFiles?[index] ?? ''),
                                fit: BoxFit.cover,
                              )
                            : const DecorationImage(
                                image: AssetImage(
                                  ImageAssets.emptyCourse,
                                ),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addLesson() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "เอกสารประกอบการเรียน",
          style: CustomStyles.med14Black363636.copyWith(fontSize: 22),
        ),
        S.h(10),
        Text(
          "เอกสารประกอบการเรียนเป็นเอกสารที่คุณใช้สำหรับบันทึกบทเรียน\nนักเรียนของคุณจะสามารถเปิดอ่านเอกสารนี้ และจดบันทึกบนเอกสาระหว่างเรียนได้",
          textAlign: TextAlign.center,
          style: CustomStyles.med14Gray878787,
        ),
        S.w(20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_buttonStepCreateDoc(), S.w(24), _buttonChoose()],
        ),
      ],
    );
  }

  Widget _buttonStepCreateDoc() {
    return ElevatedButton.icon(
      icon: const Icon(
        Icons.question_answer,
        size: 20,
        color: Colors.grey,
      ),
      label: Text(
        "ขั้นตอนการสร้างเอกสาร",
        style: CustomStyles.med14White.copyWith(
          color: CustomColors.gray878787,
        ),
      ),
      onPressed: () async {
        // final result = await showDialog(
        //     context: context,
        //     builder: ((context) => DialogFileManager(
        //           tutorId: tutorId,
        //         )));
        // if (result != null) {
        //   widget.document = null;
        //   setState(() {});
        // }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: CustomColors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
    );
  }

  Widget _buttonChoose() {
    return ElevatedButton.icon(
      icon: const Icon(
        Icons.add,
        size: 20,
        color: Colors.white,
      ), //Button icon
      label: Text(
        "เลือกเอกสาร",
        style: CustomStyles.med14White,
      ),
      onPressed: () async {
        final String documentId = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DialogFileManager(
              tutorId: courseController.courseData?.tutorId ?? '',
            ),
          ),
        );
        if (documentId.isNotEmpty) {
          // ignore: use_build_context_synchronously
          // await Alert.showOverlay(
          //   asyncFunction: () async {
          //     await courseController
          //         .getCourseById(courseController.courseData?.id ?? '');
          //   },
          //   context: context,
          //   loadingWidget: Alert.getOverlayScreen(),
          // );
          // setState(() {});
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: CustomColors.green20B153,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
    );
  }

  Widget _buttonChangeDoc() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: CustomColors.green20B153,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DialogFileManager(
              tutorId: courseController.courseData?.tutorId ?? '',
            ),
          ),
        );
        setState(() {});
      },
      child: Text(
        "เปลี่ยนเอกสาร",
        style: CustomStyles.med14White,
      ),
    );
  }
}
