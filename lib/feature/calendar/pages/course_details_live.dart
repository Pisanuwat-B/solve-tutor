import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/feature/calendar/constants/constants.dart';
import 'package:solve_tutor/feature/calendar/controller/create_course_live_controller.dart';
import 'package:solve_tutor/feature/calendar/helper/utility_helper.dart';
import 'package:solve_tutor/feature/calendar/model/course_model.dart';
import 'package:solve_tutor/feature/calendar/model/student_model.dart';
import 'package:solve_tutor/feature/calendar/widgets/alert_overlay.dart';
import 'package:solve_tutor/feature/calendar/widgets/dropdown.dart';
import 'package:solve_tutor/feature/calendar/widgets/format_date.dart';
import 'package:solve_tutor/feature/calendar/widgets/sizebox.dart';
import 'package:solve_tutor/firebase/database.dart';

import '../../live_classroom/components/close_dialog.dart';
import 'my_course_live.dart';

class CourseDetailsLive extends StatefulWidget {
  const CourseDetailsLive({
    Key? key,
  }) : super(key: key);

  @override
  State<CourseDetailsLive> createState() => _CourseDetailsLiveState();
}

class _CourseDetailsLiveState extends State<CourseDetailsLive> {
  final _util = UtilityHelper();
  var courseController = CourseLiveController();
  FirebaseService dbService = FirebaseService();
  List<StudentModel> filterStudent = [];
  String textErrorAddStudent = '';
  DateTime? startTime;
  DateTime? endTime;

