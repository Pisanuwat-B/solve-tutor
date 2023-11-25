import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';
import 'package:solve_tutor/feature/calendar/constants/custom_colors.dart';
import 'package:solve_tutor/feature/calendar/constants/custom_styles.dart';
import 'package:solve_tutor/feature/calendar/controller/create_course_controller.dart';
import 'package:solve_tutor/feature/calendar/controller/document_controller.dart';
import 'package:solve_tutor/feature/calendar/helper/utility_helper.dart';
import 'package:solve_tutor/feature/calendar/model/show_course.dart';
import 'package:solve_tutor/feature/calendar/widgets/format_date.dart';
import 'package:solve_tutor/feature/calendar/widgets/sizebox.dart';
import 'package:solve_tutor/feature/live_classroom/components/close_dialog.dart';
import 'package:solve_tutor/widgets/sizer.dart';

import '../../live_classroom/page/live_classroom.dart';
import '../../live_classroom/utils/api.dart';
import '../../live_classroom/utils/toast.dart';
import '../controller/create_course_live_controller.dart';

class WaitingJoinRoom extends StatefulWidget {
  const WaitingJoinRoom({super.key, required this.course});
  final ShowCourseTutor course;
  @override
  State<WaitingJoinRoom> createState() => _WaitingJoinRoomState();
}

