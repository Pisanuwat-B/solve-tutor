import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';

import 'package:videosdk/videosdk.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:sizer/sizer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../firebase/database.dart';
import '../../../nav.dart';
import '../../calendar/constants/custom_styles.dart';
import '../../calendar/controller/create_course_live_controller.dart';
import '../../calendar/widgets/alert_snackbar.dart';
import '../../calendar/widgets/sizebox.dart';
import '../components/close_dialog.dart';
import '../components/divider.dart';
import '../components/divider_vertical.dart';
import '../components/leaderboard.dart';
import '../../calendar/constants/assets_manager.dart';
import '../../calendar/constants/custom_colors.dart';
import '../../calendar/helper/utility_helper.dart';
import '../components/room_loading_screen.dart';
import '../components/view_all_student_mobile.dart';
import '../solvepad/solve_watch.dart';
import '../solvepad/solvepad_drawer.dart';
import '../solvepad/solvepad_stroke_model.dart';
import '../quiz/quiz_model.dart';
import '../utils/api.dart';
import '../utils/responsive.dart';

class TutorLiveClassroom extends StatefulWidget {
  final String meetingId, userId, token, displayName, courseId;
  final bool micEnabled, camEnabled, chatEnabled, isHost, isMock;
  final int startTime;
  const TutorLiveClassroom({
    Key? key,
    required this.meetingId,
    required this.userId,
    required this.token,
    required this.displayName,
    required this.isHost,
    required this.courseId,
    required this.startTime,
    this.micEnabled = true,
    this.camEnabled = false,
    this.chatEnabled = false,
    this.isMock = false,
  }) : super(key: key);

  @override
  State<TutorLiveClassroom> createState() => _LiveClassroomSolvepadState();
}

class _LiveClassroomSolvepadState extends State<TutorLiveClassroom> {
  // Conference
  bool isRecordingOn = false;
  bool isRecordingLoading = false;
  int recordIndex = 0;
  bool showChatSnackbar = false;
  String recordingState = "RECORDING_STOPPED";
  late Room meeting;
  bool _joined = false;
  Stream? shareStream;
  Stream? videoStream;
  Stream? audioStream;
  bool fullScreen = false;

  // WSS
  WebSocketChannel? channel;
  final dataTextController = TextEditingController();
  List<dynamic> data = [];
  bool allowSending = true;

  // Screen and tools
  bool _switchValue = true;
  bool _switchShareValue = true;
  bool micEnable = false;
  bool displayEnable = false;
  bool showStudent = false;
  bool selectedTools = false;
  bool openColors = false;
  bool openLines = false;
  bool openMore = false;
  bool enableDisplay = true;
  int _selectedIndexTools = 0;
  int _selectedIndexColors = 0;
  int _selectedIndexLines = 0;
  late bool isSelected;
  bool isChecked = false;
  int _studentColorIndex = 0;
  int _studentStrokeWidthIndex = 0;
  bool _requestScreenShare = false;
  bool _isViewingFocusStudent = false;
  String focusedStudentId = '';
  String focusedStudentName = '';

  final List _listLines = [
    {
      "image_active": ImageAssets.line1Active,
      "image_dis": ImageAssets.line1Dis,
    },
    {
      "image_active": ImageAssets.line2Active,
      "image_dis": ImageAssets.line2Dis,
    },
    {
      "image_active": ImageAssets.line3Active,
      "image_dis": ImageAssets.line3Dis,
    },
  ];
  final List _listColors = [
    {"color": ImageAssets.pickRed},
    {"color": ImageAssets.pickBlack},
    {"color": ImageAssets.pickGreen},
    {"color": ImageAssets.pickYellow}
  ];
  final List _strokeColors = [
    Colors.red,
    Colors.black,
    Colors.green,
    Colors.yellow,
  ];
  final List _strokeWidths = [1.0, 2.0, 5.0];
  final List _listTools = [
    {
      "image_active": ImageAssets.handActive,
      "image_dis": ImageAssets.handDis,
    },
    {
      "image_active": ImageAssets.pencilActive,
      "image_dis": ImageAssets.pencilDis,
    },
    {
      "image_active": ImageAssets.highlightActive,
      "image_dis": ImageAssets.highlightDis,
    },
    {
      "image_active": ImageAssets.rubberActive,
      "image_dis": ImageAssets.rubberDis,
    },
    // {
    //   "image_active": ImageAssets.laserPenActive,
    //   "image_dis": ImageAssets.laserPenDis,
    // }
  ];

  List<SelectQuizModel> quizList = [
    SelectQuizModel("ชุดที่#1 สมการเชิงเส้นตัวแปรเดียว", "1 ข้อ", false),
    SelectQuizModel("ชุดที่#2 สมการเชิงเส้น 2 ตัวแปร", "10 ข้อ", false),
    SelectQuizModel("ชุดที่#3  สมการจำนวนเชิงซ้อน", "5 ข้อ", false),
    SelectQuizModel("ชุดที่#4 สมการเชิงเส้นตัวแปรเดียว", "5 ข้อ", false),
    SelectQuizModel("ชุดที่#5 สมการเชิงเส้นตัวแปรเดียว", "5 ข้อ", false),
  ];
  QuizSet quizSetData = QuizSet(
    quizSetName: 'Thai Geology',
    quizQuestions: [
      QuizQuestion(
        questionText: "What's the name of Thailand's capital?",
        choices: ['Vientiane', 'Bangkok', 'Hanoi', 'Yangon'],
        correctChoice: 'Bangkok',
      ),
      QuizQuestion(
        questionText: "How many provinces are there in Thailand?",
        choices: ['70', '75', '76', '77'],
        correctChoice: '77',
      )
    ],
  );
  int focusQuestion = 0;
  int radioTest = 0;
  List students = [];
  List studentsDisplay = [
    {
      "image": ImageAssets.avatarMen,
      "name": "My Screen",
      "status_txt": "Sharing screen...",
      "share_now": "N",
      "status_share": "enable",
    },
    {
      "image": ImageAssets.avatarWomen,
      "name": "Dianne Russel",
      "status_txt": "Sharing screen...",
      "share_now": "Y",
      "status_share": "enable",
    },
    {
      "image": ImageAssets.avatarWomen,
      "name": "Darlene Robertson",
      "status_txt": "Sharing screen...",
      "share_now": "N",
      "status_share": "enable",
    },
    {
      "image": ImageAssets.avatarMen,
      "name": "Marvin McKinney",
      "status_txt": "Sharing screen...",
      "share_now": "N",
      "status_share": "enable",
    },
    {
      "image": ImageAssets.avatarWomen,
      "name": "Kathryn Murphy",
      "status_txt": "Sharing screen...",
      "share_now": "N",
      "status_share": "enable",
    },
    {
      "image": ImageAssets.avatarDisWomen,
      "name": "Bessie Cooper",
      "status_txt": "Not sharing",
      "share_now": "N",
      "status_share": "disable",
    },
    {
      "image": ImageAssets.avatarDisMen,
      "name": "Jacob Jones",
      "status_txt": "Not sharing",
      "share_now": "N",
      "status_share": "disable",
    },
    {
      "image": ImageAssets.avatarDisMen,
      "name": "Ralph Edwards",
      "status_txt": "Not sharing",
      "share_now": "N",
      "status_share": "disable",
    },
  ];

  // ---------- VARIABLE: Solve Pad data
  late List<String> _pages = [];
  final List<List<SolvepadStroke?>> _penPoints = [[]];
  final List<List<SolvepadStroke?>> _laserPoints = [[]];
  final List<List<SolvepadStroke?>> _highlighterPoints = [[]];
  final List<List<SolvepadStroke?>> _studentPenPoints = [[]];
  final List<List<SolvepadStroke?>> _studentLaserPoints = [[]];
  final List<List<SolvepadStroke?>> _studentHighlighterPoints = [[]];
  final List<Offset> _eraserPoints = [const Offset(-100, -100)];
  final List<Offset> _studentEraserPoints = [const Offset(-100, -100)];
  final List<List<Offset?>> _replayPoints = [[]];
  DrawingMode _mode = DrawingMode.drag;
  DrawingMode _studentMode = DrawingMode.drag;
  final SolveStopwatch solveStopwatch = SolveStopwatch();
  Size studentSolvepadSize = const Size(1059.0, 547.0);
  Size mySolvepadSize = const Size(1059.0, 547.0);
  double sheetImageRatio = 0.708;
  double studentImageWidth = 0;
  double studentExtraSpaceX = 0;
  double myImageWidth = 0;
  double myExtraSpaceX = 0;
  double scaleImageX = 0;
  double scaleX = 0;
  double scaleY = 0;

  // ---------- VARIABLE: Solve Pad features
  int? activePointerId;
  bool _isPrevBtnActive = false;
  bool _isNextBtnActive = true;
  bool _isStylusActive = false;

  // ---------- VARIABLE: page control
  String _formattedElapsedTime = ' 00 : 00 : 00 ';
  Timer? _laserTimer;
  Timer? _studentLaserTimer;
  Timer? _meetingTimer;
  int _currentPage = 0;
  final PageController _pageController = PageController();
  final List<TransformationController> _transformationController = [];
  var courseController = CourseLiveController();
  late AuthProvider authProvider;
  late String courseName;
  late String courseType;
  bool isSheetReady = false;
  bool isLiveCourseReady = false;

  // ---------- VARIABLE: message control
  late Map<String, Function(String)> handlers;

  // ---------- VARIABLE: data collection
  FirebaseService firebaseService = FirebaseService();
  late Map<String, dynamic> _data;
  String jsonData = '';
  late List<Map<String, dynamic>> _actions;
  List<StrokeStamp> currentStroke = [];
  List<dynamic> currentEraserStroke = [];
  List<ScrollZoomStamp> currentScrollZoom = [];
  double currentScale = 2.0;
  double currentScrollX = 0;
  double currentScrollY = 0;
  bool isUploading = false;

