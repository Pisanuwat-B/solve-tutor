import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/feature/calendar/constants/constants.dart';
import 'package:solve_tutor/feature/calendar/controller/create_course_controller.dart';
import 'package:solve_tutor/feature/calendar/helper/utility_helper.dart';
import 'package:solve_tutor/feature/calendar/model/course_model.dart';
import 'package:solve_tutor/feature/calendar/widgets/dropdown.dart';
import 'package:solve_tutor/feature/calendar/widgets/format_date.dart';
import 'package:solve_tutor/feature/calendar/widgets/widgets.dart';
import 'package:solve_tutor/feature/market_place/pages/create_course.dart';
import 'package:solve_tutor/feature/market_place/pages/update_course.dart';

class MyCourseVDOPage extends StatefulWidget {
  const MyCourseVDOPage({Key? key, required this.tutorId}) : super(key: key);
  final String tutorId;
  @override
  State<MyCourseVDOPage> createState() => _MyCourseVDOPageState();
}

class _MyCourseVDOPageState extends State<MyCourseVDOPage> {
  static final _util = UtilityHelper();
  var courseController = CourseController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  var selectedLevel = '';
  var selectedSubject = '';

  @override
  void initState() {
    super.initState();
    courseController = Provider.of<CourseController>(context, listen: false);
    getData();
    courseController.getCourseListByTutorId(widget.tutorId);
  }

  getData() async {
    courseController.initialize();
    await courseController.getLevels();
    await courseController.getSubjects();
  }

  @override
  void dispose() {
    super.dispose();
    courseController.courseData == null;
  }

