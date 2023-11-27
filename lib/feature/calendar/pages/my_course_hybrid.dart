import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';
import 'package:solve_tutor/feature/calendar/constants/constants.dart';
import 'package:solve_tutor/feature/calendar/controller/create_course_live_controller.dart';
import 'package:solve_tutor/feature/calendar/helper/utility_helper.dart';
import 'package:solve_tutor/feature/calendar/model/course_model.dart';
import 'package:solve_tutor/feature/calendar/pages/create_course_live.dart';
import 'package:solve_tutor/feature/calendar/pages/update_course_live.dart';
import 'package:solve_tutor/feature/calendar/widgets/dropdown.dart';
import 'package:solve_tutor/feature/calendar/widgets/format_date.dart';
import 'package:solve_tutor/feature/calendar/widgets/widgets.dart';
import 'package:solve_tutor/feature/profile/pages/profile_page.dart';
import 'package:solve_tutor/widgets/sizer.dart';

import '../../../constants/school_subject_constants.dart';

enum CourseLiveActionType { create, update }

class MyCourseHybridPage extends StatefulWidget {
  const MyCourseHybridPage({Key? key, required this.tutorId}) : super(key: key);
  final String tutorId;
  @override
  State<MyCourseHybridPage> createState() => _MyCourseHybridPageState();
}

class _MyCourseHybridPageState extends State<MyCourseHybridPage> {
  final util = UtilityHelper();
  var courseController = CourseLiveController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();
  String selectClass = SchoolSubjectConstants.schoolSubjectFilterList.first;
  String selectClassLevel = SchoolSubjectConstants.schoolClassLevel.first;

  var selectedLevel = '';
  var selectedSubject = '';

  @override
  void initState() {
    super.initState();
    courseController =
        Provider.of<CourseLiveController>(context, listen: false);
    getData();
  }

  getData() async {
    courseController.initialize();
    courseController.isLoading = true;
    await courseController.getLevels();
    await courseController.getSubjects();
    await courseController.getCourseListByTutorIdAndCourseType(widget.tutorId, 'hybrid');
  }

  @override
  void dispose() {
    super.dispose();
    courseController.courseData == null;
  }

  @override
  Widget build(BuildContext context) {
    courseController.initialize();
    return Consumer<CourseLiveController>(builder: (_, course, child) {
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
          // actions: const [
          //   Padding(
          //     padding: EdgeInsets.only(right: 24.55),
          //     child: InkWell(
          //       child: CircleAvatar(
          //         radius: 20.0,
          //         backgroundImage: NetworkImage(
          //             'https://static.independent.co.uk/s3fs-public/thumbnails/image/2017/09/27/08/jennifer-lawrence.jpg?quality=75&width=982&height=726&auto=webp'),
          //         backgroundColor: Colors.transparent,
          //       ),
          //     ),
          //   ),
          // ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: () async {
              courseController.refreshCourseListByTutorIdAndCourseType(widget.tutorId, 'hybrid');
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
                      InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CreateCourseLivePage(tutorId: widget.tutorId, courseType: 'hybrid'),
                            ),
                          );
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(
                              Radius.circular(10),
                            ),
                            color: CustomColors.green20B153,
                          ),
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            children: [
                              S.w(10),
                              const Icon(
                                Icons.add,
                                color: Colors.white,
                              ),
                              S.w(10),
                              Text(
                                "สร้างคอร์ส Hybrid",
                                style: CustomStyles.bold14White,
                              ),
                              S.w(10),
                            ],
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
      height: 50,
      child: TextFormField(
        controller: courseController.keywordTextEditingController,
        textAlignVertical: TextAlignVertical.bottom,
        maxLines: 1,
        style: CustomStyles.med14Black363636,
        decoration: InputDecoration(
          hintText: 'ค้นหา...',
          hintStyle: CustomStyles.med14Black363636
              .copyWith(color: CustomColors.grayCFCFCF),
          // isDense: trueasas,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(8.0),
            ),
          ),
          prefixIcon: Icon(Icons.search),
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
                child: Dropdown(
                  selectedValue: selectedSubject,
                  items: courseController.subjects,
                  hintText: '-- เลือกหมวดหมู่ --',
                  onChanged: (value) {
                    selectedSubject = value ?? '';
                    debugPrint(value);
                    courseController.courseFilter = courseController.courseList
                        .where((element) => element.subjectId == value)
                        .toList();
                    setState(() {});
                    // debugPrint('${_courseFilter?.toList().toString()}');
                  },
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
        crossAxisCount: util.isTablet() ? 2 : 1,
        crossAxisSpacing: 16,
        children: List.generate(courseList.length, (index) {
          return card(
              courseModel: courseList[index],
              onTap: () async {
                if (courseList[index].id?.isNotEmpty == true) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UpdateCourseLiveTab(
                        courseId: courseList[index].id ?? '',
                      ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(8.0),
        color: Colors.white,
        child: SizedBox(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (courseModel.thumbnailUrl?.isNotEmpty == true) ...[
                  CachedNetworkImage(
                    width: double.infinity,
                    fit: BoxFit.cover,
                    imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
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
                    height: 160,
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
                          hybridSolveIcon(),
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
                S.h(8),
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
        // _videoView(course.lessons?.length ?? 0),
        // S.w(20),
        // _documentView(course.document?.data?.docFiles?.length ?? 0),
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
        // Row(
        //   children: [
        //     _videoView(course.lessons?.length ?? 0),
        //     S.w(10),
        //     _documentView(course.document?.data?.docFiles?.length ?? 0),
        //   ],
        // ),
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