class _WaitingJoinRoomState extends State<WaitingJoinRoom>
    with TickerProviderStateMixin {
  var documentController = DocumentController();
  var courseController = CourseLiveController();
  static final _util = UtilityHelper();
  late AuthProvider authProvider;
  late AnimationController _controller;
  String? _image;

  // VideoSDK
  String _token = "";
  bool isActive = false;
  bool isMicOn = true;
  bool? isJoinMeetingSelected;
  bool? isCreateMeetingSelected;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      lowerBound: 0.5,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = await fetchToken(context);
      setState(() => _token = token);
    });
  }

  @override
  setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> createAndJoinMeeting(displayName) async {
    if (widget.course.courseType == 'live') {
      int totalMinuteLive = ((widget.course.end!.millisecondsSinceEpoch -
                  widget.course.start!.millisecondsSinceEpoch) /
              60000)
          .ceil();
      int? students = widget.course.studentCount ?? 0;
      int? minPoint = totalMinuteLive * students;
      await authProvider.getWallet();
      int? point = authProvider.wallet?.balance ?? 0;
      if (point >= minPoint) {
        await updateActualTime();
        try {
          var meetingID = await createMeeting(_token);
          if (mounted) {
            log('meeting ID: $meetingID');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TutorLiveClassroom(
                  token: _token,
                  userId: widget.course.tutorId!,
                  courseId: widget.course.courseId!,
                  startTime: widget.course.start!.millisecondsSinceEpoch,
                  meetingId: meetingID,
                  isHost: true,
                  displayName: displayName,
                  micEnabled: isMicOn,
                  camEnabled: false,
                ),
              ),
            );
          }
        } catch (error) {
          if (!mounted) return;
          showSnackBarMessage(
              message: 'ERROR ON CREATE ROOM ${error.toString()}',
              context: context);
        }
      } else {
        if (!mounted) return;
        showAlertRecordingDialog(
          context,
          title: 'Solve Coin ไม่เพียงพอ',
          detail:
              '\t\t\tSolve Coin ของคุณไม่เพียงพอสำหรับใช้เข้าสอนในคลาสนี้\nกรุณาติดต่อทีมงานดูแลลูกค้าได้ในเวลา 11.00-22.00 น.',
          confirm: 'ตกลง',
        );
      }
    } else {
      try {
        var meetingID = await createMeeting(_token);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TutorLiveClassroom(
                token: _token,
                userId: widget.course.tutorId!,
                courseId: widget.course.courseId!,
                startTime: widget.course.start!.millisecondsSinceEpoch,
                meetingId: meetingID,
                isHost: true,
                displayName: displayName,
                micEnabled: isMicOn,
                camEnabled: false,
              ),
            ),
          );
        }
      } catch (error) {
        showSnackBarMessage(
            message: 'ERROR ON CREATE ROOM ${error.toString()}',
            context: context);
      }
    }
  }

  Future<void> updateActualTime() async {
    await courseController.getCourseById(widget.course.courseId!);
    var now = DateTime.now();
    var calendars = courseController.courseData?.calendars;
    int indexToUpdate = calendars!.indexWhere((element) =>
        element.start?.compareTo(DateTime.fromMillisecondsSinceEpoch(
            widget.course.start!.millisecondsSinceEpoch)) ==
        0);

    if (indexToUpdate != -1) {
      calendars[indexToUpdate].actualStart = now;
    }
    if (!mounted) return;
    await courseController.updateSessionDetails(
        context, courseController.courseData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: CustomColors.whitePrimary,
        elevation: 6,
        leading: InkWell(
          onTap: () {
            isActive = false;
            Navigator.of(context).pop();
          },
          child: const Icon(
            Icons.close,
            color: Colors.black,
          ),
        ),
        title: Text(
          'รอเข้าห้องสอน',
          style: CustomStyles.bold22Black363636,
        ),
      ),
      persistentFooterButtons: [
        _util.isTablet() ? const SizedBox() : _footBar()
      ],
      backgroundColor: Colors.white,
      body: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  // setState(() {
                  //   isActive = !isActive;
                  // });
                },
                child: Image.asset(
                  'assets/images/time.png',
                  height: _util.isTablet() ? 72 : 32,
                ),
              ),
              S.h(_util.isTablet() ? 20 : 5),
              S.h(10),
              SizedBox(
                width: 300,
                child: Text(
                  widget.course.courseName ?? '',
                  textAlign: TextAlign.center,
                  style: CustomStyles.bold22Black363636,
                ),
              ),
              S.h(10),
              SizedBox(
                width: 300,
                child: Text(
                  widget.course.detailsText ?? '',
                  textAlign: TextAlign.center,
                  style: CustomStyles.med14Black363636,
                ),
              ),
              if (_util.isTablet()) ...[
                S.h(10),
                _timeJoin(),
                S.h(10),
                SizedBox(height: 100, child: _microphone()),
                S.h(10),
                _tutorTitle(),
                S.h(30),
                isActive
                    ? S.h(30)
                    : Countdown(
                        courseStart: widget.course.start!,
                        onActiveChanged: (bool value) {
                          setState(() {
                            isActive = value;
                          });
                        },
                      ),
                S.h(10),
                isActive ? _buttonJoinRoom() : _buttonNotYet(),
              ] else ...[
                SizedBox(height: 70, child: _microphone()),
                S.h(10),
                if (!isActive)
                  Countdown(
                    courseStart: widget.course.start!,
                    onActiveChanged: (bool value) {
                      setState(() {
                        isActive = value;
                      });
                    },
                  ),
              ],
              S.h(20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeJoin() {
    return Text(
      '${FormatDate.dayOnly(widget.course.start)}  ${FormatDate.timeOnlyNumber(widget.course.start)} น. - ${FormatDate.timeOnlyNumber(widget.course.end)} น.',
      style: _util.isTablet()
          ? CustomStyles.bold18Black363636
          : CustomStyles.med14Black363636,
    );
  }

  Widget _microphone() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(
        width: (_util.isTablet() ? 100 : 70),
        child: AnimatedBuilder(
          animation:
              CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
          builder: (context, child) {
            return Stack(alignment: Alignment.center, children: <Widget>[
              !isMicOn
                  ? const SizedBox()
                  : _buildContainer(
                      (_util.isTablet() ? 100 : 70) * _controller.value),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isMicOn = !isMicOn;
                    if (isMicOn) {
                      _controller = AnimationController(
                        vsync: this,
                        lowerBound: 0.5,
                        duration: const Duration(milliseconds: 1000),
                      )..repeat();
                    } else {
                      _controller.stop();
                    }
                    setState(() {});
                  });
                },
                child: Container(
                  padding: _util.isTablet()
                      ? const EdgeInsets.all(16.0)
                      : const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: !isMicOn ? Colors.redAccent : Colors.white,
                    border: Border.all(
                      color: !isMicOn
                          ? Colors.redAccent
                          : CustomColors.greenPrimary,
                      width: 2.5,
                    ),
                  ),
                  child: !isMicOn
                      ? Icon(
                          Icons.mic_off_outlined,
                          size: _util.isTablet() ? 24 : 25,
                          color: CustomColors.white,
                        )
                      : Icon(
                          Icons.mic_none,
                          size: _util.isTablet() ? 24 : 25,
                          color: CustomColors.greenPrimary,
                        ),
                ),
              ),
            ]);
          },
        ),
      ),
      Text(
        'เปิด/ปิด ไมโครโฟน',
        style: CustomStyles.bold18Black363636.copyWith(
          color: CustomColors.gray878787,
        ),
      ),
    ]);
  }

  Widget _tutorTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ติวเตอร์:',
          style: CustomStyles.bold18Black363636.copyWith(
            color: CustomColors.gray878787,
          ),
        ),
        const SizedBox(width: 10),
        _image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(Sizer(context).h * .1),
                child: Image.asset('assets/images/profile2.png',
                    width: Sizer(context).h * .15,
                    height: Sizer(context).h * .15,
                    fit: BoxFit.cover))
            : ClipRRect(
                borderRadius: BorderRadius.circular(Sizer(context).h * .1),
                child: CachedNetworkImage(
                  width: _util.isTablet()
                      ? Sizer(context).h / 14
                      : Sizer(context).h * .100,
                  height: _util.isTablet()
                      ? Sizer(context).h / 14
                      : Sizer(context).h * .100,
                  fit: BoxFit.cover,
                  imageUrl: authProvider.user?.image ?? "",
                  errorWidget: (context, url, error) =>
                      const CircleAvatar(child: Icon(CupertinoIcons.person)),
                ),
              ),
        const SizedBox(width: 10),
        Text(
          authProvider.user?.name ?? '',
          style: CustomStyles.med12GreenPrimary.copyWith(
            fontSize: _util.addMinusFontSize(16),
          ),
        ),
      ],
    );
  }

  Widget _buttonJoinRoom() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Material(
        child: InkWell(
          onTap: () async {
            createAndJoinMeeting(authProvider.user?.name ?? '');
          },
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
              color: CustomColors.green20B153,
            ),
            padding: _util.isTablet()
                ? const EdgeInsets.symmetric(vertical: 20, horizontal: 10.0)
                : const EdgeInsets.symmetric(vertical: 10, horizontal: 5.0),
            child: Row(
              children: [
                S.w(10),
                Text(
                  "เริ่มสอน",
                  style: CustomStyles.bold14White.copyWith(
                    fontSize: _util.addMinusFontSize(18),
                  ),
                ),
                S.w(10),
                Image.asset(
                  'assets/images/join.png',
                  scale: 3,
                ),
                S.w(10),
              ],
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buttonNotYet() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      InkWell(
        onTap: () async {},
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.circular(10),
            ),
            color: CustomColors.grayE5E6E9,
          ),
          padding: _util.isTablet()
              ? const EdgeInsets.symmetric(vertical: 20, horizontal: 10.0)
              : const EdgeInsets.symmetric(vertical: 10, horizontal: 5.0),
          child: Row(
            children: [
              S.w(10),
              Text(
                "ยังไม่ถึงเวลาสอน",
                style: CustomStyles.bold14White.copyWith(
                  fontSize: _util.addMinusFontSize(18),
                ),
              ),
              S.w(10),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _buildContainer(double radius) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green.withOpacity(1 - _controller.value),
      ),
    );
  }

  Widget _footBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _timeJoin(),
          _tutorTitle(),
          _buttonJoinRoom(),
        ],
      ),
    );
  }
}

class Countdown extends StatefulWidget {
  final DateTime courseStart;
  final ValueChanged<bool> onActiveChanged;

  const Countdown(
      {Key? key, required this.courseStart, required this.onActiveChanged})
      : super(key: key);

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  late Timer _timer;
  Duration _timeUntilStart = Duration.zero;
  static final _util = UtilityHelper();

  @override
  void initState() {
    super.initState();
    _timeUntilStart = widget.courseStart.difference(DateTime.now());
    _timer =
        Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
  }

  void _getTime() {
    final timeUntilStart = widget.courseStart.difference(DateTime.now());

    if (timeUntilStart <= const Duration(minutes: 5)) {
      widget.onActiveChanged(true); // Notify the parent widget
      _timer.cancel(); // Optionally, stop the timer
    }

    setState(() {
      _timeUntilStart = timeUntilStart;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      "คอร์สจะเริ่มในอีก ${_timeUntilStart.inHours} : ${(_timeUntilStart.inMinutes % 60).toString().padLeft(2, '0')} : ${(_timeUntilStart.inSeconds % 60).toString().padLeft(2, '0')}",
      style: _util.isTablet()
          ? CustomStyles.bold18Black363636
          : CustomStyles.med14Black363636,
    );
  }
}
