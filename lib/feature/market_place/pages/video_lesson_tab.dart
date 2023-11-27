import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart' hide ReorderableList;
import 'package:flutter/services.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:path_provider/path_provider.dart';

import 'package:provider/provider.dart';
import 'package:solve_tutor/feature/calendar/constants/constants.dart';
import 'package:solve_tutor/feature/calendar/controller/create_course_controller.dart';
import 'package:solve_tutor/feature/calendar/helper/utility_helper.dart';
import 'package:solve_tutor/feature/calendar/model/course_model.dart';
import 'package:solve_tutor/feature/calendar/model/document_model.dart';
import 'package:solve_tutor/feature/calendar/widgets/alert_overlay.dart';
import 'package:solve_tutor/feature/calendar/widgets/format_date.dart';
import 'package:solve_tutor/feature/calendar/widgets/widgets.dart';
import 'package:solve_tutor/feature/cheet/pages/alert_other.dart';
import 'package:solve_tutor/feature/market_place/pages/dialog_file_manager.dart';
import 'package:solve_tutor/feature/market_place/pages/record_course.dart';
import 'package:solve_tutor/feature/market_place/pages/reorderable_view_page.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../firebase/database.dart';
import '../../live_classroom/utils/responsive.dart';
import '../../profile/components/webview.dart';

class VideoLessonTab extends StatefulWidget {
  @override
  _VideoLessonTabState createState() => _VideoLessonTabState();
}

class ItemData {
  ItemData(this.title, this.key);

  final String title;

  // Each item in reorderable list needs stable and unique key
  final Key key;
}

enum DraggingMode {
  iOS,
  android,
}

class _VideoLessonTabState extends State<VideoLessonTab> {
  var courseController = CourseController();
  FirebaseService dbService = FirebaseService();
  static final _util = UtilityHelper();
  String tutorialUrl = '';
  // List<ItemData> _items = [];
  // var controller = ExpansionTileController();

  @override
  void initState() {
    super.initState();
    courseController = Provider.of<CourseController>(context, listen: false);
    getTutUrl();
  }

