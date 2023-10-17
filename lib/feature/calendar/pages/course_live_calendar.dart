import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';
import 'package:solve_tutor/feature/calendar/constants/assets_manager.dart';
import 'package:solve_tutor/feature/calendar/constants/custom_colors.dart';
import 'package:solve_tutor/feature/calendar/constants/custom_styles.dart';
import 'package:solve_tutor/feature/calendar/controller/create_course_live_controller.dart';
import 'package:solve_tutor/feature/calendar/helper/utility_helper.dart';
import 'package:solve_tutor/feature/calendar/model/show_course.dart';
import 'package:solve_tutor/feature/calendar/pages/utils.dart';
import 'package:solve_tutor/feature/calendar/pages/waiting_join_room.dart';
import 'package:solve_tutor/feature/calendar/widgets/format_date.dart';
import 'package:solve_tutor/feature/calendar/widgets/sizebox.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../class/pages/class_list_page.dart';
import '../constants/custom_fontfamily.dart';
import 'course_history.dart';
import 'create_course_live.dart';

class CourseLiveCalendar extends StatefulWidget {
  const CourseLiveCalendar({super.key});
  @override
  _CourseLiveCalendarState createState() => _CourseLiveCalendarState();
}

class _CourseLiveCalendarState extends State<CourseLiveCalendar>
    with TickerProviderStateMixin {
  TabController? tabController;
  static final _util = UtilityHelper();
  int indexTab = 0;
  var courseController = CourseLiveController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  ValueNotifier<List<Event>>? _selectedEvents;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  // DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? startTime;
  DateTime? endTime;
  List<DateTime> dateList = [];

  AuthProvider? auth;
  @override
  void initState() {
    super.initState();
    courseController =
        Provider.of<CourseLiveController>(context, listen: false);
    auth = Provider.of<AuthProvider>(context, listen: false);
    getInit();
  }

  getInit() async {
    getCalendarList();
    getTableCalendarList();
    await courseController.getLevels();
    await courseController.getSubjects();
  }

  setRefreshPreferredOrientations() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> getCalendarList() async {
    await courseController.getCourseTutorToday(auth?.uid ?? "");
    if (_util.isTablet()) {
      getDateAll();
      getDate(1);
    } else {
      getDate(7);
    }
    // setState(() {});
  }

  Future<void> getTableCalendarList() async {
    await courseController.getCalendarListAll(auth?.uid ?? "");
    await courseController
        .getDataCalendarList(courseController.calendarListAll);
    setState(() {});
  }

  List<Event> _getEventsForDay(DateTime day) {
    return courseController.kEvents?[day] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (_selectedEvents?.value.isNotEmpty == true) {
      setState(() {
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
        _selectedEvents?.value = _getEventsForDay(selectedDay);
      });
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    // `start` or `end` could be null
    if (start != null && end != null) {
      _selectedEvents?.value = _getEventsForRange(start, end);
    } else if (start != null) {
      _selectedEvents?.value = _getEventsForDay(start);
    } else if (end != null) {
      _selectedEvents?.value = _getEventsForDay(end);
    }
  }

  List<Event> _getEventsForRange(DateTime start, DateTime end) {
    // Implementation example
    final days = daysInRange(start, end);

    return [
      for (final d in days) ..._getEventsForDay(d),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: CustomColors.whitePrimary,
        elevation: 6,
        // leading: InkWell(
        //   onTap: () {
        //     Navigator.of(context).pop();
        //   },
        //   child: const Icon(
        //     Icons.arrow_back,
        //     color: Colors.black,
        //   ),
        // ),
        title: Text(
          'คอร์สสอนสดของฉัน',
          style: CustomStyles.bold22Black363636,
        ),
        actions: [
          if (_util.isTablet()) ...[
            // _buildButtonSearch(),
            _buildButtonAddCourse()
          ]
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: () async {
            await courseController.getCourseTutorToday(auth?.uid ?? "");
            await Future.delayed(const Duration(seconds: 1));
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _listClass(),
                  const SizedBox(
                    height: 50,
                  ),
                  _calendar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _listClass() {
    return SingleChildScrollView(child: Consumer<CourseLiveController>(
      builder: (_, student, child) {
        return Column(
          children: [
            if (_util.isTablet() == false) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _historyText(),
                  Expanded(child: Container()),
                  // _buildButtonSearch(),
                  S.w(10),
                  _buildButtonAddCourse(),
                ],
              )
            ],
            // if (courseController.showCourseTutorToday.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _topicText('คาบสอนวันนี้'),
                if (_util.isTablet()) ...[
                  _historyText(),
                ] else ...[
                  // _sellAll(),
                ]
              ],
            ),
            student.isLoadingCourseTutorToday
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
                : courseController.showCourseTutorFilterToday.isNotEmpty
                    ? SizedBox(
                        height: _util.isTablet() ? 367 : 240,
                        width: double.infinity,
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: courseController
                                        .showCourseTutorFilterToday.length <=
                                    10
                                ? courseController
                                    .showCourseTutorFilterToday.length
                                : 10,
                            itemBuilder: (context, index) {
                              return _util.isTablet()
                                  ? cardTablet(
                                      showCourseTutor: courseController
                                          .showCourseTutorFilterToday[index],
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => WaitingJoinRoom(
                                                course: courseController
                                                        .showCourseTutorFilterToday[
                                                    index]),
                                          ),
                                        );
                                        setRefreshPreferredOrientations();
                                      },
                                    )
                                  : cardMobile(
                                      showCourseTutor: courseController
                                          .showCourseTutorFilterToday[index],
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => WaitingJoinRoom(
                                                course: courseController
                                                        .showCourseTutorFilterToday[
                                                    index]),
                                          ),
                                        );
                                        setRefreshPreferredOrientations();
                                      },
                                    );
                            }),
                      )
                    : Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        decoration: BoxDecoration(
                          border: Border.all(width: 1, color: Colors.grey),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'ไม่มีการเรียนการสอน',
                            style: CustomStyles.bold14Gray878787,
                          ),
                        ),
                      ),
          ],
          // ],
        );
      },
    ));
  }

  Widget _buildButtonAddCourse() {
    return _util.isTablet()
        ? Container(
            margin: const EdgeInsets.all(8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(
                'เพิ่มคอร์สเรียน',
                style: CustomStyles.med14White.copyWith(
                  color: CustomColors.white,
                ),
              ),
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateCourseLivePage(tutorId: auth!.user!.id!),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomColors.greenPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0)),
              ),
            ),
          )
        : InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CreateCourseLivePage(tutorId: auth!.user!.id!),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: const BoxDecoration(
                color: CustomColors.greenPrimary,
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
            ),
          );
  }

  Widget _buildButtonSearch() {
    if (_util.isTablet()) {
      return Container(
        margin: const EdgeInsets.all(8),
        child: ElevatedButton.icon(
          icon: const Icon(
            Icons.search,
            color: CustomColors.gray363636,
          ),
          label: Text(
            'ค้นหางานสอน',
            style: CustomStyles.med14White.copyWith(
              color: CustomColors.gray363636,
            ),
          ),
          onPressed: () async {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ClassListPage(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: CustomColors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
          ),
        ),
      );
    } else {
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ClassListPage(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: Colors.grey),
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
          ),
          child: Text(
            'ค้นหางานสอน',
            style: CustomStyles.bold16Green,
          ),
        ),
      );
    }
  }

  Widget cardTablet(
      {required ShowCourseTutor showCourseTutor, required Function onTap}) {
    var filterLevelId = courseController.levels
        .where((e) => e.id == showCourseTutor.levelId)
        .toList();
    var filterSubjectId = courseController.subjects
        .where((e) => e.id == showCourseTutor.subjectId)
        .toList();
    bool courseReady = joinReady(showCourseTutor.start ?? DateTime.now());
    return InkWell(
      onTap: () => onTap(),
      child: SizedBox(
        height: 367,
        width: 367,
        child: Card(
          elevation: 5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(8.0),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showCourseTutor.thumbnailUrl?.isNotEmpty == true) ...[
                Stack(
                  alignment: Alignment.center,
                  children: [
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
                            colorFilter: !courseReady
                                ? ColorFilter.mode(
                                    Colors.black.withOpacity(0.5),
                                    BlendMode.srcOver)
                                : null,
                          ),
                        ),
                      ),
                      height: 180,
                      imageUrl: showCourseTutor.thumbnailUrl ?? '',
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Image.asset(
                        ImageAssets.emptyCourse,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                    if (!courseReady)
                      const Text(
                        '- ยังไม่ถึงเวลาเข้าเรียน -',
                        style: TextStyle(color: Colors.white),
                      ),
                  ],
                ),
              ] else ...[
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        image: DecorationImage(
                          image: const AssetImage(
                            'assets/images/img_not_available.jpeg',
                          ),
                          fit: BoxFit.cover,
                          colorFilter: !courseReady
                              ? ColorFilter.mode(Colors.black.withOpacity(0.5),
                                  BlendMode.srcOver)
                              : null,
                        ),
                      ),
                    ),
                    if (!courseReady) ...[
                      const Text(
                        '- ยังไม่ถึงเวลาเข้าห้องสอน -',
                        style: TextStyle(color: Colors.white),
                      ),
                    ]
                  ],
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
                        _tagTime(
                            '${FormatDate.timeOnlyNumber(showCourseTutor.start)} น. - ${FormatDate.timeOnlyNumber(showCourseTutor.end)} น.'),
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
                      showCourseTutor.courseName ?? '',
                      maxLines: 1,
                      style: CustomStyles.bold16Black363636,
                    ),
                    Text(
                      showCourseTutor.detailsText ?? '',
                      maxLines: 1,
                      style: CustomStyles.med14Black363636Overflow,
                    ),
                    S.h(8),
                    _buttonCard(showCourseTutor),
                  ],
                ),
              ),
              S.h(8),
            ],
          ),
        ),
      ),
    );
  }

  Widget cardMobile(
      {required ShowCourseTutor showCourseTutor, required Function onTap}) {
    var filterLevelId = courseController.levels
        .where((e) => e.id == showCourseTutor.levelId)
        .toList();
    var filterSubjectId = courseController.subjects
        .where((e) => e.id == showCourseTutor.subjectId)
        .toList();
    bool courseReady = joinReady(showCourseTutor.start ?? DateTime.now());
    return InkWell(
      onTap: () => onTap(),
      child: SizedBox(
        height: 230,
        width: 160,
        child: Card(
          elevation: 5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(8.0),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showCourseTutor.thumbnailUrl?.isNotEmpty == true) ...[
                Stack(
                  alignment: Alignment.center,
                  children: [
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
                            colorFilter: ColorFilter.mode(
                                !courseReady
                                    ? Colors.black.withOpacity(0.6)
                                    : Colors.transparent,
                                BlendMode.screen),
                          ),
                        ),
                      ),
                      height: 90,
                      imageUrl: showCourseTutor.thumbnailUrl ?? '',
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Image.asset(
                        ImageAssets.emptyCourse,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                    if (!courseReady) ...[
                      Text(
                        '- ยังไม่ถึงเวลาเข้าเรียน -',
                        style: CustomStyles.med14White,
                      )
                    ]
                  ],
                ),
              ] else ...[
                Image.asset(
                  ImageAssets.emptyCourse,
                  height: 90,
                  width: double.infinity,
                  fit: BoxFit.fitHeight,
                ),
              ],
              S.h(8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    S.h(8),
                    Text(
                      showCourseTutor.courseName ?? '',
                      maxLines: 1,
                      style: CustomStyles.bold16Black363636,
                    ),
                    Text(
                      showCourseTutor.detailsText ?? '',
                      maxLines: 1,
                      style: CustomStyles.med14Black363636Overflow,
                    ),
                    S.h(8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _tagTime(
                            '${FormatDate.timeOnlyNumber(showCourseTutor.start)} น. - ${FormatDate.timeOnlyNumber(showCourseTutor.end)} น.'),
                      ],
                    ),
                    S.h(8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _tagType(
                            '${filterLevelId.isNotEmpty ? filterLevelId.first.name : ''}'),
                        _tagType(
                            '${filterSubjectId.isNotEmpty ? filterSubjectId.first.name : ''}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<bool> _isSelected = [true, false];
  Widget _switch() {
    return ToggleButtons(
      isSelected: _isSelected,
      borderColor: Colors.grey,
      selectedBorderColor: Colors.grey,
      fillColor: CustomColors.greenPrimary.withOpacity(0.2),
      selectedColor: CustomColors.greenPrimary,
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      onPressed: (int index) {
        var set = _isSelected.map((e) => e = false).toList();
        _isSelected = set;
        _isSelected[index] = true;
        if (_isSelected.first == true) {
          getDate(courseController.daysForTablet[0].id);
        }
        setState(() {});
      },
      children: (_util.isTablet())
          ? <Widget>[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month),
                    S.w(10),
                    const Text('Calendar')
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.list),
                    S.w(10),
                    const Text('List')
                  ],
                ),
              )
            ]
          : <Widget>[
              const Icon(Icons.calendar_month),
              const Icon(Icons.list),
            ],
    );
  }

  Widget _calendar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_topicText('ตารางสอนของฉัน'), _switch()],
        ),
        if (_isSelected.last == true) ...[
          if (_util.isTablet()) ...[
            listCalendarTablet()
          ] else ...[
            listCalendarMobile()
          ]
        ],
        if (_isSelected.first == true) ...[
          if (_util.isTablet()) ...[
            tableCalendarTablet(),
          ] else ...[
            tableCalendarMobile(),
          ],
        ],
      ],
    );
  }

  var indexListCalendar = 0;

  List<ShowCourseTutor> listCalendarTab = [];
  void getDateAll() {
    courseController.daysForTablet.map((e) => e.sum = 0).toList();
    for (var day in courseController.showCourseTutorToday) {
      courseController.daysForTablet.map((element) {
        if (element.id == day.start?.weekday) {
          element.sum += 1;
        }
      }).toList();
    }
    // setState(() {});
  }

  void getDate(int daySelected) {
    listCalendarTab.clear();
    for (var day in courseController.showCourseTutorToday) {
      if (day.start?.weekday == daySelected) {
        listCalendarTab.add(day);
      }
    }

    // setState(() {});
  }

  Widget listCalendarMobile() {
    return Column(children: [
      S.h(20),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(width: 1, color: Colors.grey),
          borderRadius: const BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              courseController.days.length,
              (index) => InkWell(
                onTap: () {
                  indexListCalendar = index;
                  getDate(courseController.days[index].id);
                  setState(() {});
                },
                child: Text(
                  courseController.daysDD[index].day,
                  style: CustomStyles.blod16gray878787.copyWith(
                    color: indexListCalendar != index
                        ? Colors.black
                        : CustomColors.greenPrimary,
                  ),
                ),
              ),
            )),
      ),
      S.h(20),
      if (listCalendarTab.isEmpty) ...[
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: Colors.grey),
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
          ),
          child: Center(
            child: Text(
              'ไม่พบข้อมูล',
              style: CustomStyles.bold12Black363636.copyWith(fontSize: 12),
            ),
          ),
        ),
      ],
      Column(
        children: List.generate(listCalendarTab.length, (index) {
          var filterLevelId = courseController.levels
              .where((e) => e.id == listCalendarTab[index].levelId)
              .toList();
          var filterSubjectId = courseController.subjects
              .where((e) => e.id == listCalendarTab[index].subjectId)
              .toList();

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(width: 1, color: Colors.grey),
              borderRadius: const BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${FormatDate.timeOnlyNumber(listCalendarTab[index].start)} น. - ${FormatDate.timeOnlyNumber(listCalendarTab[index].end)} น.',
                      style: CustomStyles.blod16gray878787
                          .copyWith(color: Colors.black),
                    ),
                    Text(
                      FormatDate.dayOnly(listCalendarTab[index].start),
                      style: CustomStyles.reg16gray878787,
                    )
                  ],
                ),
                S.h(10),
                Row(
                  children: [
                    SizedBox(
                      height: 74,
                      width: 131,
                      child: CachedNetworkImage(
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
                        errorWidget: (context, url, error) {
                          return Image.asset(
                            ImageAssets.emptyCourse,
                            height: 90,
                            width: double.infinity,
                            fit: BoxFit.fitHeight,
                          );
                        },
                        imageUrl: listCalendarTab[index].thumbnailUrl ?? '',
                      ),
                    ),
                    S.w(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listCalendarTab[index].courseName ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CustomStyles.bold16Black363636,
                          ),
                          Text(
                            listCalendarTab[index].detailsText ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: CustomStyles.med14Black363636Overflow,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                S.h(10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      auth?.user?.name ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CustomStyles.reg16Green,
                    ),
                    Row(
                      children: [
                        _tagType(
                            '${filterSubjectId.isNotEmpty ? filterSubjectId.first.name : ''}'),
                        S.w(4.0),
                        _tagType(
                            '${filterLevelId.isNotEmpty ? filterLevelId.first.name : ''}'),
                      ],
                    )
                  ],
                )
              ],
            ),
          );
        }),
      )
    ]);
  }

  Widget listCalendarTablet() {
    return DefaultTabController(
      length: 7, // กำหนดจำนวน tab
      child: Column(children: [
        S.h(20),
        TabBar(
          labelColor: CustomColors.greenPrimary,
          labelStyle: CustomStyles.med14Black363636,
          unselectedLabelColor: Colors.grey,
          indicatorColor: CustomColors.greenPrimary,
          labelPadding: const EdgeInsets.symmetric(horizontal: 0),
          onTap: (index) async {
            getDate(courseController.daysForTablet[index].id);
            setState(() {});
          },
          tabs: List.generate(
            courseController.daysForTablet.length,
            (index) => Tab(
                child: Text(
              '${courseController.daysForTablet[index].day} (${courseController.daysForTablet[index].sum})',
              maxLines: 1,
            )),
          ),
        ),
        S.h(20),
        if (listCalendarTab.isEmpty) ...[
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              border: Border.all(width: 1, color: Colors.grey),
              borderRadius: const BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            child: Center(
              child: Text(
                'ไม่พบข้อมูล',
                style: CustomStyles.bold12Black363636,
              ),
            ),
          ),
        ],
        Column(
          children: List.generate(listCalendarTab.length, (index) {
            var filterLevelId = courseController.levels
                .where((e) => e.id == listCalendarTab[index].levelId)
                .toList();
            var filterSubjectId = courseController.subjects
                .where((e) => e.id == listCalendarTab[index].subjectId)
                .toList();

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(width: 1, color: Colors.grey),
                borderRadius: const BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _tagTime(
                          '${FormatDate.timeOnlyNumber(listCalendarTab[index].start)} น. - ${FormatDate.timeOnlyNumber(listCalendarTab[index].end)} น.'),
                      S.w(50),
                      SizedBox(
                        height: 48,
                        width: 85,
                        child: listCalendarTab[index]
                                    .thumbnailUrl
                                    .toString()
                                    .isNotEmpty ==
                                true
                            ? CachedNetworkImage(
                                width: double.infinity,
                                fit: BoxFit.cover,
                                imageBuilder: (context, imageProvider) =>
                                    Container(
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
                                imageUrl:
                                    listCalendarTab[index].thumbnailUrl ?? '',
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(
                                    color: const Color.fromRGBO(29, 41, 57, 1),
                                    width: 0.5,
                                  ),
                                ),
                                height: 48,
                                width: 85,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    'assets/images/img_not_available.jpeg',
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                      ),
                      S.w(20),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listCalendarTab[index].courseName ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CustomStyles.bold14Black363636,
                            ),
                            Text(
                              listCalendarTab[index].detailsText ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CustomStyles.med14Black363636Overflow,
                            ),
                          ],
                        ),
                      ),
                      S.w(50),
                      Row(
                        children: [
                          _tagType(
                              '${filterLevelId.isNotEmpty ? filterLevelId.first.name : ''}'),
                          S.w(10),
                          _tagType(
                              '${filterSubjectId.isNotEmpty ? filterSubjectId.first.name : ''}'),
                        ],
                      ),
                    ],
                  ),
                  S.h(10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/tutor_icon.png',
                              scale: 4,
                            ),
                            S.w(10),
                            Text(
                              auth?.user?.name ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: CustomStyles.reg16Green,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            FormatDate.dayOnly(listCalendarTab[index].start),
                            style: CustomStyles.bold14Black363636,
                          ),
                          S.w(10),
                          // _learned(),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            );
          }),
        )
      ]),
    );
  }

  Widget tableCalendarTablet() {
    var now = DateTime.now();
    return Consumer<CourseLiveController>(
        builder: (context, courseLive, child) {
      DateTime today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      return TableCalendar<Event>(
        availableGestures: AvailableGestures.horizontalSwipe,
        locale: 'en_US',
        firstDay: now,
        onHeaderTapped: (focusedDay) {},
        lastDay: courseController.kEvents?.isNotEmpty == true
            ? courseController.kEvents?.keys.last ??
                DateTime(now.year, now.month + 1, now.day)
            : DateTime(now.year, now.month + 1, now.day),
        focusedDay: now,
        calendarFormat: _calendarFormat,
        availableCalendarFormats: const {
          CalendarFormat.month: 'Month',
        },
        rangeSelectionMode: _rangeSelectionMode,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.sunday,
        daysOfWeekHeight: 56,
        rowHeight: 128.4,
        daysOfWeekStyle: DaysOfWeekStyle(
          weekendStyle: CustomStyles.med16Black363636,
          weekdayStyle: CustomStyles.med16Black363636,
        ),
        calendarStyle: const CalendarStyle(
          // Use `CalendarStyle` to customize the UI
          outsideDaysVisible: false, cellPadding: EdgeInsets.all(16),
          tableBorder: TableBorder(
              horizontalInside:
                  BorderSide(width: 1, color: CustomColors.grayCFCFCF),
              verticalInside:
                  BorderSide(width: 1, color: CustomColors.grayCFCFCF),
              left: BorderSide(width: 1, color: CustomColors.grayCFCFCF),
              right: BorderSide(width: 1, color: CustomColors.grayCFCFCF),
              top: BorderSide(width: 1, color: CustomColors.grayCFCFCF),
              bottom: BorderSide(
                width: 1,
              ),
              borderRadius: BorderRadius.all(Radius.circular(8.0))),
        ),
        onDaySelected: _onDaySelected,
        onRangeSelected: _onRangeSelected,
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          // _focusedDay = focusedDay;
        },
        calendarBuilders: CalendarBuilders(
          todayBuilder: (context, day, focusedDay) {
            return TextButton(
              onPressed: () {},
              child: Container(
                color: const Color(0xffB9E7C9),
                padding: const EdgeInsets.only(left: 20, top: 20),
                alignment: Alignment.topLeft,
                child: Text(
                  day.day.toString(),
                  style: CustomStyles.med16Black363636
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
          outsideBuilder: (context, day, event) {
            return Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: CustomColors.grayF3F3F3,
                ),
                padding: const EdgeInsets.only(left: 20, top: 20),
                alignment: Alignment.topLeft,
                child: Text(
                  day.day.toString(),
                  style: CustomStyles.med16Black363636.copyWith(
                      fontWeight: FontWeight.bold,
                      color: CustomColors.gray878787),
                ));
          },
          disabledBuilder: (context, day, focusedDay) {
            return TextButton(
              onPressed: () {},
              child: Container(
                padding: const EdgeInsets.only(left: 20, top: 20),
                alignment: Alignment.topLeft,
                child: Text(
                  day.day.toString(),
                  style: CustomStyles.med16Black363636
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
          defaultBuilder: (context, day, event) {
            return TextButton(
              onPressed: () {},
              child: Container(
                padding: const EdgeInsets.only(left: 20, top: 20),
                alignment: Alignment.topLeft,
                child: Text(
                  day.day.toString(),
                  style: CustomStyles.med16Black363636
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
          markerBuilder: (context, day, event) {
            if (event.isNotEmpty && (day.isAfter(today) || day == today)) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    S.h(0),
                    if (event.isNotEmpty) ...[
                      InkWell(
                        onTap: () async {
                          await showDialog(
                            context: context,
                            builder: (context) => _eventList(day, event),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5.0, vertical: 2.0),
                          margin: const EdgeInsets.symmetric(horizontal: 12.0),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: CustomColors.gray878787,
                              width: 1,
                            ),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(20.0)),
                            shape: BoxShape.rectangle,
                            color: _getWeekColor(day.weekday),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            event.first.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: CustomFontFamily.NotoSansMed,
                              fontSize: _util.addMinusFontSize(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                    S.h(5),
                    if (event.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5.0, vertical: 0.0),
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        decoration: BoxDecoration(
                            border: Border.all(
                              color: CustomColors.gray878787,
                              width: 1,
                            ),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(20.0)),
                            shape: BoxShape.rectangle,
                            color: CustomColors.white),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () async {
                                await showDialog(
                                    context: context,
                                    builder: (context) =>
                                        _eventList(day, event));
                              },
                              child: Text(
                                '+${event.length - 1} รายการ',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CustomStyles.med12GreenPrimary.copyWith(
                                  fontSize: _util.addMinusFontSize(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    S.h(5),
                  ],
                ),
              );
            } // now + future
            else {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    S.h(0),
                    if (event.isNotEmpty) ...[
                      InkWell(
                        onTap: () async {
                          await showDialog(
                            context: context,
                            builder: (context) => _eventList(day, event),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5.0, vertical: 0.0),
                          margin: const EdgeInsets.symmetric(horizontal: 8.0),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: CustomColors.gray878787,
                              width: 1,
                            ),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(20.0)),
                            shape: BoxShape.rectangle,
                            color: Colors.grey,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            event.first.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: CustomFontFamily.NotoSansMed,
                              fontSize: _util.addMinusFontSize(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                    S.h(5),
                    if (event.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5.0, vertical: 0.0),
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        decoration: BoxDecoration(
                            border: Border.all(
                              color: CustomColors.gray878787,
                              width: 1,
                            ),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(20.0)),
                            shape: BoxShape.rectangle,
                            color: CustomColors.white),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () async {
                                await showDialog(
                                    context: context,
                                    builder: (context) =>
                                        _eventList(day, event));
                              },
                              child: Text(
                                '+${event.length - 1} รายการ',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CustomStyles.med12GreenPrimary.copyWith(
                                  fontSize: _util.addMinusFontSize(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    S.h(5),
                  ],
                ),
              );
              // return const SizedBox();
            } // past
          },
        ),
      );
    });
  }

  Color _getWeekColor(int weekday) {
    // switch (weekday) {
    //   case 1:
    //     return Colors.black;
    //   case 2:
    //     return Colors.pinkAccent;
    //   case 3:
    //     return CustomColors.greenPrimary;
    //   case 4:
    //     return const Color(0xffFF9800);
    //   case 5:
    //     return Colors.blueAccent;
    //   case 6:
    //     return const Color(0xff8B5CF6);
    //   case 7:
    //     return const Color(0xffF44336);
    //   default:
    //     return Colors.black; // Should never be reached.
    // }
    return CustomColors.greenPrimary;
  }

  Widget tableCalendarMobile() {
    var now = DateTime.now();
    return TableCalendar<Event>(
      availableGestures: AvailableGestures.horizontalSwipe,
      locale: 'en_US',
      firstDay: now,
      lastDay: courseController.kEvents?.isNotEmpty == true
          ? courseController.kEvents?.keys.last ??
              DateTime(now.year, now.month + 1, now.day)
          : DateTime(now.year, now.month + 1, now.day),
      focusedDay: now,
      calendarFormat: _calendarFormat,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
      },
      calendarStyle: const CalendarStyle(
        // Use `CalendarStyle` to customize the UI
        outsideDaysVisible: false,
        cellPadding: EdgeInsets.all(0),
        tableBorder: TableBorder(
            horizontalInside:
                BorderSide(width: 1, color: CustomColors.grayCFCFCF),
            left: BorderSide(width: 1, color: CustomColors.grayCFCFCF),
            right: BorderSide(width: 1, color: CustomColors.grayCFCFCF),
            top: BorderSide(width: 1, color: CustomColors.grayCFCFCF),
            bottom: BorderSide(
              width: 1,
            ),
            borderRadius: BorderRadius.all(Radius.circular(20.0))),
      ),
      daysOfWeekHeight: 50,
      rowHeight: 50,
      selectedDayPredicate: (day) => false,
      rangeSelectionMode: _rangeSelectionMode,
      eventLoader: _getEventsForDay,
      startingDayOfWeek: StartingDayOfWeek.monday,
      onDaySelected: _onDaySelected,
      onRangeSelected: _onRangeSelected,
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (focusedDay) {
        // _focusedDay = focusedDay;
      },
      calendarBuilders: CalendarBuilders(
        disabledBuilder: (context, day, focusedDay) => SizedBox(
          child: Center(
            child: Text(
              day.day.toString(),
              style: CustomStyles.med16Black363636.copyWith(
                  fontWeight: FontWeight.bold, color: CustomColors.gray878787),
            ),
          ),
        ),
        todayBuilder: (context, day, focusedDay) => SizedBox(
          child: Center(
            child: Text(
              day.day.toString(),
              style: CustomStyles.med16Black363636.copyWith(
                  fontWeight: FontWeight.bold, color: CustomColors.gray878787),
            ),
          ),
        ),
        defaultBuilder: (context, day, focusedDay) => SizedBox(
          child: Center(
            child: Text(
              day.day.toString(),
              style: CustomStyles.med16Black363636.copyWith(
                  fontWeight: FontWeight.normal, color: CustomColors.black),
            ),
          ),
        ),
        markerBuilder: (context, day, event) {
          if (event.isNotEmpty && day.isAfter(DateTime.now())) {
            return InkWell(
              onTap: () async {
                await showDialog(
                    context: context,
                    builder: (context) => _eventList(day, event));
              },
              child: Column(
                children: [
                  if (event.isNotEmpty) ...[
                    Expanded(child: Container()),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                            event.length,
                            (index) => Container(
                                  height: 7,
                                  width: 7,
                                  decoration: const BoxDecoration(
                                    color: CustomColors.greenPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                )),
                      ),
                    ),
                  ],
                ],
              ),
            );
          } else {
            return const SizedBox();
          }
        },
      ),
    );
  }

  Widget _eventList(DateTime day, List<Event>? event) {
    event?.sort((a, b) => a.start.compareTo(b.start));
    return AlertDialog(
      title: Text(
        'วันที่ ${FormatDate.dayOnly(day)}',
        style: CustomStyles.bold22Black363636,
      ),
      actions: [
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
      ],
      content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
        return SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (event?.isEmpty == true) ...[
                  const Center(
                    child: SizedBox(
                      child: Text('ไม่พบตารางเรียน'),
                    ),
                  )
                ],
                S.h(10),
                for (Event i in event ?? [] as List<Event>) ...[
                  Card(
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.check_circle_outlined,
                            color: CustomColors.greenPrimary,
                            size: 40,
                          ),
                          title: Text(
                            i.courseName,
                            style: CustomStyles.blod16gray878787,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            i.title,
                            overflow: TextOverflow.ellipsis,
                            style: CustomStyles.blod16gray878787,
                          ),
                          trailing: i.courseId ==
                                  courseController.courseData?.id
                              ? TextButton(
                                  onPressed: () async {
                                    var result2 = courseController
                                        .courseData?.calendars
                                        ?.where((element) =>
                                            element.courseId ==
                                                courseController
                                                    .courseData?.id &&
                                            element.start?.compareTo(i.start) ==
                                                0 &&
                                            element.end?.compareTo(i.end) == 0)
                                        .toList();
                                    if (result2?.isNotEmpty == true) {
                                      for (var i in result2 ?? []) {
                                        courseController.courseData?.calendars
                                            ?.remove(i);
                                        courseController.calendarListAll
                                            .remove(i);
                                      }
                                      event?.remove(i);
                                      setState(() {});
                                    }
                                  },
                                  child: Text(
                                    'ลบ',
                                    textAlign: TextAlign.center,
                                    style: CustomStyles.blod16gray878787
                                        .copyWith(color: Colors.red),
                                  ),
                                )
                              : const SizedBox()),
                    ),
                  )
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  bool joinReady(DateTime start) {
    return DateTime.now().isAfter(start.subtract(const Duration(minutes: 30)));
  }

  Widget _tagTime(String tag) {
    if (tag.isEmpty) return const SizedBox();
    return Container(
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

  Widget _tagType(String tag) {
    if (tag.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        color: CustomColors.grayF3F3F3,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        tag,
        style: CustomStyles.med12gray878787.copyWith(
            color: Colors.black, fontSize: _util.isTablet() ? 14 : 13),
      ),
    );
  }

  // Widget _learned() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
  //     decoration: BoxDecoration(
  //       color: CustomColors.orangeFFE0B2,
  //       borderRadius: BorderRadius.circular(20.0),
  //     ),
  //     child: Text(
  //       'เรียนแล้ว: 5 / 50',
  //       style: CustomStyles.med12gray878787.copyWith(
  //         color: CustomColors.orangeCC6700,
  //       ),
  //     ),
  //   );
  // }

  Widget _topicText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: CustomStyles.bold22Black363636,
        ),
      ),
    );
  }

  Widget _historyText() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CourseHistory(),
          ),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.history,
            color: CustomColors.greenPrimary,
          ),
          Text(
            'ประวัติการสอน',
            style: CustomStyles.bold16Green
                .copyWith(fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _sellAll() {
    return Text('ดูเพิ่มเติม', style: CustomStyles.bold16Green);
  }

  Widget _buttonCard(ShowCourseTutor showCourseTutor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/images/student_view.png',
              scale: 4,
            ),
            S.w(5),
            Text(
              '${showCourseTutor.studentCount ?? 0}',
              style: CustomStyles.med12gray878787,
            ),
          ],
        ),
        const SizedBox(),
        // Text('status: publish'),
      ],
    );
  }
}