  @override
  void initState() {
    super.initState();
    courseController = context.read<CourseLiveController>();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      S.h(32.0),
                      Consumer<CourseLiveController>(
                          builder: (_, controller, child) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TextFormField(
                            controller: controller.courseNameTextEditing,
                            decoration: InputDecoration(
                              labelText: 'ชื่อคอร์ส',
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                              ),
                              suffix: Text(
                                  '${controller.courseNameTextEditing.text.length}/70'),
                            ),
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(70),
                            ],
                            onChanged: (value) {
                              controller.courseData?.courseName = value;
                            },
                          ),
                        );
                      }),
                      Consumer<CourseLiveController>(
                          builder: (_, controller, child) {
                        return Row(
                          children: [
                            Expanded(
                              child: Dropdown(
                                selectedValue: controller.courseData?.levelId,
                                items: controller.levels,
                                hintText: '-- ระดับชั้นปีการศึกษา --',
                                onChanged: (value) {
                                  debugPrint(value);
                                  controller.courseData?.levelId = value ?? '';
                                  setState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Dropdown(
                                selectedValue: controller.courseData?.subjectId,
                                items: controller.subjects,
                                hintText: '-- เลือกหมวดหมู่ --',
                                onChanged: (value) {
                                  debugPrint(value);
                                  controller.courseData?.subjectId =
                                      value ?? '';
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        );
                      }),
                      S.h(16.0),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "อัพโหลดรูป Thumbnail*",
                          style: _util.isTablet()
                              ? CustomStyles.bold22Black363636
                              : CustomStyles.bold18Black363636,
                        ),
                      ),
                      S.h(10),
                      Consumer<CourseLiveController>(
                          builder: (_, controller, child) {
                        File? file = controller.pickedImage;
                        Widget imageProvider = const SizedBox();
                        if (file != null) {
                          imageProvider = SizedBox(
                            height: 200,
                            width: double.infinity,
                            child: Image.file(
                              file,
                              fit: BoxFit.cover,
                            ),
                          );
                        }
                        return InkWell(
                          onTap: () async {
                            Alert.showOverlay(
                              loadingWidget: Alert.getOverlayScreen(),
                              asyncFunction: () async {
                                await controller.openGallery(
                                    context: context,
                                    courseData: courseController.courseData ??
                                        CourseModel());
                              },
                              context: context,
                            );
                          },
                          child: DottedBorder(
                              color: CustomColors.gray878787.withOpacity(0.5),
                              strokeWidth: 2,
                              dashPattern: const [5, 5],
                              padding: const EdgeInsets.all(20),
                              child: SizedBox(
                                  height: 200,
                                  width: double.infinity,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (controller.pickedImage != null) ...[
                                        imageProvider
                                      ] else if (courseController.courseData
                                              ?.thumbnailUrl?.isNotEmpty ==
                                          true) ...[
                                        CachedNetworkImage(
                                          height: 200,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          imageUrl: courseController
                                                  .courseData?.thumbnailUrl ??
                                              '',
                                          placeholder: (context, url) =>
                                              const Center(
                                                  child:
                                                      CircularProgressIndicator()),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
                                        ),
                                      ] else ...[
                                        Text(
                                          "อัพโหลดรูป",
                                          style: CustomStyles.reg32gray878787,
                                        ),
                                        S.h(10),
                                        Text(
                                          "ขนาดรูปที่แนะนำ 272px x 379px",
                                          style: CustomStyles.reg12Gray878787,
                                        ),
                                      ]
                                    ],
                                  ))),
                        );
                      }),
                      S.h(20),
                      _textArea(courseController.courseRecommendTextEditing,
                          title: "แนะนำคอร์สเรียน*",
                          // labelText: 'คำอธิบายคอร์ส',
                          hintText: 'รายละเอียด...'),
                      S.h(20),
                      _textArea(courseController.courseDetailTextEditing,
                          title: "รายละเอียดคอร์ส*", hintText: 'รายละเอียด...'),
                      S.h(20),
                      _managementStudent(),
                      S.h(20),
                      _deleteCourse(),
                      // ],
                      S.h(100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topicText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: _util.isTablet()
              ? CustomStyles.bold22Black363636
              : CustomStyles.bold18Black363636,
        ),
      ),
    );
  }

  Widget _textArea(TextEditingController controller,
      {String? title, String? labelText, String? hintText}) {
    return Column(
      children: [
        _topicText(title ?? ''),
        SizedBox(
          child: TextFormField(
            style: CustomStyles.med14Black363636,
            controller: controller,
            maxLines: 5,
            maxLength: 200,
            onChanged: (value) {
              if (title == 'แนะนำคอร์สเรียน*') {
                courseController.courseData?.recommendText = value;
              }
              if (title == 'รายละเอียดคอร์ส*') {
                courseController.courseData?.detailsText = value;
              }
            },
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
                hintText: hintText,
                hintStyle:
                    CustomStyles.med16Black363636.copyWith(color: Colors.grey),
                labelText: labelText,
                labelStyle: CustomStyles.reg14Gray878787,
                alignLabelWithHint: true,
                enabledBorder: const OutlineInputBorder(
                  // width: 0.0 produces a thin "hairline" border
                  borderSide:
                      BorderSide(color: CustomColors.grayE5E6E9, width: 1),
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4.0)),
                )),
          ),
        ),
      ],
    );
  }

  Widget _managementStudent() {
    return Consumer<CourseLiveController>(builder: (_, course, child) {
      return Column(
        children: [
          _topicText('จัดการนักเรียน'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'รายชื่อนักเรียนที่ลงทะเบียน',
                    style: CustomStyles.med14Black363636,
                  ),
                  Text(
                    'ทั้งหมด ${course.courseData?.studentIds?.length ?? 0} คน',
                    style: CustomStyles.med14Black363636,
                  ),
                ],
              ),
              _buildButtonAddStudent(context)
            ],
          ),
          Column(
            children: List.generate(
              course.courseData?.studentDetails?.length ?? 0,
              (index) => Card(
                elevation: 5,
                child: ListTile(
                    title: Text(
                      'Name : ${course.courseData?.studentDetails?[index].name}',
                      style: CustomStyles.med14Black363636,
                    ),
                    subtitle: (_util.isTablet())
                        ? Row(
                            children: [
                              Text(
                                  'ID: ${course.courseData?.studentDetails?[index].id}'),
                              S.w(20),
                              // Text(
                              //     'ลงทะเบียนวันที่: ${FormatDate.dt(course.courseData?.studentDetails?[index].createTime)}'),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ชื่อ-นามสกุล: ${course.courseData?.studentDetails?[index].name}',
                                style: CustomStyles.med14Black363636,
                              ),
                              S.w(20),
                              Text(
                                'ลงทะเบียนวันที่: ${FormatDate.dt(course.courseData?.studentDetails?[index].createTime)}',
                                style: CustomStyles.med14Black363636,
                              ),
                            ],
                          ),
                    trailing: InkWell(
                      onTap: () {
                        course.courseData?.studentIds?.remove(
                            course.courseData?.studentDetails?[index].id);
                        course.courseData?.studentDetails
                            ?.remove(course.courseData?.studentDetails?[index]);
                        setState(() {});
                      },
                      child: const Icon(
                        Icons.delete,
                        color: CustomColors.redB71C1C,
                        size: 20,
                      ),
                    )),
              ),
            ),
          )
        ],
      );
    });
  }

  Widget _deleteCourse() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _topicText('ลบคอร์สเรียน'),
      Text(
        'ข้อมูลทั้งหมดของคอร์สเรียนนี้จะถูกลบและไม่สามารถกู้คืนข้อมูลได้ หลังจากลบแล้วนักเรียนที่ลงทะเบียนจะไม่สามารถเข้าถึง คอร์สรียนได้อีก',
        style: CustomStyles.blod16gray878787,
      ),
      _buttonDelete()
    ]);
  }

  Widget _buttonDelete() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton.icon(
        icon: const Icon(
          Icons.delete,
          color: CustomColors.redB71C1C,
        ),
        label: Text(
          "ลบคอร์สเรียน",
          style: CustomStyles.med14White.copyWith(
            color: CustomColors.redB71C1C,
          ),
        ),
        onPressed: () async {
          showCloseDialog(
            context,
            () async {
              await Alert.showOverlay(
                loadingWidget: Alert.getOverlayScreen(),
                asyncFunction: () async {
                  try {
                    await context.read<CourseLiveController>().deleteCourseById(
                          id: courseController.courseData?.id ?? '',
                        );
                  } catch (e) {
                    rethrow;
                  }
                },
                context: context,
              );
              if (!mounted) return;
              Navigator.of(context).pop();
            },
            title: 'คุณกำลังจะลบคอร์สเรียนนี้',
            detail: 'คอร์สเรียนที่ถูกลบไปแล้ว ไม่สามารถกู้คืนได้',
            confirm: 'ลบคอร์ส',
            cancel: 'ยกเลิก',
          );
          // ignore: use_build_context_synchronously
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: CustomColors.white,
          shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.circular(10.0)),
        ),
      ),
    );
  }

  Widget _buildButtonAddStudent(context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add),
        label: Text(
          CustomStrings.addStutdent,
          style: CustomStyles.med14White.copyWith(
            color: CustomColors.white,
          ),
        ),
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => _findStudent(),
          );
          setState(() {});
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: CustomColors.greenPrimary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
      ),
    );
  }

  _findStudent() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AlertDialog(
        title: Text(
          'เพิ่ม ID นักเรียน',
          style: CustomStyles.med18Black363636,
        ),
        content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: courseController.findStudentController,
                            textAlignVertical: TextAlignVertical.center,
                            maxLines: 1,
                            style: CustomStyles.med14Black363636,
                            decoration: InputDecoration(
                              hintText: 'ค้นหา...',
                              hintStyle: CustomStyles.med14Black363636
                                  .copyWith(color: CustomColors.grayCFCFCF),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              filterStudent.clear();
                              textErrorAddStudent = '';
                              setState(() {});
                            },
                          ),
                        ),
                        S.w(20),
                        TextButton(
                          onPressed: () async {
                            var user = await dbService.getUserById(
                                courseController.findStudentController.text);
                            if (user['role'] != 'student') return;
                            filterStudent.add(StudentModel(
                                id: user['id'],
                                name: user['name'],
                                image: user['image']));
                            setState(() {});
                          },
                          child: Text(
                            'ค้นหา',
                            style: CustomStyles.med32greenPrimary.copyWith(
                              fontSize: _util.addMinusFontSize(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    S.h(20),
                    if (filterStudent.isNotEmpty) ...[
                      Card(
                        elevation: 5,
                        child: ListTile(
                            title: Text(filterStudent.first.name ?? ''),
                            trailing: InkWell(
                              onTap: () {
                                courseController.courseData?.studentIds ??= [];
                                courseController.courseData?.studentDetails ??=
                                    [];
                                if (!(courseController.courseData?.studentIds
                                        ?.contains(filterStudent.first.id) ??
                                    false)) {
                                  filterStudent.first.createTime =
                                      DateTime.now();
                                  courseController.courseData?.studentIds
                                      ?.add(filterStudent.first.id ?? '');
                                  courseController.courseData?.studentDetails
                                      ?.add(filterStudent.first);
                                  courseController.findStudentController
                                      .clear();
                                  setState(() {});
                                  Navigator.pop(context);
                                } else {
                                  textErrorAddStudent = 'ถูกเพิ่มไปเเล้ว';
                                  setState(() {});
                                }
                              },
                              child: const Icon(
                                Icons.add,
                                color: CustomColors.greenPrimary,
                                size: 30,
                              ),
                            )),
                      ),
                      if (textErrorAddStudent.isNotEmpty) ...[
                        S.h(10),
                        Text(
                          textErrorAddStudent,
                          style: CustomStyles.reg14RedF44336,
                        ),
                      ]
                    ],
                    S.h(20),
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CustomColors.white,
                          shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                color: CustomColors.grayE5E6E9,
                              ),
                              borderRadius: BorderRadius.circular(10.0)),
                        ),
                        child: Text(
                          "ปิดหน้านี้",
                          style: CustomStyles.med14Gray878787,
                        ),
                      ),
                    )
                  ]),
            ),
          );
        }),
      ),
    );
  }
}