  void getTutUrl() async {
    tutorialUrl = await dbService.getRecordCourseTutorialUrl();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Consumer<CourseController>(builder: (_, controller, child) {
            return Column(
              children: [
                _docLesson(courseController.courseData?.document),
                if (courseController.courseData?.courseType == 'vdo') ...[
                  _alertUploadVDO()
                ],
                if (courseController.courseData?.courseType == 'pad') ...[
                  _alertUploadPAD(),
                ],
                S.h(20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buttonSortLesson(),
                    _buttonAddVDO(),
                  ],
                ),
                lists()
              ],
            );
          }),
        ),
      ),
    );
  }

  String _getIdImage(String imageUrl) {
    var urlToken = imageUrl.split('?');
    var url = urlToken[0].split('/');
    var filePath = url[url.length - 1].replaceAll("%2F", "/");
    var name = filePath.split('/');
    return name[name.length - 1];
  }

  String _getTimeStamp(String imageUrl) {
    var url = imageUrl.split('token=');
    if (url.last.isNotEmpty) {
      return url.last;
    } else {
      return '0';
    }
  }

  Widget lists() {
    return Consumer<CourseController>(builder: (_, controller, child) {
      return Column(
        children: List.generate(
            courseController.courseData?.lessons?.length ?? 0, (index) {
          var lesson = courseController.courseData?.lessons?[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Card(
              color: CustomColors.grayEFF0F2,
              elevation: 4,
              child: Column(
                children: [
                  _headBuilder(lesson, index),
                  if (lesson?.isExpanded == true) ...[
                    if (courseController.courseData?.courseType == 'vdo') ...[
                      _bodyBuilderVDO(lesson),
                    ],
                    if (courseController.courseData?.courseType == 'pad') ...[
                      _bodyBuilderPAD(lesson),
                    ],
                    _buttonDelete(lesson, index),
                  ],
                ],
              ),
            ),
          );
        }),
      );
    });
  }

  _buttonDeleteVideo(Lessons? lesson) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: () async {
              await showDialog(
                context: context,
                builder: (context) => AlertDeleteVideo(onTap: () async {
                  await Alert.showOverlay(
                    loadingWidget: Alert.getOverlayScreen(),
                    asyncFunction: () async {
                      try {
                        final id = _getIdImage(lesson?.media ?? '');
                        await courseController.deleteFileById(
                          tutorId: courseController.courseData?.tutorId ?? '',
                          documentId: courseController.courseData?.id ?? '',
                          fileId: id,
                        );
                        lesson?.media = '';
                        await courseController
                            .updateCourseDetails(courseController.courseData);
                      } catch (e) {
                        Navigator.of(context).pop();
                        rethrow;
                      }
                    },
                    context: context,
                  );
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                }),
              );

              setState(() {});
            },
            child: Text(
              'ลบวิดิโอ',
              style: CustomStyles.reg16redF44336,
            ),
          )),
    );
  }

  _buttonDelete(Lessons? lesson, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: () async {
              await showDialog(
                  context: context,
                  builder: (context) => AlertDeleteLesson(
                        onTap: () async {
                          try {
                            await Alert.showOverlay(
                              loadingWidget: Alert.getOverlayScreen(),
                              asyncFunction: () async {
                                if (lesson?.media?.isNotEmpty == true) {
                                  final id = _getIdImage(lesson?.media ?? '');
                                  await courseController.deleteFileById(
                                    tutorId:
                                        courseController.courseData?.tutorId ??
                                            '',
                                    documentId:
                                        courseController.courseData?.id ?? '',
                                    fileId: id,
                                  );
                                  lesson?.media = '';
                                }
                                courseController.courseData?.lessons
                                    ?.removeAt(index);
                                await courseController.updateCourseDetails(
                                    courseController.courseData);
                              },
                              context: context,
                            );
                          } catch (e) {
                            Navigator.of(context).pop();
                            rethrow;
                          }
                          Navigator.of(context).pop();
                        },
                      ));

              setState(() {});
            },
            child: Text(
              'ลบบทเรียน',
              style: CustomStyles.reg16redF44336,
            ),
          )),
    );
  }

  _headBuilder(Lessons? lesson, int index) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          if (lesson?.isExpanded == false) ...[
            const Icon(
              Icons.arrow_drop_down_outlined,
              color: CustomColors.gray878787,
            ),
            Text(
              "บทที่ # ${index + 1}:",
              style: CustomStyles.blod16gray878787,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "${lesson?.lessonName}",
                style:
                    CustomStyles.blod16gray878787.copyWith(color: Colors.black),
              ),
            ),
            _buttonEdit(lesson, index)
          ],
          if (lesson?.isExpanded == true) ...[
            Text(
              "บทที่ # ${lesson?.lessonId}:",
              style: CustomStyles.blod16gray878787,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _textField(lesson),
            ),
            const SizedBox(width: 10),
            _buttonSave(lesson, index)
          ]
        ],
      ),
    );
  }

  Future<Uint8List> genThumbnail(Lessons? lesson) async {
    Uint8List bytes;
    final thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: '${lesson?.media}?download',
          thumbnailPath: (await getTemporaryDirectory()).path,
          imageFormat: ImageFormat.PNG,
          maxHeight:
              64, // specify the height of the thumbnail, let the width auto-scaled to keep the source aspect ratio
          quality: 75,
        ) ??
        '';
    log("thumbnail file is located: $thumbnailPath");

    final file = File(thumbnailPath);
    bytes = file.readAsBytesSync();
    // print(bytes);
    return bytes;
  }

  _bodyBuilderVDO(Lessons? lesson) {
    final id = _getIdImage(lesson?.media ?? '');
    final timeStamp = _getTimeStamp(lesson?.media ?? '');
    int time = int.parse(timeStamp);
    var dateTime = FormatDate.dt(DateTime.fromMillisecondsSinceEpoch(time));
    return lesson?.media?.isNotEmpty == true
        ? FutureBuilder<Uint8List>(
            future: genThumbnail(lesson),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      decoration: const BoxDecoration(
                        color: CustomColors.white,
                        borderRadius: BorderRadius.all(
                          Radius.circular(8.0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                height: _util.isTablet() ? 120 : 80,
                                width: _util.isTablet() ? 150 : 100,
                                child: Image.memory(snapshot.data,
                                    fit: BoxFit.cover),
                              ),
                              const Icon(
                                Icons.play_circle_fill,
                                size: 40,
                              )
                            ],
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(0.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    id,
                                    style: _util.isTablet()
                                        ? CustomStyles.bold22Black363636
                                            .copyWith(
                                            fontSize:
                                                _util.addMinusFontSize(18),
                                          )
                                        : CustomStyles.bold22Black363636
                                            .copyWith(
                                            fontSize:
                                                _util.addMinusFontSize(14),
                                          ),
                                  ),
                                  Text(
                                    'แก้ไขครั้งล่่าสุด: $dateTime',
                                    textAlign: TextAlign.center,
                                    style: CustomStyles.med14Gray878787,
                                  ),
                                  _buttonDeleteVideo(lesson),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                );
              } else if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.red,
                  child: Text(
                    "Error:\n${snapshot.error.toString()}",
                  ),
                );
              } else {
                return const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      CircularProgressIndicator(),
                    ]);
              }
            })
        : Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            color: CustomColors.white,
            child: Column(
              children: [
                Text(
                  'อัพโหลดวิดิโอ',
                  style: CustomStyles.bold22Black363636,
                ),
                const SizedBox(height: 20),
                Text(
                  'ประเภทไฟล์ที่รองรับ: .mov, .mp4, .wav\nขนาดไฟล์ไม่เกิน xxx MB, ความยาวไม่เกิน 2 ชั่วโมง',
                  textAlign: TextAlign.center,
                  style: CustomStyles.med14Gray878787,
                ),
                const SizedBox(height: 10),
                _buttonChooseFile(lesson),
              ],
            ),
          );
  }

  _bodyBuilderPAD(Lessons? lesson) {
    if (lesson?.media != null && lesson?.media != '') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        color: CustomColors.white,
        child: Column(
          children: [
            Text(
              'ดูบทเรียนที่คุณบันทึกไว้',
              style: CustomStyles.bold22Black363636,
            ),
            const SizedBox(height: 20),
            _buttonViewSolvepad(lesson!)
          ],
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        color: CustomColors.white,
        child: Column(
          children: [
            Text(
              'บันทึกบทเรียนด้วย SOLVEPAD',
              style: CustomStyles.bold22Black363636,
            ),
            const SizedBox(height: 20),
            Text(
              'แต่ละครั้งสามารถ คุณบันทึกบทเรียน',
              style: DefaultTextStyle.of(context).style,
              textAlign: TextAlign.center,
            ),
            Text(
              'ได้สูงสุด 30 นาที',
              style:
                  CustomStyles.med16Green.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              'หน้าจอขณะบันทึกจะถูกเปลี่ยนเป็นแนวนอน',
              textAlign: TextAlign.center,
              style: CustomStyles.med14Gray878787,
            ),
            const SizedBox(height: 10),
            if (!Responsive.isMobile(context)) _buttonRecordSolvepad(lesson!)
          ],
        ),
      );
    }
  }