  /// TODO: Get rid of all Mockup reference
  @override
  void initState() {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
      SystemUiOverlay.bottom,
    ]);
    SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
      await Future.delayed(const Duration(seconds: 3));
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
        SystemUiOverlay.bottom,
      ]);
    });
    initTimer();
    initPagingBtn();
    if (!widget.isMock) {
      startDataPreparation();
    } else {
      courseType = 'live';
      isLiveCourseReady = true;
      _joined = true;
      mockInitPageData();
    }
  }

  void startDataPreparation() async {
    await initPagesData();
    initMessageHandler();
    initConference();
  }

  void mockInitPageData() {
    setState(() {
      _pages = [
        'https://firebasestorage.googleapis.com/v0/b/solve-f1778.appspot.com/o/test(gun)%2FexampleSheet1.jpg?alt=media&token=27676570-4031-4c6b-b6bc-4280fbbcd116',
        'https://firebasestorage.googleapis.com/v0/b/solve-f1778.appspot.com/o/test(gun)%2FexampleSheet2.jpg?alt=media&token=8ec3a135-85a6-4cac-abdd-b8d0df094ce3',
      ];
      for (int i = 1; i < 2; i++) {
        _addPage();
      }
      courseName = 'Mockup Test';
      micEnable = false;
      isSheetReady = true;
    });
  }

  Future<void> initPagesData() async {
    await courseController.getCourseById(widget.courseId);
    setState(() {
      if (courseController.courseData?.document?.data?.docFiles == null) {
        _pages = [
          'https://firebasestorage.googleapis.com/v0/b/solve-f1778.appspot.com/o/default_image%2Fa4.png?alt=media&token=01e0d9ac-15ed-4a62-886d-288c60ec1ee6',
          'https://firebasestorage.googleapis.com/v0/b/solve-f1778.appspot.com/o/default_image%2Fa4.png?alt=media&token=01e0d9ac-15ed-4a62-886d-288c60ec1ee6',
          'https://firebasestorage.googleapis.com/v0/b/solve-f1778.appspot.com/o/default_image%2Fa4.png?alt=media&token=01e0d9ac-15ed-4a62-886d-288c60ec1ee6',
          'https://firebasestorage.googleapis.com/v0/b/solve-f1778.appspot.com/o/default_image%2Fa4.png?alt=media&token=01e0d9ac-15ed-4a62-886d-288c60ec1ee6',
          'https://firebasestorage.googleapis.com/v0/b/solve-f1778.appspot.com/o/default_image%2Fa4.png?alt=media&token=01e0d9ac-15ed-4a62-886d-288c60ec1ee6',
        ];
        for (int i = 1; i < 5; i++) {
          _addPage();
        }
      } else {
        _pages = courseController.courseData!.document!.data!.docFiles!;
        updateRatio(_pages[0]);
        for (int i = 1; i < _pages.length; i++) {
          _addPage();
        }
      }
      courseName = courseController.courseData!.courseName!;
      courseType = courseController.courseData!.courseType!;
      micEnable = widget.micEnabled;
      isSheetReady = true;
      setLiveCourseLoadState();
    });
    var courseStudents = courseController.courseData!.studentDetails;
    List<Map<String, dynamic>>? studentsJson =
        courseStudents?.map((student) => student.toJson()).toList();
    if (studentsJson != null) {
      students = studentsJson.cast<dynamic>();
    }
    setNullStart();
    setState(() {});
  }

  void setNullStart() {
    _penPoints[0].add(null);
    _highlighterPoints[0].add(null);
    _laserPoints[0].add(null);
  }

  void setLiveCourseLoadState() async {
    if (isSheetReady && _joined) {
      setState(() {
        isLiveCourseReady = true;
      });
      // await meeting.startRecording(config: {"mode": "audio"});
    }
  }

  void initTimer() {
    _meetingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _formattedElapsedTime = _formatElapsedTime(solveStopwatch.elapsed);
      });
    });
  }

  void initPagingBtn() {
    if (_pages.length == 1) {
      _isPrevBtnActive = false;
      _isNextBtnActive = false;
    } else {
      _pageController.addListener(() {
        _isPrevBtnActive = (_pageController.page! > 0);
        _isNextBtnActive = _pageController.page! < (_pages.length - 1);
        setState(() {});
      });
    }
  }

  void initSolvepadScaling(double solvepadWidth, double solvepadHeight) {
    studentImageWidth = studentSolvepadSize.height * sheetImageRatio;
    studentExtraSpaceX = (studentSolvepadSize.width - studentImageWidth) / 2;
    mySolvepadSize = Size(solvepadWidth, solvepadHeight);
    myImageWidth = mySolvepadSize.height * sheetImageRatio;
    myExtraSpaceX = (mySolvepadSize.width - myImageWidth) / 2;
    scaleImageX = myImageWidth / studentImageWidth;
    scaleX = mySolvepadSize.width / studentSolvepadSize.width;
    scaleY = mySolvepadSize.height / studentSolvepadSize.height;
    initSolvepadData();
  }

  void initConference() {
    Room room = VideoSDK.createRoom(
        roomId: widget.meetingId,
        token: widget.token,
        displayName: widget.displayName,
        micEnabled: widget.micEnabled,
        camEnabled: false,
        maxResolution: 'hd',
        multiStream: true,
        defaultCameraIndex: 1,
        notification: const NotificationInfo(
          title: "Video SDK",
          message: "Video SDK is sharing screen in the meeting",
          icon: "notification_share", // drawable icon name
        ),
        mode: Mode.CONFERENCE);
    registerMeetingEvents(room);
    room.join();
  }

  void initWss() {
    channel = WebSocketChannel.connect(
      Uri.parse(
          'ws://34.143.240.238:3000/${widget.courseId}/${widget.startTime}'),
    );

    channel?.stream.listen((message) {
      // if (_requestScreenShare) {
      if (!mounted) return;
      setState(() {
        var decodedMessage = json.decode(message);
        // log('json message');
        // log(decodedMessage.toString());

        var item = decodedMessage[0];
        var data = item['data'];
        var uid = item['uid'];

        if (uid != focusedStudentId &&
            !data.startsWith('StudentShareScreen') &&
            !data.startsWith('RequestSolvepadSize')) {
          return;
        }
        if (data.startsWith('StudentShareScreen')) {
          var parts = data.split(':');
          var status = parts[1];
          double solvepadWidth = mySolvepadSize.width;
          double solvepadHeight = mySolvepadSize.height;
          if (status == 'enable') {
            solvepadWidth = double.parse(parts[2]);
            solvepadHeight = double.parse(parts[3]);
            _isViewingFocusStudent = true;
          } else {
            focusedStudentId = '';
            focusedStudentName = '';
            cleanStudentSolvepad();
          }
          updateStudentData(uid, status, solvepadWidth, solvepadHeight);
        } // listen to student drawing
        else if (data.startsWith('RequestSolvepadSize')) {
          sendMessage(
            'SetSolvepad:${mySolvepadSize.width}:${mySolvepadSize.height}',
            solveStopwatch.elapsed.inMilliseconds,
          );
          if (students.isEmpty) return;
          var studentIndex = getStudentIndex(uid);
          if (studentIndex == -1) {
            log('ID not found');
            log('${students.length}');
          } else {
            setState(() {
              students[studentIndex]['attend'] = true;
            });
          }
        } else {
          for (var entry in handlers.entries) {
            if (data.startsWith(entry.key)) {
              entry.value(data);
              break;
            }
          }
        }
      });
      // }
    });
  }

  void initSolvepadData() {
    solveStopwatch.reset();
    solveStopwatch.start();
    _data = {
      "version": "2.0.0",
      "solvepadWidth": mySolvepadSize.width,
      "solvepadHeight": mySolvepadSize.height,
      "metadata": {
        "courseId": widget.courseId,
        "tutorId": widget.userId,
        "duration": 0,
      },
      "actions": []
    };
    _actions = (_data['actions'] as List).cast<Map<String, dynamic>>();
    _actions.add({
      "time": solveStopwatch.elapsed.inMilliseconds,
      "type": "start-recording",
      "page": _currentPage,
      "scrollX": currentScrollX,
      "scrollY": currentScrollY,
      "scale": currentScale,
    });
  }

  void initMessageHandler() {
    handlers = {
      'Offset': handleMessageOffset,
      'Erase': handleMessageErase,
      'null': handleMessageNull,
      'DrawingMode': handleMessageDrawingMode,
      'StrokeColor': handleMessageStrokeColor,
      'StrokeWidth': handleMessageStrokeWidth,
      'ScrollZoom': handleMessageScrollZoom,
      'ChangePage': handleMessageChangePage,
      'InstantArt': handleMessageInstantArt,
    };
  }

  void handleMessageOffset(String data) {
    var offset = convertToOffset(data);
    Color strokeColor = _strokeColors[_studentColorIndex];
    double strokeWidth = _strokeWidths[_studentStrokeWidthIndex];
    switch (_studentMode) {
      case DrawingMode.drag:
        break;
      case DrawingMode.pen:
        _studentPenPoints[_currentPage]
            .add(SolvepadStroke(offset, strokeColor, strokeWidth));
        break;
      case DrawingMode.laser:
        _studentLaserPoints[_currentPage]
            .add(SolvepadStroke(offset, strokeColor, strokeWidth));
        _studentLaserDrawing();
        break;
      case DrawingMode.highlighter:
        _studentHighlighterPoints[_currentPage]
            .add(SolvepadStroke(offset, strokeColor, strokeWidth));
        break;
      case DrawingMode.eraser:
        _studentEraserPoints[_currentPage] = offset;
        break;
      default:
        break;
    }
  }

  void handleMessageErase(String data) {
    var parts = data.split('.');
    var index = int.parse(parts.last);
    if (data.startsWith('Erase.pen')) {
      removePointStack(_studentPenPoints[_currentPage], index);
    } else if (data.startsWith('Erase.high')) {
      removePointStack(_studentHighlighterPoints[_currentPage], index);
    }
  }

  void handleMessageNull(String data) {
    switch (_studentMode) {
      case DrawingMode.drag:
        break;
      case DrawingMode.pen:
        _studentPenPoints[_currentPage].add(null);
        break;
      case DrawingMode.laser:
        _studentLaserPoints[_currentPage].add(null);
        _studentLaserTimer =
            Timer(const Duration(milliseconds: 1500), _studentStopLaserDrawing);
        break;
      case DrawingMode.highlighter:
        _studentHighlighterPoints[_currentPage].add(null);
        break;
      case DrawingMode.eraser:
        _studentEraserPoints[_currentPage] = const Offset(-100, -100);
        break;
      default:
        break;
    }
  }

  void handleMessageDrawingMode(String data) {
    String modeString = data.replaceAll('DrawingMode.', '');
    DrawingMode drawingMode = DrawingMode.values.firstWhere(
        (e) => e.toString() == 'DrawingMode.$modeString',
        orElse: () => DrawingMode.drag);
    _studentMode = drawingMode;
  }

  void handleMessageStrokeColor(String data) {
    var parts = data.split('.');
    var index = int.parse(parts.last);
    _studentColorIndex = index;
  }

  void handleMessageStrokeWidth(String data) {
    var parts = data.split('.');
    var index = int.parse(parts.last);
    _studentStrokeWidthIndex = index;
  }

  void handleMessageScrollZoom(String data) {
    var parts = data.split(':');
    var scrollX = double.parse(parts[1]);
    var scrollY = double.parse(parts[2]);
    var zoom = double.parse(parts.last);
    _transformationController[_currentPage].value = Matrix4.identity()
      ..translate(scaleScrollX(scrollX), scaleScrollY(scrollY))
      ..scale(zoom);
  }

  void handleMessageChangePage(String data) {
    var parts = data.split(':');
    var pageNumber = int.parse(parts.last);
    if (_currentPage != pageNumber) {
      _pageController.animateToPage(
        pageNumber,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void handleMessageInstantArt(String data) {
    var parts = data.split('|');
    var page = int.parse(parts[1]);
    var scrollX = double.parse(parts[2]);
    var scrollY = double.parse(parts[3]);
    var zoom = double.parse(parts[4]);
    var pen = parts[5];
    var high = parts[6];
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _transformationController[page].value = Matrix4.identity()
      ..translate(scaleScrollX(scrollX), scaleScrollY(scrollY))
      ..scale(zoom);

    List decodedPen = jsonDecode(pen);
    _studentPenPoints[page] = decodedPen.map<SolvepadStroke?>((stroke) {
      if (stroke == null) {
        return null;
      } else {
        Offset scaledOffset =
            scaleOffset(Offset(stroke['offset']['dx'], stroke['offset']['dy']));
        Color color = Color(int.parse(stroke['color'], radix: 16));
        return SolvepadStroke(scaledOffset, color, stroke['width']);
      }
    }).toList();
    List decodedHigh = jsonDecode(high);
    _studentHighlighterPoints[page] =
        decodedHigh.map<SolvepadStroke?>((stroke) {
      if (stroke == null) {
        return null;
      } else {
        Offset scaledOffset =
            scaleOffset(Offset(stroke['offset']['dx'], stroke['offset']['dy']));
        Color color = Color(int.parse(stroke['color'], radix: 16));
        return SolvepadStroke(scaledOffset, color, stroke['width']);
      }
    }).toList();
  }

  Offset convertToOffset(String offsetString) {
    final matched = RegExp(r'Offset\((.*), (.*)\)').firstMatch(offsetString);
    final dx = double.tryParse(matched!.group(1)!);
    final dy = double.tryParse(matched.group(2)!);
    var returnOffset = Offset(dx!, dy!);
    return scaleOffset(returnOffset);
  }

  Offset scaleOffset(Offset offset) {
    double studentWidth = studentSolvepadSize.width;
    double studentHeight = studentSolvepadSize.height;
    double studentImageWidth = studentHeight * sheetImageRatio;
    double studentExtraSpaceX = (studentWidth - studentImageWidth) / 2;

    double myWidth = mySolvepadSize.width;
    double myHeight = mySolvepadSize.height;
    double myImageWidth = myHeight * sheetImageRatio;
    double myExtraSpaceX = (myWidth - myImageWidth) / 2;
    // double diffExtraSpaceX = myExtraSpaceX - hostExtraSpaceX;

    double scaleImageX = myImageWidth / studentImageWidth;
    double scaleY = myHeight / studentHeight;

    return Offset(
        (offset.dx - studentExtraSpaceX) * scaleImageX + myExtraSpaceX,
        offset.dy * scaleY);
  }

  double scaleScrollX(double scrollX) => scrollX * scaleX;
  double scaleScrollY(double scrollY) => scrollY * scaleY;

  void updateStudentData(String userId, String status,
      [double solvepadWidth = 1059, double solvepadHeight = 547]) {
    for (var student in students) {
      if (student['id'] == userId) {
        setState(() {
          student['status_share'] = status;
          if (status == 'enable') {
            student['solvepad_size'] = '$solvepadWidth,$solvepadHeight';
          }
        });
        break;
      }
    }
  }

  void changeSolvepadScaling(double solvepadWidth, double solvepadHeight) {
    setState(() {
      studentSolvepadSize = Size(solvepadWidth, solvepadHeight);
      studentImageWidth = solvepadHeight * sheetImageRatio;
      studentExtraSpaceX = (solvepadWidth - studentImageWidth) / 2;
      myImageWidth = mySolvepadSize.height * sheetImageRatio;
      myExtraSpaceX = (mySolvepadSize.width - myImageWidth) / 2;
      scaleImageX = myImageWidth / studentImageWidth;
      scaleX = mySolvepadSize.width / studentSolvepadSize.width;
      scaleY = mySolvepadSize.height / studentSolvepadSize.height;
    });
  }

  void cleanStudentSolvepad() {
    setState(() {
      for (var list in _studentPenPoints) {
        list.clear();
      }
      for (var list in _studentLaserPoints) {
        list.clear();
      }
      for (var list in _studentHighlighterPoints) {
        list.clear();
      }
      _studentMode = DrawingMode.drag;
    });
  }

  void clearCurrentReviewData() {
    currentStroke.clear();
    currentEraserStroke.clear();
    currentScrollZoom.clear();
  }

  // ---------- FUNCTION: Solvepad Data Collection
  void addDrawing(List<StrokeStamp> strokeStamp, int initTime) {
    _actions.add({
      "time": initTime,
      "type": "drawing",
      "data": {
        "tool": _mode.toString(),
        "color": _strokeColors[_selectedIndexColors].value.toRadixString(16),
        "strokeWidth": _strokeWidths[_selectedIndexLines],
        "points": strokeStamp
            .map((timedOffset) => {
                  'x': double.parse(timedOffset.offset.dx.toStringAsFixed(2)),
                  'y': double.parse(timedOffset.offset.dy.toStringAsFixed(2)),
                  'time': timedOffset.timestamp,
                })
            .toList()
      }
    });
  }

  void addErasing(List<dynamic> eraserStroke) {
    if (eraserStroke.isNotEmpty) {
      List<Map<String, dynamic>> formattedActions = [];
      List<Map<String, dynamic>> moveActions = [];

      for (var action in eraserStroke) {
        if (action[0] is Offset) {
          moveActions.add({
            'x': double.parse(action[0].dx.toStringAsFixed(2)),
            'y': double.parse(action[0].dy.toStringAsFixed(2)),
            'time': action[1],
          });
        } else if (action[0] is String) {
          if (moveActions.isNotEmpty) {
            formattedActions.add({
              'action': 'moves',
              'points': moveActions,
            });
            moveActions = [];
          }

          formattedActions.add({
            'action': 'erase',
            'mode': action[0].toString(),
            'prev': action[1],
            'next': action[2],
            'time': action[3],
          });
        }
      }

      if (moveActions.isNotEmpty) {
        formattedActions.add({
          'action': 'moves',
          'points': moveActions,
        });
      }

      _actions.add({
        "time": eraserStroke[0][1],
        "type": "erasing",
        "data": formattedActions,
      });
    }
  }

  void addScrollZoom(List<ScrollZoomStamp> scrollZoomStamp, int initTime) {
    log('add scroll-zoom');
    _actions.add({
      "time": initTime,
      "type": "scroll-zoom",
      "data": scrollZoomStamp
          .map((timedScroll) => {
                'x': double.parse(timedScroll.x.toStringAsFixed(2)),
                'y': double.parse(timedScroll.y.toStringAsFixed(2)),
                'scale': double.parse(timedScroll.scale.toStringAsFixed(2)),
                'time': timedScroll.timestamp,
              })
          .toList(),
    });
  }

  Future<void> writeToFile(String fileName, dynamic data) async {
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    final file = File('$tempPath/$fileName');
    final json = jsonEncode(data);
    file.writeAsString(json);
  }

  Future<void> updateSolvepadData(String solvepadUrl) async {
    var calendars = courseController.courseData?.calendars;
    int indexToUpdate = calendars!.indexWhere((element) =>
        element.start?.compareTo(
            DateTime.fromMillisecondsSinceEpoch(widget.startTime)) ==
        0);

    if (indexToUpdate != -1) {
      calendars[indexToUpdate].reviewFile = solvepadUrl;
      await courseController.updateSessionDetails(
          context, courseController.courseData);
    }
  }

  Future<void> endSolvepadDataCollection() async {
    if (currentScrollZoom.isNotEmpty) {
      addScrollZoom(currentScrollZoom, currentScrollZoom[0].timestamp);
      currentScrollZoom.clear();
    }
    _actions.add({
      "time": solveStopwatch.elapsed.inMilliseconds,
      "type": "stop-recording",
      "data": null
    });
    int replayDuration = solveStopwatch.elapsed.inMilliseconds;
    _data['metadata']['duration'] = replayDuration;
    await writeToFile('solvepad.txt', _data);
    String uploadUrl = await firebaseService
        .uploadLiveSolvepad('${widget.courseId}_${widget.startTime}');
    await updateSolvepadData(uploadUrl);
  }

  @override
  dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.portraitDown,
    //   DeviceOrientation.landscapeRight,
    //   DeviceOrientation.landscapeLeft,
    // ]);
    _pageController.dispose();
    _meetingTimer?.cancel();
    super.dispose();
  }

  // ---------- FUNCTION: WSS
  void closeChanel() {
    channel?.sink.close();
  }

  void sendMessage(dynamic data, int time) {
    if (widget.isMock) return;
    try {
      final message =
          json.encode({'uid': widget.userId, 'data': data, 'time': time});
      channel?.sink.add(message);
    } catch (e) {
      log('Error sending message: $e');
    }
  }

  // ---------- FUNCTION: conference
  int getStudentIndex(String studentId) {
    for (int i = 0; i < students.length; i++) {
      if (students[i]['id'] == studentId) {
        return i;
      }
    }
    return -1; // Return -1 if the student with the given ID is not found
  }

  void registerMeetingEvents(Room _meeting) {
    // Called when joined in meeting
    _meeting.on(
      Events.roomJoined,
      () {
        setState(() {
          meeting = _meeting;
          _joined = true;
          setLiveCourseLoadState();
          updateMeetingCode();
          // meeting.startRecording(config: {"mode": "audio"});
          initWss();
        });
      },
    );

    _meeting.on(Events.participantJoined, (Participant participant) {
      log('Student Join');
      log(participant.displayName);
      log(participant.id);
    });

    _meeting.on(Events.participantLeft, (Participant participant) {
      log('Student Left');
      log(participant.displayName);
      log(participant.id);
    });

    // Called when meeting is ended
    _meeting.on(Events.roomLeft, (String? errorMsg) {
      if (errorMsg != null) {
        log("Meeting left due to $errorMsg !!");
      }
      // Navigator.pushAndRemoveUntil(
      //     context,
      //     MaterialPageRoute(builder: (context) => const JoinScreen()),
      //     (route) => false);
    });

    // Called when recording is started
    _meeting.on(Events.recordingStateChanged, (String status) async {
      log('Conference Recording Changed');
      log(status);
      setState(() {
        recordingState = status;
      });
      switch (status) {
        case 'RECORDING_STOPPED':
          setState(() {
            isRecordingLoading = false;
            isRecordingOn = false;
          });
          log('RECORDING_STOPPED:$recordIndex');
          sendMessage('RECORDING_STOPPED:$recordIndex',
              solveStopwatch.elapsed.inMilliseconds);
          await fetchRecording(widget.meetingId);
          break;
        case 'RECORDING_STOPPING':
          setState(() {
            isRecordingLoading = true;
          });
          break;
        case 'RECORDING_STARTING':
          setState(() {
            isRecordingLoading = true;
          });
          break;
        case 'RECORDING_STARTED':
          setState(() {
            isRecordingLoading = false;
            isRecordingOn = true;
          });
          log('RECORDING_STARTED:$recordIndex');
          sendMessage('RECORDING_STARTED:$recordIndex',
              solveStopwatch.elapsed.inMilliseconds);
          clearCurrentReviewData();
          initSolvepadData();
          break;
        default:
      }
    });

    // Called when stream is enabled
    _meeting.localParticipant.on(Events.streamEnabled, (Stream _stream) {
      if (_stream.kind == 'audio') {
        setState(() {
          audioStream = _stream;
        });
      }
    });

    // Called when stream is disabled
    _meeting.localParticipant.on(Events.streamDisabled, (Stream _stream) {
      if (_stream.kind == 'video' && videoStream?.id == _stream.id) {
        setState(() {
          videoStream = null;
        });
      } else if (_stream.kind == 'audio' && audioStream?.id == _stream.id) {
        setState(() {
          audioStream = null;
        });
      } else if (_stream.kind == 'share' && shareStream?.id == _stream.id) {
        setState(() {
          shareStream = null;
        });
      }
    });

    _meeting.on(
      Events.error,
      (error) => {
        log('meeting function error'),
        log(error['name'].toString()),
        log(error['message'].toString()),
        if (error['name'] == 'START_RECORDING_FAILED')
          {
            showSnackBar(
                context,
                'ERROR_RECORDING_FAILED: เกิดปัญหาทางเทคนิค ไม่สามารถบันทึกได้',
                'red'),
          }
      },
    );
  }

  Future<void> fetchRecording(meetingID) async {
    try {
      List recordList = [];
      var record = await fetchRecordings(widget.token, meetingID);
      log('record fetched: $record');
      recordIndex += 1;
      record.forEach((r) {
        if (r['file'] != null) {
          recordList.add(r['file']['fileUrl']);
        }
      });
      log(recordList.toString());
      await updateAudioFile(recordList);
    } catch (error) {
      log('fetchRecording error: $error');
    }
  }

  Future<void> updateAudioFile(recordList) async {
    var calendars = courseController.courseData?.calendars;
    int indexToUpdate = calendars!.indexWhere((element) =>
        element.start?.compareTo(
            DateTime.fromMillisecondsSinceEpoch(widget.startTime)) ==
        0);

    if (indexToUpdate != -1) {
      calendars[indexToUpdate].audioFile = recordList;
      await courseController.updateSessionDetails(
          context, courseController.courseData);
    }
  }

  Future<void> updateActualTime() async {
    var now = DateTime.now();
    int? duration;
    var calendars = courseController.courseData?.calendars;
    int indexToUpdate = calendars!.indexWhere((element) =>
        element.start?.compareTo(
            DateTime.fromMillisecondsSinceEpoch(widget.startTime)) ==
        0);

    if (indexToUpdate != -1) {
      calendars[indexToUpdate].actualEnd = now;
      duration = ((now.millisecondsSinceEpoch -
                  calendars[indexToUpdate]
                      .actualStart!
                      .millisecondsSinceEpoch) /
              60000)
          .ceil();
      calendars[indexToUpdate].liveDuration = duration;
      await courseController.updateSessionDetails(
          context, courseController.courseData);
      if (courseType == 'live') {
        int students = courseController.courseData?.studentIds?.length ?? 0;
        await updateBalanceAndLiveDuration(duration, students);
      }
    }
  }

  Future<void> updateBalanceAndLiveDuration(int duration, int student) async {
    int cost = duration * student;
    int value = authProvider.wallet!.balance! - cost;
    int walletDuration = duration + (authProvider.wallet!.liveDuration ?? 0);
    await authProvider.updateWalletBalance(value, walletDuration);
    int userDuration = duration + (authProvider.user!.liveDuration ?? 0);
    await authProvider.updateLiveDuration(userDuration);
    authProvider.getSelfInfo();
  }

  Future<bool> _onWillPopScope() async {
    log('live on will pop');
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    if (widget.isMock) {
      Navigator.pop(context);
    }
    closeChanel();
    meeting.leave();
    return true;
  }

  void updateMeetingCode() {
    FirebaseFirestore.instance
        .collection('course_live')
        .doc(widget.courseId)
        .update({'currentMeetingCode': meeting.id});
  }

  void updateRatio(String url) {
    Image image = Image.network(url);
    image.image
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      double ratio = info.image.width / info.image.height;
      sheetImageRatio = ratio;
    }));
  }

  // ---------- FUNCTION: solve pad feature
  double square(double x) => x * x;
  double sqrDistanceBetween(Offset p1, Offset p2) =>
      square(p1.dx - p2.dx) + square(p1.dy - p2.dy);

  int countNullOccurrences(List<SolvepadStroke?> strokeArray, int strokeIndex) {
    int nullOccurrences = 0;
    for (int i = 0; i < strokeIndex; i++) {
      if (strokeArray[i] == null) {
        nullOccurrences++;
      }
    }

    return nullOccurrences;
  }

  void doErase(int index, DrawingMode mode) {
    List<SolvepadStroke?> pointStack;
    String removeMode = 'pen';
    if (mode == DrawingMode.pen) {
      pointStack = _penPoints[_currentPage];
    } // pen
    else if (mode == DrawingMode.highlighter) {
      removeMode = 'high';
      pointStack = _highlighterPoints[_currentPage];
    } // high
    else {
      pointStack = _penPoints[_currentPage];
    }
    int nullCount = countNullOccurrences(pointStack, index);
    removePointStack(pointStack, index, removeMode: removeMode);
    log('Erase.$removeMode.$nullCount');
    sendMessage(
      'Erase.$removeMode.$nullCount',
      solveStopwatch.elapsed.inMilliseconds,
    );
  }

  void removePointStack(List<SolvepadStroke?> pointStack, int index,
      {String? removeMode}) {
    int prevNullIndex = -1;
    int nextNullIndex = -1;
    for (int i = index; i >= 0; i--) {
      if (pointStack[i]?.offset == null) {
        prevNullIndex = i;
        break;
      }
      if (i == 0) prevNullIndex = i;
    }
    for (int i = index; i < pointStack.length; i++) {
      if (pointStack[i]?.offset == null) {
        nextNullIndex = i;
        break;
      }
    }
    if (prevNullIndex != -1 && nextNullIndex != -1) {
      setState(() {
        pointStack.removeRange(prevNullIndex, nextNullIndex);
      });
      if (removeMode != null) {
        currentEraserStroke.add([
          removeMode,
          prevNullIndex,
          nextNullIndex,
          solveStopwatch.elapsed.inMilliseconds
        ]);
      }
    }
  }

  void _laserDrawing() {
    _laserTimer?.cancel();
  }

  void _stopLaserDrawing() {
    setState(() {
      _laserPoints[_currentPage].clear();
    });
  }

  void _studentLaserDrawing() {
    _studentLaserTimer?.cancel();
  }

  void _studentStopLaserDrawing() {
    setState(() {
      _studentLaserPoints[_currentPage].clear();
    });
  }

  // ---------- FUNCTION: page control
  void _addPage() {
    setState(() {
      _penPoints.add([null]);
      _laserPoints.add([null]);
      _highlighterPoints.add([null]);
      _eraserPoints.add(const Offset(-100, -100));
      _replayPoints.add([null]);
      _studentPenPoints.add([null]);
      _studentLaserPoints.add([null]);
      _studentHighlighterPoints.add([null]);
      _studentEraserPoints.add(const Offset(-100, -100));
    });
  }

  void _onPageViewChange(int page) {
    setState(() {
      for (var point in _laserPoints) {
        point.clear();
      }
      _currentPage = page;
    });
    if (currentScrollZoom.isNotEmpty) {
      addScrollZoom(currentScrollZoom, currentScrollZoom[0].timestamp);
      currentScrollZoom.clear();
    }
    _actions.add({
      "time": solveStopwatch.elapsed.inMilliseconds,
      "type": "change-page",
      "data": page,
    });
  }

  String _formatElapsedTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return ' $hours : $minutes : $seconds ';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPopScope,
      child: isLiveCourseReady
          ? Scaffold(
              backgroundColor: CustomColors.grayCFCFCF,
              body: !Responsive.isMobileLandscape(context)
                  ? _buildTablet()
                  : _buildMobile(),
            )
          : const LoadingScreen(),
    );
  }

  Widget _buildTablet() {
    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              headerLayer1(),
              const DividerLine(),
              headerLayer2(),
              const DividerLine(),

              //Body Layout
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tools(),
                    solvePad(),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 145,
            right: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!micEnable)
                  statusScreenRed("You’re Muted", ImageAssets.micMuteRed),
                S.h(16),
                // if (_requestScreenShare && (focusedStudentId == ''))
                //   statusScreenRed(
                //       "Wait for student to share", ImageAssets.micMuteRed),
                if (focusedStudentId != '' && _isViewingFocusStudent)
                  statusStudentShareScreen(
                      "หน้าจอ: $focusedStudentName", ImageAssets.avatarWomen),
              ],
            ),
          ), // Share screen pill
          showListStudents(),
          if (isUploading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Uploading Data',
                          style: CustomStyles.bold14bluePrimary),
                      S.w(16),
                      const CircularProgressIndicator(
                        color: Color(0xff0D47A1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (isRecordingLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Preparing Audio Record',
                          style: CustomStyles.bold14bluePrimary),
                      S.w(16),
                      const CircularProgressIndicator(
                        color: Color(0xff0D47A1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (openColors)
            Positioned(
              left: 150,
              bottom: 50,
              child: Container(
                width: 55,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: CustomColors.grayCFCFCF,
                    style: BorderStyle.solid,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(64),
                  color: CustomColors.whitePrimary,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _listColors.length,
                        itemBuilder: (context, index) {
                          return Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedIndexColors = index;
                                    openColors = !openColors;
                                  });
                                  int time =
                                      solveStopwatch.elapsed.inMilliseconds;
                                  for (int i = 0; i <= 4; i++) {
                                    sendMessage(
                                      'StrokeColor.$index',
                                      time,
                                    );
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Image.asset(
                                    _listColors[index]['color'],
                                  ),
                                ),
                              ),
                              S.h(4)
                            ],
                          );
                        })
                  ],
                ),
              ),
            ),
          if (openLines)
            Positioned(
              left: 150,
              bottom: 50,
              child: Container(
                width: 55,
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: CustomColors.grayCFCFCF,
                    style: BorderStyle.solid,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(64),
                  color: CustomColors.whitePrimary,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _listLines.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                setState(() {
                                  _selectedIndexLines = index;
                                  openLines = !openLines;
                                });
                                int time =
                                    solveStopwatch.elapsed.inMilliseconds;
                                for (int i = 0; i <= 4; i++) {
                                  sendMessage(
                                    'StrokeWidth.$index',
                                    time,
                                  );
                                }
                              });
                            },
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Image.asset(
                                    _selectedIndexLines == index
                                        ? _listLines[index]['image_active']
                                        : _listLines[index]['image_dis'],
                                  ),
                                ),
                                S.h(8)
                              ],
                            ),
                          );
                        })
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobile() {
    return SafeArea(
      right: false,
      left: false,
      bottom: false,
      child: Stack(
        children: [
          Column(
            children: [
              headerLayer2Mobile(),
              const DividerLine(),
              solvePad(),
            ],
          ),

          if (isUploading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Uploading Data',
                          style: CustomStyles.bold14bluePrimary),
                      S.w(16),
                      const CircularProgressIndicator(
                        color: Color(0xff0D47A1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (isRecordingLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Preparing Audio Record',
                          style: CustomStyles.bold14bluePrimary),
                      S.w(16),
                      const CircularProgressIndicator(
                        color: Color(0xff0D47A1),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          ///tools widget
          if (!selectedTools) toolsMobile(),
          if (selectedTools) toolsActiveMobile(),

          /// Status ShareScreen
          statusShareScreenMobile(),

          /// Control display
          toolsControlMobile(),

          /// For list Student
          showListStudentsMobile(),
        ],
      ),
    );
  }

  Widget solvePad() {
    return Expanded(
      child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        double solvepadWidth = constraints.maxWidth;
        double solvepadHeight = constraints.maxHeight;
        currentScrollX = (-1 * solvepadWidth);
        if (mySolvepadSize.width != solvepadWidth) {
          initSolvepadScaling(solvepadWidth, solvepadHeight);
        }
        return Stack(children: [
          PageView.builder(
            onPageChanged: _onPageViewChange,
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            scrollDirection: Axis.vertical,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              if (index >= _transformationController.length) {
                _transformationController.add(TransformationController());
                _transformationController[index].value = Matrix4.identity()
                  ..scale(2.0)
                  ..translate(-1 * solvepadWidth / 4, 0);
              }
              return InteractiveViewer(
                transformationController: _transformationController[index],
                alignment: const Alignment(-1, -1),
                minScale: 1.0,
                maxScale: 4.0,
                onInteractionUpdate: (ScaleUpdateDetails details) {
                  var translation =
                      _transformationController[index].value.getTranslation();
                  double scale = _transformationController[index]
                      .value
                      .getMaxScaleOnAxis();
                  double originalTranslationY = translation.y;
                  double originalTranslationX = translation.x;

                  if (_mode == DrawingMode.drag) {
                    sendMessage(
                      'ScrollZoom:${originalTranslationX.toStringAsFixed(2)}:${originalTranslationY.toStringAsFixed(2)}:${scale.toStringAsFixed(2)}',
                      solveStopwatch.elapsed.inMilliseconds,
                    );
                    currentScrollZoom.add(ScrollZoomStamp(
                        originalTranslationX,
                        originalTranslationY,
                        scale,
                        solveStopwatch.elapsed.inMilliseconds));
                  } else {
                    currentScale = scale;
                    currentScrollX = originalTranslationX;
                    currentScrollY = originalTranslationY;
                  }
                },
                child: Stack(
                  children: [
                    Center(
                      child: Image.network(
                        _pages[index],
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: _mode == DrawingMode.drag,
                        child: GestureDetector(
                          onPanDown: (_) {},
                          child: Listener(
                            onPointerDown: (details) {
                              if (activePointerId != null) return;
                              activePointerId = details.pointer;
                              if (details.kind == PointerDeviceKind.stylus) {
                                _isStylusActive = true;
                              }
                              if (_isStylusActive &&
                                  details.kind == PointerDeviceKind.touch) {
                                return;
                              }
                              sendMessage(
                                details.localPosition.toString(),
                                solveStopwatch.elapsed.inMilliseconds,
                              );
                              switch (_mode) {
                                case DrawingMode.pen:
                                  currentStroke.add(StrokeStamp(
                                      details.localPosition,
                                      solveStopwatch.elapsed.inMilliseconds));
                                  _penPoints[_currentPage].add(
                                    SolvepadStroke(
                                        details.localPosition,
                                        _strokeColors[_selectedIndexColors],
                                        _strokeWidths[_selectedIndexLines]),
                                  );
                                  break;
                                case DrawingMode.laser:
                                  _laserPoints[_currentPage].add(
                                    SolvepadStroke(
                                        details.localPosition,
                                        _strokeColors[_selectedIndexColors],
                                        _strokeWidths[_selectedIndexLines]),
                                  );
                                  _laserDrawing();
                                  break;
                                case DrawingMode.highlighter:
                                  currentStroke.add(StrokeStamp(
                                      details.localPosition,
                                      solveStopwatch.elapsed.inMilliseconds));
                                  _highlighterPoints[_currentPage].add(
                                    SolvepadStroke(
                                        details.localPosition,
                                        _strokeColors[_selectedIndexColors],
                                        _strokeWidths[_selectedIndexLines]),
                                  );
                                  break;
                                case DrawingMode.eraser:
                                  currentEraserStroke.add([
                                    details.localPosition,
                                    solveStopwatch.elapsed.inMilliseconds
                                  ]);
                                  _eraserPoints[_currentPage] =
                                      details.localPosition;
                                  int penHit = _penPoints[_currentPage]
                                      .indexWhere((point) =>
                                          (point?.offset != null) &&
                                          sqrDistanceBetween(point!.offset,
                                                  details.localPosition) <=
                                              100);
                                  int highlightHit =
                                      _highlighterPoints[_currentPage]
                                          .indexWhere((point) =>
                                              (point?.offset != null) &&
                                              sqrDistanceBetween(point!.offset,
                                                      details.localPosition) <=
                                                  100);
                                  if (penHit != -1) {
                                    doErase(penHit, DrawingMode.pen);
                                  }
                                  if (highlightHit != -1) {
                                    doErase(
                                        highlightHit, DrawingMode.highlighter);
                                  }
                                  break;
                                default:
                                  break;
                              }
                            },
                            onPointerMove: (details) {
                              if (activePointerId != details.pointer) return;
                              activePointerId = details.pointer;
                              if (details.kind == PointerDeviceKind.stylus) {
                                _isStylusActive = true;
                              }
                              if (_isStylusActive &&
                                  details.kind == PointerDeviceKind.touch) {
                                return;
                              }
                              sendMessage(
                                details.localPosition.toString(),
                                solveStopwatch.elapsed.inMilliseconds,
                              );
                              switch (_mode) {
                                case DrawingMode.pen:
                                  currentStroke.add(StrokeStamp(
                                      details.localPosition,
                                      solveStopwatch.elapsed.inMilliseconds));
                                  setState(() {
                                    _penPoints[_currentPage].add(SolvepadStroke(
                                        details.localPosition,
                                        _strokeColors[_selectedIndexColors],
                                        _strokeWidths[_selectedIndexLines]));
                                  });
                                  break;
                                case DrawingMode.laser:
                                  setState(() {
                                    _laserPoints[_currentPage].add(
                                      SolvepadStroke(
                                          details.localPosition,
                                          _strokeColors[_selectedIndexColors],
                                          _strokeWidths[_selectedIndexLines]),
                                    );
                                  });
                                  _laserDrawing();
                                  break;
                                case DrawingMode.highlighter:
                                  currentStroke.add(StrokeStamp(
                                      details.localPosition,
                                      solveStopwatch.elapsed.inMilliseconds));
                                  setState(() {
                                    _highlighterPoints[_currentPage].add(
                                      SolvepadStroke(
                                          details.localPosition,
                                          _strokeColors[_selectedIndexColors],
                                          _strokeWidths[_selectedIndexLines]),
                                    );
                                  });
                                  break;
                                case DrawingMode.eraser:
                                  currentEraserStroke.add([
                                    details.localPosition,
                                    solveStopwatch.elapsed.inMilliseconds
                                  ]);
                                  setState(() {
                                    _eraserPoints[_currentPage] =
                                        details.localPosition;
                                  });
                                  int penHit = _penPoints[_currentPage]
                                      .indexWhere((point) =>
                                          (point?.offset != null) &&
                                          sqrDistanceBetween(point!.offset,
                                                  details.localPosition) <=
                                              100);
                                  int highlightHit =
                                      _highlighterPoints[_currentPage]
                                          .indexWhere((point) =>
                                              (point?.offset != null) &&
                                              sqrDistanceBetween(point!.offset,
                                                      details.localPosition) <=
                                                  500);
                                  if (penHit != -1) {
                                    doErase(penHit, DrawingMode.pen);
                                  }
                                  if (highlightHit != -1) {
                                    doErase(
                                        highlightHit, DrawingMode.highlighter);
                                  }
                                  break;
                                default:
                                  break;
                              }
                            },
                            onPointerUp: (details) {
                              if (activePointerId != details.pointer) return;
                              activePointerId = null;
                              if (_isStylusActive &&
                                  details.kind == PointerDeviceKind.touch) {
                                return;
                              }
                              int time = solveStopwatch.elapsed.inMilliseconds;
                              for (int i = 0; i <= 2; i++) {
                                sendMessage(
                                  'null',
                                  time,
                                );
                              }
                              switch (_mode) {
                                case DrawingMode.pen:
                                  addDrawing(currentStroke,
                                      currentStroke[0].timestamp);
                                  currentStroke.clear();
                                  _penPoints[_currentPage].add(null);
                                  break;
                                case DrawingMode.laser:
                                  _laserPoints[_currentPage].add(null);
                                  _laserTimer = Timer(
                                      const Duration(milliseconds: 1500),
                                      _stopLaserDrawing);
                                  break;
                                case DrawingMode.highlighter:
                                  addDrawing(currentStroke,
                                      currentStroke[0].timestamp);
                                  currentStroke.clear();
                                  _highlighterPoints[_currentPage].add(null);
                                  break;
                                case DrawingMode.eraser:
                                  addErasing(currentEraserStroke);
                                  currentEraserStroke.clear();
                                  setState(() {
                                    _eraserPoints[_currentPage] =
                                        const Offset(-100, -100);
                                  });
                                  break;
                                default:
                                  break;
                              }
                            },
                            onPointerCancel: (details) {
                              if (activePointerId != details.pointer) return;
                              activePointerId = null;
                              if (_isStylusActive &&
                                  details.kind == PointerDeviceKind.touch) {
                                return;
                              }
                              int time = solveStopwatch.elapsed.inMilliseconds;
                              for (int i = 0; i <= 2; i++) {
                                sendMessage(
                                  'null',
                                  time,
                                );
                              }
                              switch (_mode) {
                                case DrawingMode.pen:
                                  addDrawing(currentStroke,
                                      currentStroke[0].timestamp);
                                  currentStroke.clear();
                                  _penPoints[_currentPage].add(null);
                                  break;
                                case DrawingMode.laser:
                                  _laserPoints[_currentPage].add(null);
                                  _laserTimer = Timer(
                                      const Duration(milliseconds: 1500),
                                      _stopLaserDrawing);
                                  break;
                                case DrawingMode.highlighter:
                                  addDrawing(currentStroke,
                                      currentStroke[0].timestamp);
                                  currentStroke.clear();
                                  _highlighterPoints[_currentPage].add(null);
                                  break;
                                case DrawingMode.eraser:
                                  addErasing(currentEraserStroke);
                                  currentEraserStroke.clear();
                                  setState(() {
                                    _eraserPoints[_currentPage] =
                                        const Offset(-100, -100);
                                  });
                                  break;
                                default:
                                  break;
                              }
                            },
                            child: CustomPaint(
                              painter: SolvepadDrawerLive(
                                _penPoints[index],
                                _replayPoints[index],
                                _eraserPoints[index],
                                _laserPoints[index],
                                _highlighterPoints[index],
                                _studentPenPoints[index],
                                _studentLaserPoints[index],
                                _studentHighlighterPoints[index],
                                _studentEraserPoints[index],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (_requestScreenShare)
            IgnorePointer(
              ignoring: true,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.blue,
                    width: 3.0, // choose the width of the border
                  ),
                ),
              ),
            ),
        ]);
      }),
    );
  }

  Widget headerLayer1() {
    return Container(
      height: 60,
      color: CustomColors.whitePrimary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          S.w(Responsive.isTablet(context) ? 5 : 24),
          if (Responsive.isTablet(context))
            Expanded(
              flex: 3,
              child: Text(
                widget.isMock ? "คอร์สปรับพื้นฐานคณิตศาสตร์" : courseName,
                style: CustomStyles.bold16Black363636Overflow,
                maxLines: 1,
              ),
            ),
          if (Responsive.isDesktop(context))
            Expanded(
              flex: 4,
              child: InkWell(
                onTap: () {
                  log(_penPoints[_currentPage].toString());
                },
                child: Text(
                  widget.isMock ? "คอร์สปรับพื้นฐานคณิตศาสตร์" : courseName,
                  style: CustomStyles.bold16Black363636Overflow,
                  maxLines: 1,
                ),
              ),
            ),
          if (Responsive.isMobile(context))
            Expanded(
              flex: 2,
              child: Text(
                courseName,
                style: CustomStyles.bold16Black363636Overflow,
                maxLines: 1,
              ),
            ),
          Expanded(
            flex: Responsive.isDesktop(context) ? 3 : 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Container(
                //   height: 32,
                //   width: 145,
                //   decoration: const BoxDecoration(
                //     color: CustomColors.pinkFFCDD2,
                //     borderRadius: BorderRadius.all(
                //       Radius.circular(defaultPadding),
                //     ),
                //   ),
                //   child: InkWell(
                //     onTap: () async {
                //       log('test tapped');
                //       await meeting.stopRecording();
                //       await fetchRecording(widget.meetingId);
                //     },
                //     child: Row(
                //       mainAxisAlignment: MainAxisAlignment.center,
                //       children: [
                //         Image.asset(
                //           ImageAssets.lowSignal,
                //           height: 22,
                //           width: 18,
                //         ),
                //         S.w(10),
                //         Flexible(
                //           child: Text(
                //             "สัญญาณอ่อน",
                //             style: CustomStyles.bold14redB71C1C,
                //             maxLines: 1,
                //             overflow: TextOverflow.ellipsis,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
                S.w(16.0),
                Container(
                  height: 11,
                  width: 11,
                  decoration: BoxDecoration(
                      color: CustomColors.redF44336,
                      borderRadius: BorderRadius.circular(100)
                      //more than 50% of width makes circle
                      ),
                ),
                S.w(4.0),
                RichText(
                  text: TextSpan(
                    text: 'Live Time: ',
                    style: CustomStyles.med14redFF4201,
                    children: <TextSpan>[
                      TextSpan(
                        text: _formattedElapsedTime,
                        style: CustomStyles.med14Gray878787,
                      ),
                    ],
                  ),
                ),
                S.w(16.0),
                InkWell(
                  onTap: () async {
                    if (isRecordingOn) {
                      showAlertRecordingDialog(context);
                    } else {
                      setState(() {
                        isUploading = true;
                      });
                      showCloseDialog(context, () async {
                        sendMessage(
                          'EndMeeting',
                          solveStopwatch.elapsed.inMilliseconds,
                        );
                        if (!widget.isMock) {
                          meeting.end();
                          closeChanel();
                          FirebaseFirestore.instance
                              .collection('course_live')
                              .doc(widget.courseId)
                              .update({'currentMeetingCode': ''});
                          await updateActualTime();
                          await endSolvepadDataCollection();
                        }
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Nav(),
                            ),
                            (route) => false);
                      }, onCancel: () {
                        setState(() {
                          isUploading = false;
                        });
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: defaultPadding * 1,
                      vertical: defaultPadding / 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: CustomColors.redF44336,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "ปิดห้องเรียน",
                          style: CustomStyles.bold14White,
                        ),
                      ],
                    ),
                  ),
                ),
                S.w(Responsive.isTablet(context) ? 5 : 24),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget headerLayer2() {
    return Container(
      height: 70,
      decoration: BoxDecoration(color: CustomColors.whitePrimary, boxShadow: [
        BoxShadow(
            color: CustomColors.gray878787.withOpacity(.1),
            offset: const Offset(0.0, 6),
            blurRadius: 10,
            spreadRadius: 1)
      ]),
      child: Row(
        children: [
          S.w(Responsive.isTablet(context) ? 5 : 24),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _requestScreenShare
                      ? ColorFiltered(
                          colorFilter: ColorFilter.mode(
                              Colors.grey.withOpacity(0.3), BlendMode.modulate),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: CustomColors.grayCFCFCF,
                                style: BorderStyle.solid,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: CustomColors.whitePrimary,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 1, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                InkWell(
                                  onTap: () {
                                    log('TEST');
                                    log(_highlighterPoints[_currentPage]
                                        .toString());
                                  },
                                  child: Image.asset(
                                    ImageAssets.allPages,
                                    height: 30,
                                    width: 32,
                                  ),
                                ),
                                S.w(defaultPadding),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: CustomColors.grayCFCFCF,
                                ),
                                S.w(defaultPadding),
                                Material(
                                  child: InkWell(
                                    onTap: () {
                                      if (_isViewingFocusStudent) return;
                                      if (_pageController.hasClients &&
                                          _pageController.page!.toInt() != 0) {
                                        int page = _currentPage - 1;
                                        int time = solveStopwatch
                                            .elapsed.inMilliseconds;
                                        for (int i = 0; i <= 4; i++) {
                                          sendMessage(
                                            'ChangePage:$page',
                                            time,
                                          );
                                        }
                                        _pageController.animateToPage(
                                          _pageController.page!.toInt() - 1,
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Image.asset(
                                        ImageAssets.backDis,
                                        height: 16,
                                        width: 17,
                                        color: _isPrevBtnActive
                                            ? CustomColors.activePagingBtn
                                            : CustomColors.inactivePagingBtn,
                                      ),
                                    ),
                                  ),
                                ),
                                S.w(defaultPadding),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: CustomColors.grayCFCFCF,
                                      style: BorderStyle.solid,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    color: CustomColors.whitePrimary,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text("Page ${_currentPage + 1}",
                                          style:
                                              CustomStyles.bold14greenPrimary),
                                    ],
                                  ),
                                ),
                                S.w(8.0),
                                Text("/ ${_pages.length}",
                                    style: CustomStyles.med14Gray878787),
                                S.w(8),
                                Material(
                                  child: InkWell(
                                    onTap: () {
                                      if (_isViewingFocusStudent) return;
                                      if (_pages.length > 1) {
                                        if (_pageController.hasClients &&
                                            _pageController.page!.toInt() !=
                                                _pages.length - 1) {
                                          int page = _currentPage + 1;
                                          int time = solveStopwatch
                                              .elapsed.inMilliseconds;
                                          for (int i = 0; i <= 4; i++) {
                                            sendMessage(
                                              'ChangePage:$page',
                                              time,
                                            );
                                          }
                                          _pageController.animateToPage(
                                            _pageController.page!.toInt() + 1,
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Image.asset(
                                        ImageAssets.forward,
                                        height: 16,
                                        width: 17,
                                        color: _isNextBtnActive
                                            ? CustomColors.activePagingBtn
                                            : CustomColors.inactivePagingBtn,
                                      ),
                                    ),
                                  ),
                                ),
                                S.w(6.0),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: CustomColors.grayCFCFCF,
                              style: BorderStyle.solid,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: CustomColors.whitePrimary,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 1, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              InkWell(
                                onTap: () {
                                  log('TEST');
                                  log(_highlighterPoints[_currentPage]
                                      .toString());
                                },
                                child: Image.asset(
                                  ImageAssets.allPages,
                                  height: 30,
                                  width: 32,
                                ),
                              ),
                              S.w(defaultPadding),
                              Container(
                                width: 1,
                                height: 24,
                                color: CustomColors.grayCFCFCF,
                              ),
                              S.w(defaultPadding),
                              Material(
                                child: InkWell(
                                  onTap: () {
                                    if (_isViewingFocusStudent) return;
                                    if (_pageController.hasClients &&
                                        _pageController.page!.toInt() != 0) {
                                      int page = _currentPage - 1;
                                      int time =
                                          solveStopwatch.elapsed.inMilliseconds;
                                      for (int i = 0; i <= 4; i++) {
                                        sendMessage(
                                          'ChangePage:$page',
                                          time,
                                        );
                                      }
                                      _pageController.animateToPage(
                                        _pageController.page!.toInt() - 1,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.asset(
                                      ImageAssets.backDis,
                                      height: 16,
                                      width: 17,
                                      color: _isPrevBtnActive
                                          ? CustomColors.activePagingBtn
                                          : CustomColors.inactivePagingBtn,
                                    ),
                                  ),
                                ),
                              ),
                              S.w(defaultPadding),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: CustomColors.grayCFCFCF,
                                    style: BorderStyle.solid,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  color: CustomColors.whitePrimary,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text("Page ${_currentPage + 1}",
                                        style: CustomStyles.bold14greenPrimary),
                                  ],
                                ),
                              ),
                              S.w(8.0),
                              Text("/ ${_pages.length}",
                                  style: CustomStyles.med14Gray878787),
                              S.w(8),
                              Material(
                                child: InkWell(
                                  onTap: () {
                                    if (_isViewingFocusStudent) return;
                                    if (_pages.length > 1) {
                                      if (_pageController.hasClients &&
                                          _pageController.page!.toInt() !=
                                              _pages.length - 1) {
                                        int page = _currentPage + 1;
                                        int time = solveStopwatch
                                            .elapsed.inMilliseconds;
                                        for (int i = 0; i <= 4; i++) {
                                          sendMessage(
                                            'ChangePage:$page',
                                            time,
                                          );
                                        }
                                        _pageController.animateToPage(
                                          _pageController.page!.toInt() + 1,
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.asset(
                                      ImageAssets.forward,
                                      height: 16,
                                      width: 17,
                                      color: _isNextBtnActive
                                          ? CustomColors.activePagingBtn
                                          : CustomColors.inactivePagingBtn,
                                    ),
                                  ),
                                ),
                              ),
                              S.w(6.0),
                            ],
                          ),
                        ),
                ),
                S.w(8),
                statusTouchModeIcon(),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Material(
                  child: InkWell(
                    onTap: () async {
                      if (!isRecordingLoading) {
                        if (!isRecordingOn) {
                          await meeting
                              .startRecording(config: {"mode": "audio"});
                        } else {
                          await meeting.stopRecording();
                        }
                      }
                    },
                    // child: Image.asset(
                    //   isRecordingLoading
                    //       ? ImageAssets.loading
                    //       : isRecordingOn
                    //           ? ImageAssets.recordDis
                    //           : ImageAssets.recordEnable,
                    //   height: 44,
                    //   width: 44,
                    // ),
                    child: isRecordingLoading
                        ? Image.asset(
                            ImageAssets.loading,
                            height: 44,
                            width: 44,
                          )
                        : Container(
                            // margin: const EdgeInsets.symmetric(vertical: 14.0),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: isRecordingOn
                                    ? CustomColors.gray363636
                                    : CustomColors.redFF4201,
                                shape: BoxShape.circle),
                            child: Icon(
                              isRecordingOn
                                  ? Icons.stop
                                  : Icons.radio_button_checked_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                S.w(defaultPadding),
                Material(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        micEnable = !micEnable;
                      });
                      if (micEnable && !widget.isMock) {
                        meeting.unmuteMic();
                      } else {
                        meeting.muteMic();
                      }
                    },
                    child: Image.asset(
                      micEnable ? ImageAssets.micEnable : ImageAssets.micDis,
                      height: 44,
                      width: 44,
                    ),
                  ),
                ),
                // S.w(defaultPadding),
                // InkWell(
                //   onTap: () {
                //     setState(() {
                //       displayEnable = !displayEnable;
                //     });
                //     meeting.startRecording(config: {"mode": "audio"});
                //   },
                //   child: Image.asset(
                //     displayEnable
                //         ? ImageAssets.displayEnable
                //         : ImageAssets.displayDis,
                //     height: 44,
                //     width: 44,
                //   ),
                // ),
                // S.w(defaultPadding),

                ///todo Icon share for disable
                // Image.asset(
                //   ImageAssets.shareQa,
                //   height: 44,
                //   width: 44,
                // ),
                // Stack(
                //   children: [
                //     InkWell(
                //       onTap: () {
                //         quizSelectModal();
                //         // showDialog(
                //         //     context: context,
                //         //     builder: (context) => const QuizSelect());
                //
                //         // showDialog(
                //         //     context: context,
                //         //     builder: (context) => _buildQuiz());
                //       },
                //       child: Image.asset(
                //         ImageAssets.icShareAction,
                //         height: 44,
                //         width: 44,
                //       ),
                //     ),
                //     Padding(
                //       padding: const EdgeInsets.only(left: 32, bottom: 1),
                //       child: Container(
                //         decoration: const BoxDecoration(
                //             color: CustomColors.black363636,
                //             shape: BoxShape.circle),
                //         width: 25,
                //         height: 25,
                //         child: Center(
                //           child: Text(
                //             "12",
                //             style: CustomStyles.bold11White,
                //           ),
                //         ),
                //       ),
                //     ),
                //   ],
                // ),

                ///End icon share
                S.w(defaultPadding),
                const DividerVer(),
                S.w(defaultPadding),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.blue,
                      style: BorderStyle.solid,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(100),
                    color: CustomColors.whitePrimary,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Transform.scale(
                        scale: 0.7,
                        child: CupertinoSwitch(
                          trackColor: Colors.blue.withOpacity(0.1),
                          activeColor: Colors.blue,
                          value: _requestScreenShare,
                          onChanged: (bool value) {
                            setState(() {
                              _requestScreenShare = value;
                              showStudent = value;
                              if (value == false) {
                                _isViewingFocusStudent = false;
                                cleanStudentSolvepad();
                              }
                            });
                            sendMessage(
                              'RequestScreenShare:$value',
                              solveStopwatch.elapsed.inMilliseconds,
                            );
                          },
                        ),
                      ),
                      Text("ให้นักเรียนแชร์จอ",
                          textAlign: TextAlign.center,
                          style: CustomStyles.bold14bluePrimary),
                      S.w(4)
                    ],
                  ),
                ),
                S.w(32),
              ],
            ),
          ),

          /// Statistics
          // Expanded(
          //     flex: 2,
          //     child: Align(
          //       alignment: Alignment.centerRight,
          //       child: InkWell(
          //         onTap: () {
          //           log('Go to Statistics');
          //           showLeader(context);
          //         },
          //         child: Container(
          //           decoration: BoxDecoration(
          //             border: Border.all(
          //               color: CustomColors.grayCFCFCF,
          //               style: BorderStyle.solid,
          //               width: 1.0,
          //             ),
          //             borderRadius: BorderRadius.circular(8),
          //             color: CustomColors.whitePrimary,
          //           ),
          //           padding:
          //               const EdgeInsets.symmetric(horizontal: 1, vertical: 6),
          //           child: Padding(
          //             padding: const EdgeInsets.all(6.0),
          //             child: Row(
          //               mainAxisSize: MainAxisSize.min,
          //               mainAxisAlignment: MainAxisAlignment.center,
          //               children: <Widget>[
          //                 Image.asset(
          //                   ImageAssets.leaderboard,
          //                   height: 23,
          //                   width: 25,
          //                 ),
          //                 S.w(8),
          //                 Container(
          //                   width: 1,
          //                   height: 24,
          //                   color: CustomColors.grayCFCFCF,
          //                 ),
          //                 S.w(8),
          //                 Image.asset(
          //                   ImageAssets.checkTrue,
          //                   height: 18,
          //                   width: 18,
          //                 ),
          //                 if (!Responsive.isTablet(context)) S.w(8.0),
          //                 Text("100%", style: CustomStyles.bold14Gray878787),
          //                 if (!Responsive.isTablet(context)) S.w(8.0),
          //                 Image.asset(
          //                   ImageAssets.x,
          //                   height: 18,
          //                   width: 18,
          //                 ),
          //                 if (!Responsive.isTablet(context)) S.w(8.0),
          //                 Text("100%", style: CustomStyles.bold14Gray878787),
          //                 if (!Responsive.isTablet(context)) S.w(8.0),
          //                 Image.asset(
          //                   ImageAssets.icQa,
          //                   height: 18,
          //                   width: 18,
          //                 ),
          //                 if (!Responsive.isTablet(context)) S.w(8.0),
          //                 Text("100%", style: CustomStyles.bold14Gray878787),
          //                 if (!Responsive.isTablet(context)) S.w(8.0),
          //                 Image.asset(
          //                   ImageAssets.arrowNextCircle,
          //                   width: 21,
          //                 ),
          //               ],
          //             ),
          //           ),
          //         ),
          //       ),
          //     )),
          // S.w(Responsive.isTablet(context) ? 5 : 24),
        ],
      ),
    );
  }

  Future<void> headerLayer1Mobile() {
    return showDialog(
      useSafeArea: false,
      context: context,
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      color: CustomColors.whitePrimary,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          S.w(defaultPadding),
                          if (Responsive.isMobile(context))
                            Expanded(
                                flex: 4,
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                                      child: const Icon(
                                        Icons.close,
                                        color: CustomColors.gray878787,
                                        size: 18,
                                      ),
                                    ),
                                    S.w(8),
                                    Flexible(
                                      child: Text(
                                        courseName,
                                        style: CustomStyles
                                            .bold16Black363636Overflow,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                )),
                          Expanded(
                              flex: 2,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  S.w(16.0),
                                  Container(
                                    height: 11,
                                    width: 11,
                                    decoration: BoxDecoration(
                                        color: CustomColors.redF44336,
                                        borderRadius: BorderRadius.circular(100)
                                        //more than 50% of width makes circle
                                        ),
                                  ),
                                  S.w(4.0),
                                  RichText(
                                    text: TextSpan(
                                      text: 'Live Time: ',
                                      style: CustomStyles.med14redFF4201,
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: _formattedElapsedTime,
                                          style: CustomStyles.med14Gray878787,
                                        ),
                                      ],
                                    ),
                                  ),
                                  S.w(defaultPadding),
                                ],
                              ))
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget headerLayer2Mobile() {
    return Container(
      height: 46,
      decoration: BoxDecoration(color: CustomColors.whitePrimary, boxShadow: [
        BoxShadow(
            color: CustomColors.gray878787.withOpacity(.1),
            offset: const Offset(0.0, 6),
            blurRadius: 10,
            spreadRadius: 1)
      ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 38,
            margin: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: CustomColors.grayCFCFCF,
                style: BorderStyle.solid,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(8),
              color: CustomColors.whitePrimary,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                InkWell(
                  onTap: () => headerLayer1Mobile(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      ImageAssets.iconInfoPage,
                      height: 24,
                      width: 24,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: CustomColors.grayCFCFCF,
                ),
                S.w(8),
                InkWell(
                  onTap: () {
                    log('TEST');
                    log(_highlighterPoints[_currentPage].toString());
                    log(_penPoints[_currentPage].toString());
                  },
                  child: Image.asset(
                    ImageAssets.allPages,
                    height: 24,
                    width: 24,
                  ),
                ),
                S.w(8),
                Container(
                  width: 1,
                  height: 32,
                  color: CustomColors.grayCFCFCF,
                ),
                Material(
                  child: InkWell(
                    onTap: () {
                      if (_pageController.hasClients &&
                          _pageController.page!.toInt() != 0) {
                        int page = _currentPage - 1;
                        int time = solveStopwatch.elapsed.inMilliseconds;
                        for (int i = 0; i <= 4; i++) {
                          sendMessage(
                            'ChangePage:$page',
                            time,
                          );
                        }
                        _pageController.animateToPage(
                          _pageController.page!.toInt() - 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        ImageAssets.backDis,
                        height: 16,
                        width: 17,
                        color: _isPrevBtnActive
                            ? CustomColors.activePagingBtn
                            : CustomColors.inactivePagingBtn,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: CustomColors.grayCFCFCF,
                      style: BorderStyle.solid,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    color: CustomColors.whitePrimary,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text("Page ${_currentPage + 1}",
                          style: CustomStyles.bold12greenPrimary),
                    ],
                  ),
                ),
                S.w(8.0),
                Text("/ ${_pages.length}", style: CustomStyles.med12gray878787),
                Material(
                  child: InkWell(
                    // splashColor: Colors.lightGreen,
                    onTap: () {
                      if (_pages.length > 1) {
                        if (_pageController.hasClients &&
                            _pageController.page!.toInt() !=
                                _pages.length - 1) {
                          int page = _currentPage + 1;
                          int time = solveStopwatch.elapsed.inMilliseconds;
                          for (int i = 0; i <= 4; i++) {
                            sendMessage(
                              'ChangePage:$page',
                              time,
                            );
                          }
                          _pageController.animateToPage(
                            _pageController.page!.toInt() + 1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        ImageAssets.forward,
                        height: 16,
                        width: 17,
                        color: _isNextBtnActive
                            ? CustomColors.activePagingBtn
                            : CustomColors.inactivePagingBtn,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Transform.scale(
                scale: 0.6,
                child: CupertinoSwitch(
                  trackColor: Colors.blue.withOpacity(0.1),
                  activeColor: Colors.blue,
                  value: _requestScreenShare,
                  onChanged: (bool value) {
                    sendMessage(
                      'RequestScreenShare:$value',
                      solveStopwatch.elapsed.inMilliseconds,
                    );
                    setState(() {
                      _requestScreenShare = value;
                      showStudent = value;
                    });
                  },
                ),
              ),
              Text("ให้นักเรียนแชร์จอ",
                  textAlign: TextAlign.center,
                  style: CustomStyles.bold14bluePrimary),
              S.w(defaultPadding),
              // Container(
              //   height: 32,
              //   decoration: BoxDecoration(
              //     border: Border.all(
              //       color: CustomColors.grayCFCFCF,
              //       style: BorderStyle.solid,
              //       width: 1.0,
              //     ),
              //     borderRadius: BorderRadius.circular(8),
              //     color: CustomColors.whitePrimary,
              //   ),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: <Widget>[
              //       S.w(8),
              //       InkWell(
              //         onTap: () {
              //           showLeader(context);
              //         },
              //         child: Image.asset(
              //           ImageAssets.leaderboard,
              //           height: 24,
              //           width: 24,
              //         ),
              //       ),
              //       S.w(8),
              //       Container(
              //         width: 1,
              //         height: double.infinity,
              //         color: CustomColors.grayCFCFCF,
              //       ),
              //       S.w(8),
              //       InkWell(
              //         onTap: () {
              //           setState(() {
              //             showStudent = !showStudent;
              //           });
              //         },
              //         child: Image.asset(
              //           ImageAssets.shareGray,
              //           height: 24,
              //           width: 24,
              //         ),
              //       ),
              //       S.w(8),
              //     ],
              //   ),
              // )
            ],
          ),
          // / Statistics
          // Expanded(
          //     flex: 2,
          //     child: Align(
          //       alignment: Alignment.centerRight,
          //       child: InkWell(
          //         onTap: () {
          //           log('Go to Statistics');
          //           showLeader(context);
          //         },
          //         child: Container(
          //           decoration: BoxDecoration(
          //             border: Border.all(
          //               color: CustomColors.grayCFCFCF,
          //               style: BorderStyle.solid,
          //               width: 1.0,
          //             ),
          //             borderRadius: BorderRadius.circular(8),
          //             color: CustomColors.whitePrimary,
          //           ),
          //           padding:
          //               const EdgeInsets.symmetric(horizontal: 1, vertical: 6),
          //           child: Padding(
          //             padding: const EdgeInsets.all(6.0),
          //             child: Row(
          //               mainAxisSize: MainAxisSize.min,
          //               mainAxisAlignment: MainAxisAlignment.center,
          //               children: <Widget>[
          //                 Image.asset(
          //                   ImageAssets.leaderboard,
          //                   height: 23,
          //                   width: 25,
          //                 ),
          //                 S.w(8),
          //                 Container(
          //                   width: 1,
          //                   height: 24,
          //                   color: CustomColors.grayCFCFCF,
          //                 ),
          //                 S.w(8),
          //                 Image.asset(
          //                   ImageAssets.checkTrue,
          //                   height: 18,
          //                   width: 18,
          //                 ),
          //                 if (!Responsive.isTablet(context)) S.w(8.0),
          //                 Text("100%", style: CustomStyles.bold14Gray878787),
          //                 if (!Responsive.isTablet(context)) S.w(8.0),
          //                 Image.asset(
          //                   ImageAssets.x,
          //                   height: 18,
          //                   width: 18,
          //                 ),
          //                 if (!Responsive.isTablet(context)) S.w(8.0),
          //                 Text("100%", style: CustomStyles.bold14Gray878787),
          //                 if (!Responsive.isTablet(context)) S.w(8.0),
          //                 Image.asset(
          //                   ImageAssets.icQa,
          //                   height: 18,
          //                   width: 18,
          //                 ),
          //                 if (!Responsive.isTablet(context)) S.w(8.0),
          //                 Text("100%", style: CustomStyles.bold14Gray878787),
          //                 if (!Responsive.isTablet(context)) S.w(8.0),
          //                 Image.asset(
          //                   ImageAssets.arrowNextCircle,
          //                   width: 21,
          //                 ),
          //               ],
          //             ),
          //           ),
          //         ),
          //       ),
          //     )),
        ],
      ),
    );
  }

  /// Tools

  Widget toolsActiveMobile() {
    return Positioned(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: CustomColors.greenPrimary,
                borderRadius: BorderRadius.only(topRight: Radius.circular(90)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedTools = !selectedTools;
                  });
                },
                child: Image.asset(
                  _listTools[_selectedIndexTools]['image_active'],
                  height: 70,
                  width: 70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget toolsMobile() {
    return Positioned(
      left: 15,
      bottom: 5,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Column(
          children: [
            if (openColors)
              Container(
                  height: 55,
                  width: 260,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: CustomColors.grayCFCFCF,
                      style: BorderStyle.solid,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(64),
                    color: CustomColors.whitePrimary,
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: ListView.builder(
                        padding: const EdgeInsets.only(left: 1, right: 1),
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _listColors.length,
                        itemBuilder: (context, index) {
                          return Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedIndexColors = index;

                                    // Close popup
                                    openColors = !openColors;
                                  });
                                  int time =
                                      solveStopwatch.elapsed.inMilliseconds;
                                  for (int i = 0; i <= 4; i++) {
                                    sendMessage(
                                      'StrokeColor.$index',
                                      time,
                                    );
                                  }
                                },
                                child: Image.asset(_listColors[index]['color'],
                                    width: 48),
                              ),
                              S.w(4)
                            ],
                          );
                        }),
                  )),
            if (openLines)
              Container(
                  height: 55,
                  width: 200,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: CustomColors.grayCFCFCF,
                      style: BorderStyle.solid,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(64),
                    color: CustomColors.whitePrimary,
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: ListView.builder(
                        padding: const EdgeInsets.only(left: 1, right: 1),
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _listLines.length,
                        itemBuilder: (context, index) {
                          return Row(
                            children: [
                              InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedIndexLines = index;

                                      // Close popup
                                      openLines = !openLines;
                                    });
                                    int time =
                                        solveStopwatch.elapsed.inMilliseconds;
                                    for (int i = 0; i <= 4; i++) {
                                      sendMessage(
                                        'StrokeWidth.$index',
                                        time,
                                      );
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        _selectedIndexLines == index
                                            ? _listLines[index]['image_active']
                                            : _listLines[index]['image_dis'],
                                        width: 46,
                                      ),
                                      S.h(8)
                                    ],
                                  )),
                              S.w(4)
                            ],
                          );
                        }),
                  )),
            AnimatedContainer(
              duration: const Duration(seconds: 1),
              curve: Curves.fastOutSlowIn,
              height: 65,
              width: selectedTools ? 0 : 390,
              // TODO: change to 430 when laser ready
              decoration: BoxDecoration(
                border: Border.all(
                  color: CustomColors.grayCFCFCF,
                  style: BorderStyle.solid,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(64),
                color: CustomColors.whitePrimary,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  S.h(8),
                  selectedTools
                      ? Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  _listTools[_selectedIndexTools]
                                      ['image_active'],
                                  width: 10.w,
                                )
                              ],
                            ),
                          ),
                        )
                      : Expanded(
                          // flex: 2,
                          child: Row(
                            // mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ListView.builder(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  physics: const NeverScrollableScrollPhysics(),
                                  scrollDirection: Axis.horizontal,
                                  shrinkWrap: true,
                                  itemCount: _listTools.length,
                                  itemBuilder: (context, index) {
                                    return Row(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedIndexTools = index;
                                            });
                                            if (index == 0) {
                                              _mode = DrawingMode.drag;
                                              int time = solveStopwatch
                                                  .elapsed.inMilliseconds;
                                              for (int i = 0; i <= 4; i++) {
                                                sendMessage(
                                                  'DrawingMode.drag',
                                                  time,
                                                );
                                              }
                                            } else if (index == 1) {
                                              _mode = DrawingMode.pen;
                                              int time = solveStopwatch
                                                  .elapsed.inMilliseconds;
                                              for (int i = 0; i <= 4; i++) {
                                                sendMessage(
                                                  'DrawingMode.pen',
                                                  time,
                                                );
                                              }
                                            } else if (index == 2) {
                                              _mode = DrawingMode.highlighter;
                                              int time = solveStopwatch
                                                  .elapsed.inMilliseconds;
                                              for (int i = 0; i <= 4; i++) {
                                                sendMessage(
                                                  'DrawingMode.highlighter',
                                                  time,
                                                );
                                              }
                                            } else if (index == 3) {
                                              _mode = DrawingMode.eraser;
                                              int time = solveStopwatch
                                                  .elapsed.inMilliseconds;
                                              for (int i = 0; i <= 4; i++) {
                                                sendMessage(
                                                  'DrawingMode.eraser',
                                                  time,
                                                );
                                              }
                                            } else if (index == 4) {
                                              _mode = DrawingMode.laser;
                                              int time = solveStopwatch
                                                  .elapsed.inMilliseconds;
                                              for (int i = 0; i <= 4; i++) {
                                                sendMessage(
                                                  'DrawingMode.laser',
                                                  time,
                                                );
                                              }
                                            }
                                          },
                                          child: Image.asset(
                                            _selectedIndexTools == index
                                                ? _listTools[index]
                                                    ['image_active']
                                                : _listTools[index]
                                                    ['image_dis'],
                                            width: 48,
                                          ),
                                        ),
                                        S.w(8),
                                      ],
                                    );
                                  }),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (openLines || openMore == true) {
                                      openLines = false;
                                      openMore = false;
                                    }
                                    openColors = !openColors;
                                  });
                                },
                                child: Image.asset(
                                  _listColors[_selectedIndexColors]['color'],
                                  width: 28,
                                ),
                              ),
                              S.w(defaultPadding),
                              InkWell(
                                onTap: () {
                                  log("Pick Line");

                                  setState(() {
                                    if (openColors || openMore == true) {
                                      openColors = false;
                                      openMore = false;
                                    }
                                    openLines = !openLines;
                                  });
                                },
                                child: Image.asset(
                                  ImageAssets.pickLine,
                                  width: 38,
                                ),
                              ),
                              S.w(4),
                              // InkWell(
                              //   onTap: () {
                              //     log("Clear");
                              //   },
                              //   child: Image.asset(
                              //     ImageAssets.bin,
                              //     width: 38,
                              //   ),
                              // ),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedTools = !selectedTools;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  child: Image.asset(
                                    ImageAssets.arrowLeftDouble,
                                    width: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget toolsControlMobile() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () {
                showCloseDialog(context, () async {
                  sendMessage(
                    'EndMeeting',
                    solveStopwatch.elapsed.inMilliseconds,
                  );
                  if (!widget.isMock) {
                    meeting.end();
                    closeChanel();
                    FirebaseFirestore.instance
                        .collection('course_live')
                        .doc(widget.courseId)
                        .update({'currentMeetingCode': ''});
                    await updateActualTime();
                    await endSolvepadDataCollection();
                  }
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Nav(),
                      ),
                      (route) => false);
                });
              },
              child: Image.asset(
                ImageAssets.iconOut,
                width: 44,
              ),
            ),
            S.h(8),

            ///For empty data
            // InkWell(
            //   onTap: () {},
            //   child: Image.asset(
            //     ImageAssets.shareQa,
            //     width: 44,
            //   ),
            // ),

            // Stack(
            //   children: [
            //     InkWell(
            //       onTap: () {
            //         quizSelectModal();
            //       },
            //       child: Image.asset(
            //         ImageAssets.icShareAction,
            //         height: 44,
            //         width: 44,
            //       ),
            //     ),
            //     Padding(
            //       padding: const EdgeInsets.only(left: 24),
            //       child: Container(
            //         decoration: const BoxDecoration(
            //             color: CustomColors.black363636,
            //             shape: BoxShape.circle),
            //         width: 25,
            //         height: 25,
            //         child: Center(
            //           child: Text(
            //             "12",
            //             style: CustomStyles.bold11White,
            //           ),
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
            // S.h(8),
            // InkWell(
            //   onTap: () {
            //     setState(() {
            //       displayEnable = !displayEnable;
            //     });
            //   },
            //   child: Image.asset(
            //     displayEnable
            //         ? ImageAssets.displayEnable
            //         : ImageAssets.displayDis,
            //     width: 44,
            //   ),
            // ),
            S.h(8),
            InkWell(
              onTap: () async {
                if (!isRecordingLoading) {
                  if (!isRecordingOn) {
                    await meeting.startRecording(config: {"mode": "audio"});
                  } else {
                    await meeting.stopRecording();
                  }
                }
              },
              child: Image.asset(
                isRecordingLoading
                    ? ImageAssets.loading
                    : isRecordingOn
                        ? ImageAssets.recordDis
                        : ImageAssets.recordEnable,
                height: 44,
                width: 44,
              ),
            ),
            S.h(8),
            InkWell(
              onTap: () {
                setState(() {
                  micEnable = !micEnable;
                });
                if (micEnable && !widget.isMock) {
                  meeting.unmuteMic();
                } else {
                  meeting.muteMic();
                }
              },
              child: Image.asset(
                micEnable ? ImageAssets.micEnable : ImageAssets.micDis,
                width: 44,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tools() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (Responsive.isDesktop(context)) S.w(10),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AnimatedContainer(
              duration: const Duration(seconds: 1),
              curve: Curves.fastOutSlowIn,
              height: selectedTools ? 270 : 440,
              width: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: CustomColors.grayCFCFCF,
                  style: BorderStyle.solid,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(64),
                color: CustomColors.whitePrimary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  S.h(12),
                  // TODO: undo redo ??
                  // Expanded(
                  //   flex: 1,
                  //   child: Padding(
                  //     padding: const EdgeInsets.symmetric(
                  //         horizontal: defaultPadding, vertical: 1),
                  //     child: Row(
                  //       mainAxisAlignment: MainAxisAlignment.spaceAround,
                  //       children: [
                  //         InkWell(
                  //           onTap: () {
                  //             log("Undo");
                  //           },
                  //           child: Image.asset(
                  //             ImageAssets.undo,
                  //             width: 38,
                  //           ),
                  //         ),
                  //         InkWell(
                  //           onTap: () {
                  //             log("Redo");
                  //           },
                  //           child: Image.asset(
                  //             ImageAssets.redo,
                  //             width: 38,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  // Container(
                  //     height: 2, width: 80, color: CustomColors.grayF3F3F3),
                  selectedTools
                      ? Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  _listTools[_selectedIndexTools]
                                      ['image_active'],
                                  width: 10.w,
                                )
                              ],
                            ),
                          ),
                        )
                      : Expanded(
                          flex: 7, // flex 4 if have all
                          child: ListView.builder(
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              itemCount: _listTools.length,
                              itemBuilder: (context, index) {
                                return Column(
                                  children: [
                                    S.h(8),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedIndexTools = index;
                                        });
                                        if (currentScrollZoom.isNotEmpty) {
                                          addScrollZoom(currentScrollZoom,
                                              currentScrollZoom[0].timestamp);
                                          currentScrollZoom.clear();
                                        }
                                        if (index == 0) {
                                          _mode = DrawingMode.drag;
                                          int time = solveStopwatch
                                              .elapsed.inMilliseconds;
                                          for (int i = 0; i <= 4; i++) {
                                            sendMessage(
                                              'DrawingMode.drag',
                                              time,
                                            );
                                          }
                                        } // drag
                                        else if (index == 1) {
                                          _mode = DrawingMode.pen;
                                          int time = solveStopwatch
                                              .elapsed.inMilliseconds;
                                          for (int i = 0; i <= 4; i++) {
                                            sendMessage(
                                              'DrawingMode.pen',
                                              time,
                                            );
                                          }
                                        } // pen
                                        else if (index == 2) {
                                          _mode = DrawingMode.highlighter;
                                          int time = solveStopwatch
                                              .elapsed.inMilliseconds;
                                          for (int i = 0; i <= 4; i++) {
                                            sendMessage(
                                              'DrawingMode.highlighter',
                                              time,
                                            );
                                          }
                                        } // high
                                        else if (index == 3) {
                                          _mode = DrawingMode.eraser;
                                          int time = solveStopwatch
                                              .elapsed.inMilliseconds;
                                          for (int i = 0; i <= 4; i++) {
                                            sendMessage(
                                              'DrawingMode.eraser',
                                              time,
                                            );
                                          }
                                        } // eraser
                                        else if (index == 4) {
                                          _mode = DrawingMode.laser;
                                          int time = solveStopwatch
                                              .elapsed.inMilliseconds;
                                          for (int i = 0; i <= 4; i++) {
                                            sendMessage(
                                              'DrawingMode.laser',
                                              time,
                                            );
                                          }
                                        } // laser
                                      },
                                      child: Image.asset(
                                        _selectedIndexTools == index
                                            ? _listTools[index]['image_active']
                                            : _listTools[index]['image_dis'],
                                        width: 10.w,
                                      ),
                                    ),
                                  ],
                                );
                              }),
                        ),
                  Container(
                      height: 2, width: 80, color: CustomColors.grayF3F3F3),
                  Expanded(
                    flex: selectedTools ? 1 : 2,
                    child: Column(
                      children: [
                        S.h(defaultPadding),
                        if (!selectedTools)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 1),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              if (openLines ||
                                                  openMore == true) {
                                                openLines = false;
                                                openMore = false;
                                              }
                                              openColors = !openColors;
                                            });
                                          },
                                          child: Image.asset(
                                            _listColors[_selectedIndexColors]
                                                ['color'],
                                            width: 38,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              if (openColors ||
                                                  openMore == true) {
                                                openColors = false;
                                                openMore = false;
                                              }
                                              openLines = !openLines;
                                            });
                                          },
                                          child: Image.asset(
                                            ImageAssets.pickLine,
                                            width: 38,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // TODO: do we need clear btn ?
                                  // Expanded(
                                  //   child: Row(
                                  //     mainAxisAlignment:
                                  //         MainAxisAlignment.spaceEvenly,
                                  //     children: [
                                  //       InkWell(
                                  //         onTap: () {
                                  //           log("Clear");
                                  //         },
                                  //         child: Image.asset(
                                  //           ImageAssets.bin,
                                  //           width: 38,
                                  //         ),
                                  //       ),
                                  //       InkWell(
                                  //         onTap: () {
                                  //           log("More");
                                  //
                                  //           setState(() {
                                  //             if (openColors ||
                                  //                 openLines == true) {
                                  //               openColors = false;
                                  //               openLines = false;
                                  //             }
                                  //             openMore = !openMore;
                                  //           });
                                  //         },
                                  //         child: Image.asset(
                                  //           ImageAssets.more,
                                  //           width: 38,
                                  //         ),
                                  //       ),
                                  //     ],
                                  //   ),
                                  // ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedTools = !selectedTools;
                                        });
                                      },
                                      child: Image.asset(
                                        selectedTools
                                            ? ImageAssets.arrowDownDouble
                                            : ImageAssets.arrowTopDouble,
                                        width: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (selectedTools)
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  selectedTools = !selectedTools;
                                });
                              },
                              child: Image.asset(
                                selectedTools
                                    ? ImageAssets.arrowDownDouble
                                    : ImageAssets.arrowTopDouble,
                                width: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  ///Button for list student
  Widget showListStudents() {
    return Positioned(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  showStudent = !showStudent;
                });
              },
              child: Container(
                height: 40,
                width: 264,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: CustomColors.grayE5E6E9,
                      width: 1.0,
                      style: BorderStyle.solid),
                  color: CustomColors.whitePrimary,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    topLeft: Radius.circular(8),
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    showStudent ? ImageAssets.arrowDown : ImageAssets.icShared,
                    height: showStudent ? 16 : 22,
                    width: showStudent ? 16 : 25,
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              width: showStudent ? MediaQuery.of(context).size.width : 0,
              height: showStudent ? 105 : 0,
              decoration: BoxDecoration(
                border: Border.all(
                    color: CustomColors.grayE5E6E9,
                    width: 1.0,
                    style: BorderStyle.solid),
                color: CustomColors.whitePrimary,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  topLeft: Radius.circular(8),
                ),
              ),
              duration: const Duration(seconds: 1),
              curve: Curves.fastOutSlowIn,
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'แชร์จอ :',
                        style: CustomStyles.bold14Gray878787,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 80,
                    color: CustomColors.grayCFCFCF,
                  ),
                  S.w(defaultPadding),
                  Expanded(
                    flex: 5,
                    child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: students.length,
                      itemBuilder: (BuildContext context, int index) => Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: InkWell(
                              onTap: () {
                                if (_requestScreenShare == true) {
                                  setState(() {
                                    focusedStudentId = students[index]['id'];
                                    focusedStudentName =
                                        students[index]['name'];
                                  });
                                  var size = students[index]['solvepad_size']
                                      .split(',');
                                  changeSolvepadScaling(double.parse(size[0]),
                                      double.parse(size[1]));
                                  sendMessage(
                                    'FocusStudentScreen:${students[index]['id']}',
                                    solveStopwatch.elapsed.inMilliseconds,
                                  );
                                }
                              },
                              child: ColorFiltered(
                                colorFilter: students[index]['status_share'] ==
                                        'enable'
                                    ? const ColorFilter.mode(
                                        Colors.transparent, BlendMode.multiply)
                                    : const ColorFilter.matrix(<double>[
                                        0.2126,
                                        0.7152,
                                        0.0722,
                                        0,
                                        0,
                                        0.2126,
                                        0.7152,
                                        0.0722,
                                        0,
                                        0,
                                        0.2126,
                                        0.7152,
                                        0.0722,
                                        0,
                                        0,
                                        0,
                                        0,
                                        0,
                                        1,
                                        0,
                                      ]),
                                child: Container(
                                  height: 62,
                                  width: 62,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: NetworkImage(
                                        students[index]['image'],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              child: SizedBox(
                                width: 100,
                                child: Text(
                                  students[index]['name'],
                                  textAlign: TextAlign.center,
                                  style: CustomStyles.med14Black363636Overflow,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: () {
                                viewAllStudentModal();
                              },
                              child: Text(
                                'ทั้งหมด',
                                style: CustomStyles.bold14greenPrimary,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: InkWell(
                              onTap: () {
                                viewAllStudentModal();
                              },
                              child: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: CustomColors.greenPrimary,
                                size: 18.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget showListStudentsMobile() {
    return Positioned(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            /// TODO: revise this
            // if (showStudent)
            //   InkWell(
            //     onTap: () {
            //       setState(() {
            //         showStudent = false;
            //       });
            //     },
            //     child: Container(
            //       height: 40,
            //       width: 264,
            //       decoration: BoxDecoration(
            //         border: Border.all(
            //             color: CustomColors.grayE5E6E9,
            //             width: 1.0,
            //             style: BorderStyle.solid),
            //         color: CustomColors.whitePrimary,
            //         borderRadius: const BorderRadius.only(
            //           topRight: Radius.circular(8),
            //           topLeft: Radius.circular(8),
            //         ),
            //       ),
            //       child: Center(
            //         child: Image.asset(
            //           ImageAssets.arrowDown,
            //           height: showStudent ? 16 : 22,
            //           width: showStudent ? 16 : 25,
            //         ),
            //       ),
            //     ),
            //   ),
            AnimatedContainer(
              width: showStudent ? mySolvepadSize.width : 0,
              height: showStudent ? 105 : 0,
              decoration: BoxDecoration(
                border: Border.all(
                    color: CustomColors.grayE5E6E9,
                    width: 1.0,
                    style: BorderStyle.solid),
                color: CustomColors.whitePrimary,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  topLeft: Radius.circular(8),
                ),
              ),
              duration: const Duration(seconds: 1),
              curve: Curves.fastOutSlowIn,
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          'แชร์จอ:',
                          style: CustomStyles.bold14Gray878787,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 80,
                    color: CustomColors.grayCFCFCF,
                  ),
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: students.length,
                        itemBuilder: (BuildContext context, int index) =>
                            Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 3,
                              child: InkWell(
                                onTap: () {
                                  if (_requestScreenShare == true) {
                                    setState(() {
                                      focusedStudentId = students[index]['id'];
                                      focusedStudentName =
                                          students[index]['name'];
                                    });
                                    var size = students[index]['solvepad_size']
                                        .split(',');
                                    changeSolvepadScaling(
                                      double.parse(size[0]),
                                      double.parse(size[1]),
                                    );
                                    sendMessage(
                                      'FocusStudentScreen:${students[index]['id']}',
                                      solveStopwatch.elapsed.inMilliseconds,
                                    );
                                    showStudent = false;
                                  }
                                },
                                child: ColorFiltered(
                                  colorFilter: students[index]
                                              ['status_share'] ==
                                          'enable'
                                      ? const ColorFilter.mode(
                                          Colors.transparent,
                                          BlendMode.multiply)
                                      : const ColorFilter.matrix(<double>[
                                          0.2126,
                                          0.7152,
                                          0.0722,
                                          0,
                                          0,
                                          0.2126,
                                          0.7152,
                                          0.0722,
                                          0,
                                          0,
                                          0.2126,
                                          0.7152,
                                          0.0722,
                                          0,
                                          0,
                                          0,
                                          0,
                                          0,
                                          1,
                                          0,
                                        ]),
                                  child: Container(
                                    height: 62,
                                    width: 62,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        fit: BoxFit.cover,
                                        image: NetworkImage(
                                          students[index]['image'],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {},
                                child: SizedBox(
                                  width: 100,
                                  child: Text(
                                    students[index]['name'],
                                    textAlign: TextAlign.center,
                                    style:
                                        CustomStyles.med14Black363636Overflow,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: () async {
                                final int? selectedIndex = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViewAllStudentMobile(
                                      students: students,
                                    ),
                                  ),
                                );
                                log(selectedIndex.toString());
                                setState(() {
                                  focusedStudentId =
                                      students[selectedIndex!]['id'];
                                  focusedStudentName =
                                      students[selectedIndex]['name'];
                                });
                                if (selectedIndex == null) return;
                                var size = students[selectedIndex]
                                        ['solvepad_size']
                                    .split(',');
                                changeSolvepadScaling(double.parse(size[0]),
                                    double.parse(size[1]));
                                sendMessage(
                                  'FocusStudentScreen:${students[selectedIndex]['id']}',
                                  solveStopwatch.elapsed.inMilliseconds,
                                );
                                showStudent = false;
                              },
                              child: Text(
                                'ทั้งหมด',
                                style: CustomStyles.bold14greenPrimary,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViewAllStudentMobile(
                                      students: students,
                                    ),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: CustomColors.greenPrimary,
                                size: 18.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statusStudentShareScreen(String txt, String img) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: CustomColors.blueCFE8FC,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          S.w(defaultPadding),
          Image.asset(
            ImageAssets.displayBlue,
            width: 22,
          ),
          S.w(10),
          Text(
            txt,
            style: CustomStyles.bold14blue0D47A1,
          ),
          S.w(10),
          Image.asset(
            img,
            width: 22,
          ),
          S.w(10),
          Container(
            width: 1,
            height: 16,
            color: CustomColors.blue0D47A1,
          ),
          S.w(10),
          InkWell(
              onTap: () {
                sendMessage(
                  'HostLeaveScreen:$focusedStudentId',
                  solveStopwatch.elapsed.inMilliseconds,
                );
                focusedStudentId = '';
                focusedStudentName = '';
                cleanStudentSolvepad();
              },
              child: Text("ออก", style: CustomStyles.bold14blue0D47A1Line)),
          S.w(defaultPadding),
        ],
      ),
    );
  }

  Widget statusScreenRed(String txt, String img) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: CustomColors.pinkFFCDD2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          S.w(16),
          Image.asset(
            img,
            width: 22,
          ),
          S.w(12),
          Text(
            txt,
            style: CustomStyles.bold14RedB71C1C,
          ),
          S.w(16),
        ],
      ),
    );
  }

  Widget statusShareScreen(String txt, String img) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: CustomColors.greenB9E7C9,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          S.w(16),
          Image.asset(
            img,
            width: 22,
          ),
          S.w(12),
          Text(
            txt,
            style: CustomStyles.bold14greenPrimary,
          ),
          S.w(16),
        ],
      ),
    );
  }

  Widget statusShareScreenMobile() {
    return Positioned(
      top: 70,
      left: 70,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!micEnable)
            statusScreenRed(
                "You’re Muted", ImageAssets.micMuteRed), // should be micMuteRed
          S.h(16),
          // TODO: reconsider this
          if (focusedStudentId != '' && _isViewingFocusStudent)
            statusStudentShareScreen(
                "หน้าจอ: $focusedStudentName", ImageAssets.avatarWomen),
        ],
      ),
    );
  }

  Widget statusTouchMode() {
    return InkWell(
      onTap: () {
        setState(() {
          _isStylusActive = !_isStylusActive;
        });
      },
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: CustomColors.greenPrimary,
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              _isStylusActive = !_isStylusActive;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              S.w(16),
              Image.asset(
                _isStylusActive
                    ? 'assets/images/pencil-dis.png'
                    : 'assets/images/hand-dis.png',
                width: 22,
              ),
              S.w(12),
              Text(
                _isStylusActive ? 'Stylus mode' : 'Touch mode',
                style: CustomStyles.bold14White,
              ),
              S.w(16),
            ],
          ),
        ),
      ),
    );
  }

  Widget statusTouchModeIcon() {
    return InkWell(
      onTap: () {
        setState(() {
          _isStylusActive = !_isStylusActive;
        });
      },
      child: Image.asset(
        _isStylusActive
            ? 'assets/images/stylus-icon.png'
            : 'assets/images/touch-icon.png',
        height: 44,
        width: 44,
      ),
    );
  }

  Future<void> quizSelectModal() {
    Color getColor(Set<MaterialState> states) {
      const Set<MaterialState> interactiveStates = <MaterialState>{
        MaterialState.pressed,
        MaterialState.hovered,
        MaterialState.focused
      };

      return CustomColors.greenPrimary;
    }

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                ///Header
                Material(
                  color: Colors.transparent,
                  child: Container(
                    height: 60,
                    color: CustomColors.whitePrimary,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        S.w(Responsive.isTablet(context) ? 5 : 24),
                        if (Responsive.isTablet(context))
                          Expanded(
                            flex: 3,
                            child: Text(
                              courseName,
                              style: CustomStyles.bold16Black363636Overflow,
                              maxLines: 1,
                            ),
                          ),
                        if (Responsive.isDesktop(context))
                          Expanded(
                            flex: 4,
                            child: Text(
                              courseName,
                              style: CustomStyles.bold16Black363636Overflow,
                              maxLines: 1,
                            ),
                          ),
                        if (Responsive.isMobile(context))
                          Expanded(
                            flex: 2,
                            child: Text(
                              courseName,
                              style: CustomStyles.bold16Black363636Overflow,
                              maxLines: 1,
                            ),
                          ),
                        Expanded(
                            flex: Responsive.isDesktop(context) ? 3 : 4,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: 32,
                                  width: 145,
                                  // margin: EdgeInsets.only(top: defaultPadding),
                                  // padding: EdgeInsets.all(defaultPadding),
                                  decoration: const BoxDecoration(
                                    color: CustomColors.pinkFFCDD2,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(defaultPadding),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        ImageAssets.lowSignal,
                                        height: 22,
                                        width: 18,
                                      ),
                                      S.w(10),
                                      Flexible(
                                        child: Text(
                                          "สัญญาณอ่อน",
                                          style: CustomStyles.bold14redB71C1C,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                S.w(16.0),
                                Container(
                                  height: 11,
                                  width: 11,
                                  decoration: BoxDecoration(
                                      color: CustomColors.redF44336,
                                      borderRadius: BorderRadius.circular(100)
                                      //more than 50% of width makes circle
                                      ),
                                ),
                                S.w(4.0),
                                RichText(
                                  text: TextSpan(
                                    text: 'Live Time: ',
                                    style: CustomStyles.med14redFF4201,
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: '01 : 59 : 59',
                                        style: CustomStyles.med14Gray878787,
                                      ),
                                    ],
                                  ),
                                ),
                                S.w(16.0),
                                InkWell(
                                  onTap: () {
                                    showCloseDialog(context, () {});
                                  },
                                  child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: defaultPadding * 1,
                                        vertical: defaultPadding / 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: CustomColors.redF44336,
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "ปิดห้องเรียน",
                                            style: CustomStyles.bold14White,
                                          ),
                                        ],
                                      )),
                                ),
                                S.w(Responsive.isTablet(context) ? 5 : 24),
                              ],
                            ))
                      ],
                    ),
                  ),
                ),

                ///Modal Quiz title
                Expanded(
                  child: Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 0,
                    backgroundColor: CustomColors.grayF3F3F3,
                    child: SingleChildScrollView(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.6,
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text('เลือก Quiz ที่จะแชร์ให้นักเรียน',
                                  style: CustomStyles.bold22Black363636),
                              S.h(4),
                              Text(
                                  'ติ๊กเลือก์ชุดคำถามที่จะแชร์ให้นักเรียนในห้อง คุณสามารถแก้ไขคำถามได้ที่หน้า “ตั้งค่า” คอร์สเรียน',
                                  style: CustomStyles.med14Gray878787),
                              S.h(24),

                              /// Quiz
                              ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  scrollDirection: Axis.vertical,
                                  shrinkWrap: true,
                                  itemCount: quizList.length,
                                  itemBuilder: (context, index) {
                                    return Column(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              quizList[index].isSelected =
                                                  !quizList[index].isSelected;
                                            });
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            height: 54,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: quizList[index]
                                                              .isSelected ==
                                                          false
                                                      ? CustomColors.grayE5E6E9
                                                      : CustomColors
                                                          .greenPrimary,
                                                  width: 1.0,
                                                  style: BorderStyle.solid),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              color: quizList[index]
                                                          .isSelected ==
                                                      false
                                                  ? CustomColors.whitePrimary
                                                  : CustomColors.greenE5F6EB,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Checkbox(
                                                  checkColor: Colors.white,
                                                  fillColor:
                                                      MaterialStateProperty
                                                          .resolveWith(
                                                              getColor),
                                                  value: quizList[index]
                                                      .isSelected,
                                                  onChanged: (bool? value) {
                                                    log('checkbox tapped');
                                                    setState(() {
                                                      quizList[index]
                                                              .isSelected =
                                                          !quizList[index]
                                                              .isSelected;
                                                    });
                                                    // setState(() {
                                                    //   isChecked = value!;
                                                    // });
                                                  },
                                                ),
                                                Text(
                                                  quizList[index].quiz,
                                                  style: quizList[index]
                                                              .isSelected ==
                                                          false
                                                      ? CustomStyles
                                                          .bold16Black363636Overflow
                                                      : CustomStyles
                                                          .bold16greenPrimaryOverflow,
                                                ),
                                                Expanded(child: Container()),
                                                Text(
                                                  quizList[index].choice,
                                                  style: quizList[index]
                                                              .isSelected ==
                                                          false
                                                      ? CustomStyles
                                                          .med16gray878787
                                                      : CustomStyles.med16Green,
                                                ),
                                                S.w(20),
                                                const Icon(
                                                  Icons
                                                      .arrow_forward_ios_rounded,
                                                  color:
                                                      CustomColors.greenPrimary,
                                                  size: 16.0,
                                                ),
                                                S.w(12),
                                              ],
                                            ),
                                          ),
                                        ),
                                        S.h(16),
                                      ],
                                    );
                                  }),
                              S.h(24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: 165,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: CustomColors.grayCFCFCF,
                                        style: BorderStyle.solid,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: CustomColors.whitePrimary,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        const Icon(
                                          Icons.arrow_back,
                                          size: 20,
                                          color: CustomColors.gray878787,
                                        ),
                                        S.w(4),
                                        Text("กลับไปที่ห้องเรียน",
                                            textAlign: TextAlign.center,
                                            style:
                                                CustomStyles.bold14Gray878787),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 185,
                                    height: 40,
                                    child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              CustomColors.greenPrimary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                8.0), // <-- Radius
                                          ), // NEW
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          shareQuizModal();
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              ImageAssets.icShareWhite,
                                              width: 16,
                                            ),
                                            S.w(10),
                                            Text('แชร์ Quiz (2)',
                                                style: CustomStyles.bold14White)
                                          ],
                                        )),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<void> shareQuizModal() {
    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                ///Header1
                Material(
                  color: Colors.transparent,
                  child: Container(
                    height: 60,
                    color: CustomColors.whitePrimary,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        S.w(Responsive.isTablet(context) ? 5 : 24),
                        if (Responsive.isTablet(context))
                          Expanded(
                            flex: 3,
                            child: Text(
                              courseName,
                              style: CustomStyles.bold16Black363636Overflow,
                              maxLines: 1,
                            ),
                          ),
                        if (Responsive.isDesktop(context))
                          Expanded(
                            flex: 4,
                            child: Text(
                              courseName,
                              style: CustomStyles.bold16Black363636Overflow,
                              maxLines: 1,
                            ),
                          ),
                        if (Responsive.isMobile(context))
                          Expanded(
                            flex: 2,
                            child: Text(
                              courseName,
                              style: CustomStyles.bold16Black363636Overflow,
                              maxLines: 1,
                            ),
                          ),
                        Expanded(
                            flex: Responsive.isDesktop(context) ? 3 : 4,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: 32,
                                  width: 145,
                                  // margin: EdgeInsets.only(top: defaultPadding),
                                  // padding: EdgeInsets.all(defaultPadding),
                                  decoration: const BoxDecoration(
                                    color: CustomColors.pinkFFCDD2,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(defaultPadding),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        ImageAssets.lowSignal,
                                        height: 22,
                                        width: 18,
                                      ),
                                      S.w(10),
                                      Flexible(
                                        child: Text(
                                          "สัญญาณอ่อน",
                                          style: CustomStyles.bold14redB71C1C,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                S.w(16.0),
                                Container(
                                  height: 11,
                                  width: 11,
                                  decoration: BoxDecoration(
                                      color: CustomColors.redF44336,
                                      borderRadius: BorderRadius.circular(100)
                                      //more than 50% of width makes circle
                                      ),
                                ),
                                S.w(4.0),
                                RichText(
                                  text: TextSpan(
                                    text: 'Live Time: ',
                                    style: CustomStyles.med14redFF4201,
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: '01 : 59 : 59',
                                        style: CustomStyles.med14Gray878787,
                                      ),
                                    ],
                                  ),
                                ),
                                S.w(16.0),
                                InkWell(
                                  onTap: () {
                                    showCloseDialog(context, () {});
                                  },
                                  child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: defaultPadding * 1,
                                        vertical: defaultPadding / 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: CustomColors.redF44336,
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "ปิดห้องเรียน",
                                            style: CustomStyles.bold14White,
                                          ),
                                        ],
                                      )),
                                ),
                                S.w(Responsive.isTablet(context) ? 5 : 24),
                              ],
                            ))
                      ],
                    ),
                  ),
                ),
                Material(
                  // color: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    height: 1,
                    color: CustomColors.grayCFCFCF,
                  ),
                ),

                ///Header2
                Material(
                  color: Colors.transparent,
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                        color: CustomColors.whitePrimary,
                        boxShadow: [
                          BoxShadow(
                              color: CustomColors.gray878787.withOpacity(.1),
                              offset: const Offset(0.0, 6),
                              blurRadius: 10,
                              spreadRadius: 1)
                        ]),
                    child: Row(
                      children: [
                        S.w(Responsive.isTablet(context) ? 5 : 24),
                        Expanded(
                          flex: 2,
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: CustomColors.grayCFCFCF,
                                      style: BorderStyle.solid,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: CustomColors.whitePrimary,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 1, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Image.asset(
                                        ImageAssets.allPages,
                                        height: 30,
                                        width: 32,
                                      ),
                                      S.w(defaultPadding),
                                      Container(
                                        width: 1,
                                        height: 24,
                                        color: CustomColors.grayCFCFCF,
                                      ),
                                      S.w(defaultPadding),
                                      Image.asset(
                                        ImageAssets.backDis,
                                        height: 16,
                                        width: 17,
                                      ),
                                      S.w(defaultPadding),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: CustomColors.grayCFCFCF,
                                            style: BorderStyle.solid,
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          color: CustomColors.whitePrimary,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Text("Page 20",
                                                style: CustomStyles
                                                    .bold14greenPrimary),
                                          ],
                                        ),
                                      ),
                                      S.w(8.0),
                                      Text("/ 149",
                                          style: CustomStyles.med14Gray878787),
                                      S.w(defaultPadding),
                                      Image.asset(
                                        ImageAssets.forward,
                                        height: 16,
                                        width: 17,
                                      ),
                                      S.w(6.0),
                                    ],
                                  ))),
                        ),
                        Expanded(
                            flex: 3,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      micEnable = !micEnable;
                                    });
                                    if (micEnable && !widget.isMock) {
                                      meeting.unmuteMic();
                                    } else {
                                      meeting.muteMic();
                                    }
                                  },
                                  child: Image.asset(
                                    micEnable
                                        ? ImageAssets.micEnable
                                        : ImageAssets.micDis,
                                    height: 44,
                                    width: 44,
                                  ),
                                ),
                                S.w(defaultPadding),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      displayEnable = !displayEnable;
                                    });
                                  },
                                  child: Image.asset(
                                    displayEnable
                                        ? ImageAssets.displayEnable
                                        : ImageAssets.displayDis,
                                    height: 44,
                                    width: 44,
                                  ),
                                ),
                                S.w(defaultPadding),

                                ///todo Icon share for disable
                                // Image.asset(
                                //   ImageAssets.shareQa,
                                //   height: 44,
                                //   width: 44,
                                // ),
                                Stack(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        quizSelectModal();
                                      },
                                      child: Image.asset(
                                        ImageAssets.icShareAction,
                                        height: 44,
                                        width: 44,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 32, bottom: 1),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                            color: CustomColors.black363636,
                                            shape: BoxShape.circle),
                                        width: 25,
                                        height: 25,
                                        child: Center(
                                          child: Text(
                                            "12",
                                            style: CustomStyles.bold11White,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                ///End icon share
                                S.w(defaultPadding),
                                const DividerVer(),
                                S.w(defaultPadding),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: CustomColors.grayCFCFCF,
                                      style: BorderStyle.solid,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(100),
                                    color: CustomColors.whitePrimary,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Transform.scale(
                                        scale: 0.7,
                                        child: CupertinoSwitch(
                                          value: _switchValue,
                                          onChanged: (bool value) {
                                            setState(() {
                                              _switchValue = value;
                                            });
                                          },
                                        ),
                                      ),
                                      Text("ให้นักเรียนแชร์จอ",
                                          textAlign: TextAlign.center,
                                          style: CustomStyles.bold14Gray878787),
                                      S.w(4)
                                    ],
                                  ),
                                )
                              ],
                            )),

                        /// Statistics
                        Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: InkWell(
                                onTap: () {
                                  log('Go to Statistics');
                                  showLeader(context);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: CustomColors.grayCFCFCF,
                                      style: BorderStyle.solid,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: CustomColors.whitePrimary,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 1, vertical: 6),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Image.asset(
                                          ImageAssets.leaderboard,
                                          height: 23,
                                          width: 25,
                                        ),
                                        S.w(8),
                                        Container(
                                          width: 1,
                                          height: 24,
                                          color: CustomColors.grayCFCFCF,
                                        ),
                                        S.w(8),
                                        Image.asset(
                                          ImageAssets.checkTrue,
                                          height: 18,
                                          width: 18,
                                        ),
                                        if (!Responsive.isTablet(context))
                                          S.w(8.0),
                                        Text("100%",
                                            style:
                                                CustomStyles.bold14Gray878787),
                                        if (!Responsive.isTablet(context))
                                          S.w(8.0),
                                        Image.asset(
                                          ImageAssets.x,
                                          height: 18,
                                          width: 18,
                                        ),
                                        if (!Responsive.isTablet(context))
                                          S.w(8.0),
                                        Text("100%",
                                            style:
                                                CustomStyles.bold14Gray878787),
                                        if (!Responsive.isTablet(context))
                                          S.w(8.0),
                                        Image.asset(
                                          ImageAssets.icQa,
                                          height: 18,
                                          width: 18,
                                        ),
                                        if (!Responsive.isTablet(context))
                                          S.w(8.0),
                                        Text("100%",
                                            style:
                                                CustomStyles.bold14Gray878787),
                                        if (!Responsive.isTablet(context))
                                          S.w(8.0),
                                        Image.asset(
                                          ImageAssets.arrowNextCircle,
                                          width: 21,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )),
                        S.w(Responsive.isTablet(context) ? 5 : 24),
                      ],
                    ),
                  ),
                ),

                ///Modal Share Quiz
                Expanded(
                  child: Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 0,
                    backgroundColor: CustomColors.whitePrimary,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: CustomColors.greenPrimary),
                                  child: InkWell(
                                    onTap: () {
                                      if (focusQuestion != 0) {
                                        setState(() {
                                          focusQuestion--;
                                        });
                                      }
                                    },
                                    child: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 16,
                                      color: CustomColors.whitePrimary,
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(quizSetData.quizSetName,
                                        style: CustomStyles.bold22Black363636),
                                    Row(
                                      children: [
                                        Text(
                                          '2 ข้อ',
                                          style: CustomStyles.med16gray878787,
                                        ),
                                        S.w(defaultPadding),
                                        Container(
                                          width: 1,
                                          height: 16,
                                          color: CustomColors.grayCFCFCF,
                                        ),
                                        Transform.scale(
                                          scale: 0.7,
                                          child: CupertinoSwitch(
                                            value: _switchShareValue,
                                            onChanged: (bool value) {
                                              setState(() {
                                                _switchShareValue = value;
                                              });
                                            },
                                          ),
                                        ),
                                        Text(
                                          "แชร์คำถามให้นักเรียน",
                                          style: CustomStyles.bold14Gray878787,
                                        )
                                      ],
                                    )
                                  ],
                                ),
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: CustomColors.greenPrimary),
                                  child: InkWell(
                                    onTap: () {
                                      if (focusQuestion + 1 <
                                          quizSetData.quizQuestions.length) {
                                        setState(() {
                                          focusQuestion++;
                                        });
                                      }
                                    },
                                    child: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: CustomColors.whitePrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            S.h(12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  quizSetData.quizQuestions[focusQuestion]
                                      .questionText,
                                  style: CustomStyles.bold16Black363636Overflow,
                                ),
                                S.h(12),
                                ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  scrollDirection: Axis.vertical,
                                  shrinkWrap: true,
                                  itemCount: quizSetData
                                      .quizQuestions[focusQuestion]
                                      .choices
                                      .length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return Container(
                                      width: double.infinity,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: CustomColors.grayE5E6E9,
                                            width: 1.0,
                                            style: BorderStyle.solid),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Radio(
                                              value: index,
                                              groupValue: radioTest,
                                              onChanged: (value) {
                                                setState(() {
                                                  radioTest = value!;
                                                });
                                              }),
                                          Text(
                                            quizSetData
                                                .quizQuestions[focusQuestion]
                                                .choices[index],
                                            style: CustomStyles
                                                .bold16Black363636Overflow,
                                          ),
                                          Expanded(child: Container()),
                                          const Icon(
                                            Icons.check,
                                            color: CustomColors.greenPrimary,
                                            size: 16.0,
                                          ),
                                          S.w(20),
                                          Text(
                                            'ถุกต้อง',
                                            style: CustomStyles.med16Green,
                                          ),
                                          S.w(12),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            S.h(18),
                            Center(
                              child: SizedBox(
                                width: 185,
                                height: 40,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: CustomColors.greenPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          8.0), // <-- Radius
                                    ), // NEW
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.arrow_back,
                                        color: CustomColors.whitePrimary,
                                        size: 20.0,
                                      ),
                                      S.w(4),
                                      Text('กลับไปที่ห้องเรียน',
                                          style: CustomStyles.bold14White)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> viewAllStudentModal() {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return Column(
            children: [
              ///Header
              Material(
                color: Colors.transparent,
                child: Container(
                  height: 60,
                  color: CustomColors.whitePrimary,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      S.w(Responsive.isTablet(context) ? 5 : 24),
                      if (Responsive.isTablet(context))
                        Expanded(
                          flex: 3,
                          child: Text(
                            courseName,
                            style: CustomStyles.bold16Black363636Overflow,
                            maxLines: 1,
                          ),
                        ),
                      if (Responsive.isDesktop(context))
                        Expanded(
                          flex: 4,
                          child: Text(
                            courseName,
                            style: CustomStyles.bold16Black363636Overflow,
                            maxLines: 1,
                          ),
                        ),
                      if (Responsive.isMobile(context))
                        Expanded(
                          flex: 2,
                          child: Text(
                            courseName,
                            style: CustomStyles.bold16Black363636Overflow,
                            maxLines: 1,
                          ),
                        ),
                      Expanded(
                        flex: Responsive.isDesktop(context) ? 3 : 4,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: 32,
                              width: 145,
                              // margin: EdgeInsets.only(top: defaultPadding),
                              // padding: EdgeInsets.all(defaultPadding),
                              decoration: const BoxDecoration(
                                color: CustomColors.pinkFFCDD2,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(defaultPadding),
                                ),
                              ),
                              // child: Row(
                              //   mainAxisAlignment: MainAxisAlignment.center,
                              //   children: [
                              //     Image.asset(
                              //       ImageAssets.lowSignal,
                              //       height: 22,
                              //       width: 18,
                              //     ),
                              //     S.w(10),
                              //     Flexible(
                              //       child: Text(
                              //         "สัญญาณอ่อน",
                              //         style: CustomStyles.bold14redB71C1C,
                              //         maxLines: 1,
                              //         overflow: TextOverflow.ellipsis,
                              //       ),
                              //     ),
                              //   ],
                              // ),
                            ),
                            S.w(16.0),
                            Container(
                              height: 11,
                              width: 11,
                              decoration: BoxDecoration(
                                  color: CustomColors.redF44336,
                                  borderRadius: BorderRadius.circular(100)
                                  //more than 50% of width makes circle
                                  ),
                            ),
                            S.w(4.0),
                            RichText(
                              text: TextSpan(
                                text: 'Live Time: ',
                                style: CustomStyles.med14redFF4201,
                                children: <TextSpan>[
                                  TextSpan(
                                    text: '01 : 59 : 59',
                                    style: CustomStyles.med14Gray878787,
                                  ),
                                ],
                              ),
                            ),
                            S.w(16.0),
                            InkWell(
                              onTap: () {
                                showCloseDialog(context, () {});
                              },
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: defaultPadding * 1,
                                    vertical: defaultPadding / 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: CustomColors.redF44336,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "ปิดห้องเรียน",
                                        style: CustomStyles.bold14White,
                                      ),
                                    ],
                                  )),
                            ),
                            S.w(Responsive.isTablet(context) ? 5 : 24),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),

              ///Modal list student
              Expanded(
                child: Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 0,
                  backgroundColor: CustomColors.grayF3F3F3,
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                S.w(32),
                                Text('สลับหน้าไปจอของ...',
                                    style: CustomStyles.bold22Black363636),
                                Expanded(child: Container()),
                                SizedBox(
                                  height: 40,
                                  width: 220,
                                  child: TextFormField(
                                    keyboardType: TextInputType.visiblePassword,
                                    decoration: InputDecoration(
                                      labelText: 'ค้นหาชื่อผู้เรียน',
                                      labelStyle: CustomStyles.med14Gray878787,
                                      border: const OutlineInputBorder(),
                                      suffixIcon: const Icon(
                                        Icons.search,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                S.w(32),
                              ],
                            ),
                            S.h(24),
                            SizedBox(
                              width: double.infinity,
                              height: 340,
                              child: GridView.builder(
                                  primary: false,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 18 / 4,
                                          crossAxisSpacing: 20,
                                          mainAxisSpacing: 20),
                                  itemCount: students.length,
                                  itemBuilder: (BuildContext context, index) {
                                    return Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          color: CustomColors.whitePrimary,
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Row(
                                        children: [
                                          S.w(defaultPadding),
                                          Image.network(
                                            students[index]['image'],
                                            height: 62,
                                            width: 62,
                                          ),
                                          S.w(defaultPadding),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 118,
                                                child: Text(
                                                  students[index]['name'],
                                                  style: CustomStyles
                                                      .bold16Black363636Overflow,
                                                  maxLines: 1,
                                                ),
                                              ),
                                              S.h(4),
                                              if (students[index]
                                                      ['status_share'] !=
                                                  'disable') ...[
                                                Row(
                                                  children: [
                                                    Image.asset(
                                                      ImageAssets.shareGreen,
                                                      width: 22,
                                                    ),
                                                    S.w(3),
                                                    Text(
                                                      'Sharing Screen',
                                                      style: CustomStyles
                                                          .bold12greenPrimary,
                                                    ),
                                                  ],
                                                ),
                                              ] // if share
                                              else ...[
                                                Text(
                                                  'Not allow sharing yet',
                                                  style: CustomStyles
                                                      .med12gray878787,
                                                ),
                                              ] // if not share
                                            ],
                                          ),
                                          Expanded(child: Container()),
                                          if (students[index]['status_share'] !=
                                                  'disable' &&
                                              students[index]['share_now'] ==
                                                  'N')
                                            SizedBox(
                                              width: 80,
                                              height: 30,
                                              child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        CustomColors
                                                            .greenPrimary,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0), // <-- Radius
                                                    ), // NEW
                                                  ),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    if (_requestScreenShare ==
                                                        true) {
                                                      setState(() {
                                                        focusedStudentId =
                                                            students[index]
                                                                ['id'];
                                                        focusedStudentName =
                                                            students[index]
                                                                ['name'];
                                                      });
                                                      var size = students[index]
                                                              ['solvepad_size']
                                                          .split(',');
                                                      changeSolvepadScaling(
                                                          double.parse(size[0]),
                                                          double.parse(
                                                              size[1]));
                                                      sendMessage(
                                                        'FocusStudentScreen:${students[index]['id']}',
                                                        solveStopwatch.elapsed
                                                            .inMilliseconds,
                                                      );
                                                    }
                                                  },
                                                  child: Text('เลือก',
                                                      style: CustomStyles
                                                          .bold14White)),
                                            ),
                                          if (students[index]['share_now'] ==
                                              'Y')
                                            Container(
                                              width: 118,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color:
                                                      CustomColors.grayCFCFCF,
                                                  style: BorderStyle.solid,
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                color:
                                                    CustomColors.whitePrimary,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "ออกจากการแชร์",
                                                  style: CustomStyles
                                                      .bold14Gray878787Overflow,
                                                ),
                                              ),
                                            ),
                                          S.w(8)
                                        ],
                                      ),
                                    );
                                  }),
                            ),
                            S.h(24),
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Container(
                                width: 120,
                                height: 40,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: CustomColors.grayCFCFCF,
                                    style: BorderStyle.solid,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: CustomColors.whitePrimary,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Icon(
                                      Icons.arrow_back,
                                      size: 24,
                                      color: CustomColors.gray878787,
                                    ),
                                    S.w(8),
                                    Text("ย้อนกลับ",
                                        textAlign: TextAlign.center,
                                        style: CustomStyles.bold14Gray878787),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        });
  }
}