  @override
  Widget build(BuildContext context) {
    courseController.initialize();
    return Consumer<CourseController>(builder: (_, course, child) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          backgroundColor: CustomColors.whitePrimary,
          elevation: 6,
          title: Text(
            CustomStrings.myCourse,
            style: CustomStyles.bold22Black363636,
          ),
          leading: InkWell(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: const Icon(
                Icons.arrow_back,
                color: CustomColors.gray878787,
              )),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 24.55),
              child: InkWell(
                child: CircleAvatar(
                  radius: 20.0,
                  // backgroundImage: NetworkImage(
                  //     'https://static.independent.co.uk/s3fs-public/thumbnails/image/2017/09/27/08/jennifer-lawrence.jpg?quality=75&width=982&height=726&auto=webp'),
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: () async {
              courseController.refreshCourseListByTutorId(widget.tutorId);
              await Future.delayed(const Duration(seconds: 1));
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                S.h(10.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _textFieldFilter(),
                      ),
                      S.w(10.0),
                      // PopupMenuButton(
                      //   child: Container(
                      //     decoration: const BoxDecoration(
                      //       borderRadius: BorderRadius.all(
                      //         Radius.circular(10),
                      //       ),
                      //       color: CustomColors.green20B153,
                      //     ),
                      //     padding: const EdgeInsets.all(10.0),
                      //     child: Row(
                      //       children: [
                      //         S.w(10),
                      //         const Icon(
                      //           Icons.add,
                      //           color: Colors.white,
                      //         ),
                      //         S.w(10),
                      //         Text(
                      //           "สร้างคอร์สออนไลน์",
                      //           style: CustomStyles.bold14White,
                      //         ),
                      //         S.w(10),
                      //       ],
                      //     ),
                      //   ),
                      //   itemBuilder: (context) {
                      //     return [
                      //       PopupMenuItem(
                      //           value: '0',
                      //           child: Row(
                      //             children: [
                      //               Image.asset(
                      //                 'assets/images/icon_select_pdf.png',
                      //                 scale: 2,
                      //               ),
                      //               S.w(10),
                      //               Text(
                      //                 'SOLVEPAD',
                      //                 style: CustomStyles.med16Green,
                      //               ),
                      //             ],
                      //           )),
                      //       PopupMenuItem(
                      //           value: '1',
                      //           child: Row(
                      //             children: [
                      //               Image.asset(
                      //                 'assets/images/ph_video.png',
                      //                 scale: 2,
                      //               ),
                      //               S.w(10),
                      //               Text(
                      //                 'อัพโหลดวิดิโอ',
                      //                 style: CustomStyles.med16Green,
                      //               ),
                      //             ],
                      //           ))
                      //     ];
                      //   },
                      //   onSelected: (String value) async {
                      //     if (value == '0') {
                      //       await Navigator.push(
                      //         context,
                      //         MaterialPageRoute(
                      //           builder: (context) => CreateCoursePage(
                      //               tutorId: widget.tutorId,
                      //               courseType: CourseType.pad),
                      //         ),
                      //       );
                      //     } else if (value == '1') {
                      //       await Navigator.push(
                      //         context,
                      //         MaterialPageRoute(
                      //           builder: (context) => CreateCoursePage(
                      //               tutorId: widget.tutorId,
                      //               courseType: CourseType.vdo),
                      //         ),
                      //       );
                      //     }
                      //   },
                      // ),
                      Container(
                        margin: const EdgeInsets.all(6),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: Text(
                            'สร้างคอร์สออนไลน์',
                            style: CustomStyles.med14White.copyWith(
                              color: CustomColors.white,
                            ),
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateCoursePage(
                                    tutorId: widget.tutorId,
                                    courseType: CourseType.pad),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CustomColors.greenPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                S.h(10.0),
                _rowDropdown(),
                Expanded(
                  child: courseController.isLoading
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: Text('กำลังโหลด...'),
                            ),
                          ],
                        )
                      : listMyCourse(
                          course.courseFilter.isNotEmpty
                              ? course.courseFilter
                              : course.courseList,
                          context),
                )
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _textFieldFilter() {
    return SizedBox(
      height: 40,
      child: TextFormField(
        controller: courseController.keywordTextEditingController,
        textAlignVertical: TextAlignVertical.bottom,
        maxLines: 1,
        style: CustomStyles.med14Black363636,
        decoration: InputDecoration(
          hintText: 'ค้นหา...',
          hintStyle: CustomStyles.med14Black363636
              .copyWith(color: CustomColors.grayCFCFCF),
          // isDense: true,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(8.0),
            ),
          ),
          prefixIcon: const Icon(Icons.search),

          // suffix: Text('${controller.courseNames.length}/70'),
        ),
        onChanged: (value) {
          // controller.lastChangeName(courseName.text);
        },
      ),
    );
  }

  Widget _rowDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  child: Dropdown(
                    selectedValue: selectedSubject,
                    items: courseController.subjects,
                    hintText: '-- เลือกหมวดหมู่ --',
                    onChanged: (value) {
                      selectedSubject = value ?? '';
                      debugPrint('หมวดหมู่ $value');
                      courseController.courseFilter = courseController
                          .courseList
                          .where((element) => element.subjectId == value)
                          .toList();
                      setState(() {});
                      // debugPrint('${_courseFilter?.toList().toString()}');
                    },
                  ),
                ),
              ),
              S.w(5),
              Expanded(
                child: Dropdown(
                  selectedValue: selectedLevel,
                  items: courseController.levels,
                  hintText: '-- ระดับชั้นปีการศึกษา --',
                  onChanged: (value) {
                    selectedLevel = value ?? '';
                    courseController.courseFilter = courseController.courseList
                        .where((element) => element.levelId == value)
                        .toList();
                    setState(() {});
                    // debugPrint('${_courseFilter?.toList().toString()}');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget listMyCourse(List<CourseModel> courseList, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: _util.isTablet() ? 2 : 1,
        crossAxisSpacing: 16,
        children: List.generate(courseList.length, (index) {
          return card(
              courseModel: courseList[index],
              onTap: () async {
                if (courseList[index].id?.isNotEmpty == true) {
                  // ignore: use_build_context_synchronously
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          UpdateCourseTab(courseId: courseList[index].id ?? ''),
                    ),
                  );
                }
                await courseController
                    .refreshCourseListByTutorId(widget.tutorId);
              });
        }),
      ),
    );
  }

  Widget card({required CourseModel courseModel, required Function onTap}) {
    var filterLevelId = courseController.levels
        .where((e) => e.id == courseModel.levelId)
        .toList();
    var filterSubjectId = courseController.subjects
        .where((e) => e.id == courseModel.subjectId)
        .toList();
    return InkWell(
      onTap: () => onTap(),
      child: Card(
        elevation: 5,
        margin: const EdgeInsets.all(8.0),
        color: Colors.white,
        child: SizedBox(
          height: 367,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (courseModel.thumbnailUrl?.isNotEmpty == true) ...[
                  CachedNetworkImage(
                    width: double.infinity,
                    fit: BoxFit.cover,
                    height: 180,
                    imageUrl: courseModel.thumbnailUrl ?? '',
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ] else ...[
                  Image.asset(
                    'assets/images/img_not_available.jpeg',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ],
                S.h(8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      S.h(8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (courseModel.courseType == 'vdo') ...[
                            Row(
                              children: [iconSolveVdo()],
                            )
                          ],
                          if (courseModel.courseType == 'pad') ...[
                            Row(
                              children: [iconSolvePad()],
                            )
                          ],
                          Row(
                            children: [
                              _tagType(
                                  '${filterLevelId.isNotEmpty ? filterLevelId.first.name : ''}'),
                              S.w(10),
                              _tagType(
                                  '${filterSubjectId.isNotEmpty ? filterSubjectId.first.name : ''}'),
                            ],
                          )
                        ],
                      ),
                      S.h(8),
                      Text(
                        courseModel.courseName ?? '',
                        maxLines: 1,
                        style: CustomStyles.bold16Black363636,
                      ),
                      Text(
                        courseModel.detailsText ?? '',
                        maxLines: 1,
                        style: CustomStyles.med14Black363636Overflow,
                      ),
                    ],
                  ),
                ),
                _buttonCard(courseModel),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tagType(String tag) {
    return tag.isEmpty
        ? const SizedBox()
        : Container(
            padding: const EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              color: CustomColors.grayF3F3F3,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              tag,
              style: CustomStyles.med12gray878787.copyWith(color: Colors.black),
            ),
          );
  }

  Widget _buttonCard(CourseModel course) {
    final util = UtilityHelper();
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: util.isTablet() ? _isTablet(course) : _isMobile(course));
  }

  Widget _isTablet(CourseModel course) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _studentView(course.studentIds ?? []),
        _border(),
        _lastUpdate(course.createTime!),
        Expanded(child: Container()),
        _videoView(course.lessons?.length ?? 0),
        S.w(20),
        _documentView(course.documentCount ?? 0),
      ],
    );
  }

  Widget _isMobile(CourseModel course) {
    return Column(
      children: [
        Row(
          children: [
            _studentView(course.studentIds ?? []),
            _border(),
            _lastUpdate(course.createTime!),
          ],
        ),
        S.h(10),
        Row(
          children: [
            _videoView(course.lessons?.length ?? 0),
            S.w(10),
            _documentView(course.documentCount ?? 0),
          ],
        ),
      ],
    );
  }

  Widget _border() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      height: 16,
      width: 1,
      color: Colors.grey,
    );
  }

  Widget _studentView(List<String> students) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/student_view.png',
          scale: 4,
        ),
        S.w(5),
        Text(
          '${students.length}',
          style: CustomStyles.med12gray878787,
        ),
      ],
    );
  }

  Widget _lastUpdate(DateTime dt) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'แก้ไขล่าสุด: ${FormatDate.dayOnly(dt)} ',
          style: CustomStyles.med12gray878787,
        ),
      ],
    );
  }

  Widget _videoView(int views) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/videocam.png',
          scale: 4,
        ),
        S.w(5),
        Text(
          '$views',
          style: CustomStyles.med12gray878787,
        ),
      ],
    );
  }

  Widget _documentView(int views) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/doc.png',
          scale: 4,
        ),
        S.w(5),
        Text(
          '$views',
          style: CustomStyles.med12gray878787,
        ),
      ],
    );
  }

  PopupMenuItem _buildPopupMenuItem(
    BuildContext context, {
    required String title,
    required String path,
    required Widget page,
  }) {
    return PopupMenuItem(
      enabled: false,
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        child: Row(
          children: [
            Image.asset(
              path,
              scale: 3,
            ),
            const SizedBox(
              width: 10,
            ),
            Text(
              title,
              style: CustomStyles.bold14Green,
            ),
          ],
        ),
      ),
    );
  }
}