// /medias/upload-files-course
  _textField(Lessons? lesson) {
    return Container(
      color: Colors.white,
      child: TextFormField(
        initialValue: lesson?.lessonName,
        decoration: InputDecoration(
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(8.0),
            ),
          ),
          suffix: Text('${lesson?.lessonName?.length ?? 0}/70'),
        ),
        inputFormatters: [
          LengthLimitingTextInputFormatter(70),
        ],
        onChanged: (value) {
          lesson?.lessonName = value;
          setState(() {});
        },
        onFieldSubmitted: (value) {
          lesson?.lessonName = value;
          setState(() {});
        },
      ),
    );
  }

  Widget _buttonAddVDO() {
    return ElevatedButton.icon(
      icon: const Icon(
        Icons.add,
        size: 20,
        color: Colors.white,
      ),
      label: Text(
        "เพิ่มบทเรียน",
        style: CustomStyles.med14White.copyWith(
          color: CustomColors.white,
        ),
      ),
      onPressed: () async {
        courseController.courseData?.lessons?.add(
          Lessons(
            lessonId: (courseController.courseData?.lessons?.length ?? 0) + 1,
            lessonName: '',
            media: '',
            isExpanded: false,
          ),
        );
        setState(() {});
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: CustomColors.greenPrimary,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
    );
  }

  int selectIndex = 0;
  Widget _buttonEdit(Lessons? lesson, int index) {
    return InkWell(
      onTap: () {
        courseController.courseData?.lessons
            ?.map((e) => e.isExpanded = false)
            .toList();
        courseController.courseData?.lessons?.elementAt(index).isExpanded =
            true;
        setState(() {});
      },
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8.0),
          color: Colors.white,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.edit,
          size: 22,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buttonSave(Lessons? lesson, int index) {
    return InkWell(
      onTap: () {
        if (lesson?.isExpanded == true) {
          lesson?.isExpanded = false;
          setState(() {});
        }
      },
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: CustomColors.greenPrimary,
          ),
          const SizedBox(width: 10),
          Text(
            'บันทึก',
            style: CustomStyles.reg14Green,
          ),
        ],
      ),
    );
  }

  Widget _buttonChooseFile(Lessons? lesson) {
    return ElevatedButton.icon(
      icon: const Icon(
        Icons.add,
        size: 20,
        color: Colors.white,
      ),
      label: Text(
        "เลือกไฟล์",
        style: CustomStyles.med14White.copyWith(
          color: CustomColors.white,
        ),
      ),
      onPressed: () async {
        String? videoUrl;
        await Alert.showOverlay(
            loadingWidget: Alert.getOverlayScreen(),
            context: context,
            asyncFunction: () async {
              videoUrl = await courseController.openFileVideo(
                  context: context,
                  courseData: courseController.courseData ?? CourseModel());
              lesson?.media = videoUrl ?? '';
              await courseController
                  .updateCourseDetails(courseController.courseData);
            });

        setState(() {});
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: CustomColors.greenPrimary,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
    );
  }

  Widget _buttonRecordSolvepad(Lessons lesson) {
    return ElevatedButton.icon(
      icon: const Icon(
        Icons.radio_button_checked_rounded,
        size: 20,
        color: Colors.white,
      ),
      label: Text(
        "เริ่มบันทึก",
        style: CustomStyles.med14White.copyWith(
          color: CustomColors.white,
        ),
      ),
      onPressed: () async {
        setState(() {
          lesson.isExpanded = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecordCourse(
              lesson: lesson,
              course: courseController.courseData!,
            ),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: CustomColors.redF44336,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
    );
  }

  Widget _buttonViewSolvepad(Lessons lesson) {
    return ElevatedButton.icon(
      icon: const Icon(
        Icons.play_arrow,
        size: 20,
        color: Colors.white,
      ),
      label: Text(
        "ดูคอร์สที่บันทึกไว้",
        style: CustomStyles.med14White.copyWith(
          color: CustomColors.white,
        ),
      ),
      onPressed: () async {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecordCourse(
              lesson: lesson,
              course: courseController.courseData!,
            ),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: CustomColors.greenPrimary,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
    );
  }

  Widget _buttonSortLesson() {
    return ElevatedButton(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReorderableViewPage(),
          ),
        );
        setState(() {});
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: CustomColors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/arrow_move.png',
            scale: 4,
            color: CustomColors.gray878787,
          ),
          const SizedBox(width: 20),
          Text(
            "เรียงลำดับเนื้อหา",
            style: CustomStyles.med14White.copyWith(
              color: CustomColors.gray363636,
            ),
          ),
        ],
      ),
    );
  }

  Widget _docLesson(DocumentModel? document) {
    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "เพิ่มบทเรียน",
            style: _util.isTablet()
                ? CustomStyles.bold22Black363636
                : CustomStyles.bold18Black363636,
          ),
          S.h(10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_util.isTablet() == false) ...[
                    Text(
                      "เอกสารประกอบการเรียน: ${courseController.courseData?.document?.data?.documentName ?? ''}",
                      textAlign: TextAlign.center,
                      style: CustomStyles.med14Black363636
                          .copyWith(fontSize: _util.addMinusFontSize(18)),
                    ),
                    docChange()
                  ]
                ],
              ),
              const SizedBox(width: 20),
              if (_util.isTablet()) ...[docChange()],
            ],
          ),
          S.h(20),
        ],
      ),
    );
  }

  Widget docChange() {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DialogFileManager(
              tutorId: courseController.courseData?.tutorId ?? '',
            ),
          ),
        );
      },
      child: Text(
        "เปลี่ยนเอกสาร",
        style: CustomStyles.med14White.copyWith(
          color: CustomColors.greenPrimary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _alertUploadVDO() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: CustomColors.grayCFCFCF,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8.0),
        color: CustomColors.grayEFF0F2,
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "อัพโหลดวิดิโอ",
                  style: CustomStyles.med14White.copyWith(
                      color: CustomColors.black,
                      fontSize: _util.addMinusFontSize(16)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Lorem ipsum dolor sit amet consectetur. Ullamcorper eget nulla neque viverra lacus consequat at egestas scelerisque. Nunc accumsan cras penatibus qua",
                    textAlign: TextAlign.center,
                    style: CustomStyles.med14White.copyWith(
                      color: CustomColors.gray363636,
                    ),
                  ),
                ),
                S.h(10),
                iconHowtoUploadVDO()
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertUploadPAD() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: CustomColors.grayCFCFCF,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8.0),
        color: CustomColors.grayEFF0F2,
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "บันทึกบทเรียนด้วย SOLVEPAD",
                  style: CustomStyles.med14White.copyWith(
                      color: CustomColors.black,
                      fontSize: _util.addMinusFontSize(18)),
                ),
                Text(
                  "คุณสามารถบันทึกการสอนขณะพูดและเขียนอธิบายบนชีทได้ผ่าน SOLVEPAD\nแนะนำให้บันทึกบทเรียนแยกเป็นหลายๆบทเรียน บทเรียนละไม่เกิน 30นาที",
                  textAlign: TextAlign.center,
                  style: CustomStyles.med14White.copyWith(
                    color: CustomColors.gray363636,
                  ),
                ),
                S.h(10),
                iconHowtoUploadPAD(context, tutorialUrl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget iconHowtoUploadVDO() {
  return ElevatedButton.icon(
    icon: const Icon(
      Icons.play_circle,
      size: 20,
      color: Colors.grey,
    ),
    label: Text(
      "ขั้นตอนการสร้างเอกสาร",
      style: CustomStyles.med14White.copyWith(
        color: CustomColors.gray878787,
      ),
    ),
    onPressed: () async {},
    style: ElevatedButton.styleFrom(
      backgroundColor: CustomColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
    ),
  );
}

Widget iconHowtoUploadPAD(BuildContext context, String tutorialUrl) {
  return ElevatedButton.icon(
    icon: const Icon(
      Icons.play_circle,
      size: 20,
      color: Colors.grey,
    ),
    label: Text(
      "ดูขั้นตอนการบันทึกบทเรียน",
      style: CustomStyles.med14White.copyWith(
        color: CustomColors.gray878787,
      ),
    ),
    onPressed: () {
      if (tutorialUrl == '') return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewScreen(url: tutorialUrl),
        ),
      );
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: CustomColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
    ),
  );
}

class Item extends StatelessWidget {
  const Item({
    Key? key,
    required this.data,
    required this.isFirst,
    required this.isLast,
    required this.draggingMode,
  }) : super(key: key);

  final ItemData data;
  final bool isFirst;
  final bool isLast;
  final DraggingMode draggingMode;

  Widget _buildChild(BuildContext context, ReorderableItemState state) {
    BoxDecoration decoration;

    if (state == ReorderableItemState.dragProxy ||
        state == ReorderableItemState.dragProxyFinished) {
      // slightly transparent background white dragging (just like on iOS)
      decoration = const BoxDecoration(color: Color(0xD0FFFFFF));
    } else {
      bool placeholder = state == ReorderableItemState.placeholder;
      decoration = BoxDecoration(
          border: Border(
              top: isFirst && !placeholder
                  ? Divider.createBorderSide(context) //
                  : BorderSide.none,
              bottom: isLast && placeholder
                  ? BorderSide.none //
                  : Divider.createBorderSide(context)),
          color: placeholder ? null : Colors.white);
    }

    // For iOS dragging mode, there will be drag handle on the right that triggers
    // reordering; For android mode it will be just an empty container
    Widget dragHandle = draggingMode == DraggingMode.iOS
        ? ReorderableListener(
            child: Container(
              padding: const EdgeInsets.only(right: 18.0, left: 18.0),
              color: const Color(0x08000000),
              child: const Center(
                  // child: Icon(Icons.reorder, color: Color(0xFF888888)),
                  ),
            ),
          )
        : Container();

    Widget content = Container(
      decoration: decoration,
      child: SafeArea(
          top: false,
          bottom: false,
          child: Opacity(
            // hide content for placeholder
            opacity: state == ReorderableItemState.placeholder ? 0.0 : 1.0,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: ExpansionTile(
                      // leading: Icon(data.icon),
                      title: Text(
                        data.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      children: [const Text('sdf')],
                    ),
                  ),
                  // Expanded(
                  //     child: Padding(
                  //   padding: const EdgeInsets.symmetric(
                  //       vertical: 14.0, horizontal: 14.0),
                  //   child: Text(data.title,
                  //       style: Theme.of(context).textTheme.titleMedium),
                  // )),
                  // Triggers the reordering
                  dragHandle,
                ],
              ),
            ),
          )),
    );

    // For android dragging mode, wrap the entire content in DelayedReorderableListener
    if (draggingMode == DraggingMode.android) {
      content = DelayedReorderableListener(
        child: content,
      );
    }

    return content;
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableItem(
        key: data.key, //
        childBuilder: _buildChild);
  }
}

class LessonVideo {
  String? id;
  String? title;
  String? video;
  bool? isExpanded;

  LessonVideo({
    this.id,
    this.title,
    this.video,
    this.isExpanded,
  });

  LessonVideo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    video = json['video'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id ?? '';
    data['title'] = title ?? '';
    data['video'] = video ?? '';
    return data;
  }
}
