import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/feature/calendar/controller/create_course_controller.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';

import '../../../firebase/database.dart';
import '../../calendar/constants/custom_styles.dart';
import '../../calendar/model/course_model.dart';
import '../../calendar/widgets/alert_overlay.dart';
import '../../calendar/widgets/alert_snackbar.dart';
import '../../calendar/widgets/sizebox.dart';

import '../../calendar/constants/assets_manager.dart';
import '../../calendar/constants/custom_colors.dart';
import '../../live_classroom/components/close_dialog.dart';
import '../../live_classroom/components/divider.dart';
import '../../live_classroom/components/divider_vertical.dart';
import '../../live_classroom/components/leaderboard.dart';
import '../../live_classroom/components/room_loading_screen.dart';
import '../../live_classroom/quiz/quiz_model.dart';
import '../../live_classroom/solvepad/solve_watch.dart';
import '../../live_classroom/solvepad/solvepad_drawer.dart';
import '../../live_classroom/solvepad/solvepad_stroke_model.dart';
import '../../live_classroom/utils/responsive.dart';

class RecordCourse extends StatefulWidget {
  final CourseModel course;
  final Lessons lesson;
  const RecordCourse({
    Key? key,
    required this.lesson,
    required this.course,
  }) : super(key: key);

  @override
  State<RecordCourse> createState() => _RecordCourseState();
}

class _RecordCourseState extends State<RecordCourse> {
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
  FirebaseService firebaseService = FirebaseService();

  // ---------- VARIABLE: Solve Pad data
  late List<String> _pages = [];
  final List<List<SolvepadStroke?>> _penPoints = [[]];
  final List<List<SolvepadStroke?>> _laserPoints = [[]];
  final List<List<SolvepadStroke?>> _highlighterPoints = [[]];
  final List<Offset> _eraserPoints = [const Offset(-100, -100)];
  final List<List<Offset?>> _replayPoints = [[]];
  DrawingMode _mode = DrawingMode.drag;
  final SolveStopwatch solveStopwatch = SolveStopwatch();

  // ---------- VARIABLE: Solve Size
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
  String _formattedElapsedTime = 'Recording 00:00:00';
  bool _isPrevBtnActive = false;
  bool _isNextBtnActive = true;
  int? activePointerId;

  // ---------- VARIABLE: page control
  Timer? _laserTimer;
  Timer? _recordTimer;
  int _currentPage = 0;
  final PageController _pageController = PageController();
  final List<TransformationController> _transformationController = [];
  var courseController = CourseController();
  late String courseName;
  bool isCourseLoaded = false;
  bool isRecording = false;
  bool isRecordEnd = false;
  bool isReplaying = false;
  bool isReplayEnd = true;

  // ---------- VARIABLE: recorder
  Codec _codec = Codec.aacMP4;
  String _mPath = 'tau_file.mp4';
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  FlutterSoundRecorder? _mRecorder = FlutterSoundRecorder();
  bool _mPlayerIsInited = false;
  bool _mRecorderIsInited = false;
  bool _mPlaybackReady = false;

  // ---------- VARIABLE: new format
  late Map<String, dynamic> _data;
  String jsonData = '';
  late List<Map<String, dynamic>> _actions;
  List<StrokeStamp> currentStroke = [];
  List<dynamic> currentEraserStroke = [];
  List<ScrollZoomStamp> currentScrollZoom = [];
  int currentReplayIndex = 0;
  int currentReplayPointIndex = 0;
  int currentReplayScrollIndex = 0;
  double currentScale = 2.0;
  double currentScrollX = 2.0;
  double currentScrollY = 0;
  Timer? _sliderTimer;
  double replayProgress = 0;
  int replayDuration = 100;

  /// TODO: Get rid of all Mockup reference
  @override
  void initState() {
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
    initAudio();
    initPagesData();
    initPagingBtn();
  }

  void initAudio() {
    _mPlayer!.openPlayer().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });
    openTheRecorder().then((value) {
      setState(() {
        _mRecorderIsInited = true;
      });
    });
  }

  Future<void> initPagesData() async {
    await courseController.getCourseById(widget.course.id!);
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
      isCourseLoaded = true;
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

  @override
  dispose() {
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.portraitDown,
    //   DeviceOrientation.landscapeRight,
    //   DeviceOrientation.landscapeLeft,
    // ]);
    _mPlayer!.closePlayer();
    _mPlayer = null;
    _mRecorder!.closeRecorder();
    _mRecorder = null;
    _pageController.dispose();
    _recordTimer?.cancel();
    _sliderTimer?.cancel();
    _laserTimer?.cancel();
    super.dispose();
  }

  Future<bool> _onWillPopScope() async {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return true;
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

  // ---------- FUNCTION: page control
  void _addPage() {
    setState(() {
      _penPoints.add([]);
      _laserPoints.add([]);
      _highlighterPoints.add([]);
      _eraserPoints.add(const Offset(-100, -100));
      _replayPoints.add([]);
    });
  }

  void _onPageViewChange(int page) {
    setState(() {
      for (var point in _laserPoints) {
        point.clear();
      }
      _currentPage = page;
      _penPoints[_currentPage].add(null);
    });
    if (isRecording) {
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
  }

  String _formatElapsedTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return 'Recording $hours:$minutes:$seconds';
  }

  String _formatReplayElapsedTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  // ---------- FUNCTION: solve pad feature
  double square(double x) => x * x;
  double sqrDistanceBetween(Offset p1, Offset p2) =>
      square(p1.dx - p2.dx) + square(p1.dy - p2.dy);

  void doErase(int index, DrawingMode mode) {
    int prevNullIndex = -1;
    int nextNullIndex = -1;
    List<SolvepadStroke?> pointStack;
    if (mode == DrawingMode.highlighter) {
      pointStack = _highlighterPoints[_currentPage];
    } else {
      pointStack = _penPoints[_currentPage];
    }
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
      currentEraserStroke.add([
        mode,
        prevNullIndex,
        nextNullIndex,
        solveStopwatch.elapsed.inMilliseconds
      ]);
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

  void initSolvepadData() {
    _data = {
      "version": "2.0.0",
      "solvepadWidth": mySolvepadSize.width,
      "solvepadHeight": mySolvepadSize.height,
      "metadata": {
        "courseId": widget.course.id,
        "tutorId": widget.course.tutorId,
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

  void _initRecord() {
    solveStopwatch.reset();
    solveStopwatch.start();
    setState(() {
      isRecording = true;
    });
    _startRecordTimer();
    initSolvepadData();
  }

  void _startRecordTimer() {
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _formattedElapsedTime = _formatElapsedTime(solveStopwatch.elapsed);
      });
    });
  }

  void _stopSolvePadRecord() {
    isRecording = false;
    _mode = DrawingMode.drag;
    if (currentScrollZoom.isNotEmpty) {
      addScrollZoom(currentScrollZoom, currentScrollZoom[0].timestamp);
      currentScrollZoom.clear();
    }
    _actions.add({
      "time": solveStopwatch.elapsed.inMilliseconds,
      "type": "stop-recording",
      "data": null
    });
    replayDuration = solveStopwatch.elapsed.inMilliseconds;
    _data['metadata']['duration'] = replayDuration;
    solveStopwatch.reset();
    _stopRecordTimer();
    setState(() {});
  }

  void _stopRecordTimer() {
    _recordTimer?.cancel();
    _recordTimer = null;
    _formattedElapsedTime = 'Record end';
    setState(() {
      isRecordEnd = true;
    });
  }

  void addDrawing(List<StrokeStamp> strokeStamp, int initTime) {
    if (isRecording) {
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
  }

  void addErasing(List<dynamic> eraserStroke) {
    if (isRecording && eraserStroke.isNotEmpty) {
      List<Map<String, dynamic>> formattedActions = [];
      List<Map<String, dynamic>> moveActions = [];

      for (var action in eraserStroke) {
        if (action[0] is Offset) {
          moveActions.add({
            'x': double.parse(action[0].dx.toStringAsFixed(2)),
            'y': double.parse(action[0].dy.toStringAsFixed(2)),
            'time': action[1],
          });
        } else if (action[0] is DrawingMode) {
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
    // log(scrollZoomStamp.toString());
    if (isRecording) {
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
  }

  // ---------- FUNCTION: solve pad core
  void clearReplayPoint() {
    for (var point in _penPoints) {
      point.clear();
    }
    for (var point in _replayPoints) {
      point.clear();
    }
    for (var point in _highlighterPoints) {
      point.clear();
    }
  }

  void pauseReplay() {
    log('pause replay');
    setState(() {
      isReplaying = false;
    });
    pauseAudioPlayer();
    solveStopwatch.stop();
  }

  void resumeReplay() {
    log('resume replay');
    setState(() {
      isReplaying = true;
    });
    resumeAudioPlayer();
    solveStopwatch.start();
  }

  void _initReplay() {
    log('init replay');
    setState(() {
      isReplaying = true;
      isReplayEnd = false;
      clearReplayPoint();
    });
    _replay();
    playAudioPlayer();
  }

  Future<void> _replay() async {
    log('_replay()');
    solveStopwatch.start();
    _sliderTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      setState(() {
        replayProgress = solveStopwatch.elapsed.inMilliseconds.toDouble();
        if (replayProgress >= replayDuration.toDouble()) {
          replayProgress = replayDuration.toDouble();
          timer.cancel();
        }
      });
    });

    while (currentReplayIndex < _data['actions'].length) {
      await Future.delayed(const Duration(milliseconds: 0), () async {
        if (solveStopwatch.elapsed.inMilliseconds >=
            _data['actions'][currentReplayIndex]['time']) {
          await executeReplayAction(_data['actions'][currentReplayIndex]);
          currentReplayIndex++;
        }
      });
    }

    endReplay();
  }

  void endReplay() {
    setState(() {
      isReplaying = false;
      isReplayEnd = true;
    });
    stopAudioPlayer();
    _sliderTimer?.cancel();
    solveStopwatch.reset();
    currentReplayIndex = 0;
    log(' --------- end loop ----------');
  }

  Future<void> executeReplayAction(Map<String, dynamic> action) async {
    switch (action['type']) {
      case 'start-recording':
        var page = action['page'];
        _pageController.animateToPage(
          page,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _transformationController[page].value = Matrix4.identity()
          ..translate(action['scrollX'] / 2, action['scrollY'])
          ..scale(action['scale']);
        break;
      case 'change-page':
        _pageController.animateToPage(
          action['data'],
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        break;
      case 'stop-recording':
        break;
      case 'scroll-zoom':
        List<Map<String, dynamic>> scrollAction = action['data'];
        while (currentReplayScrollIndex < scrollAction.length) {
          await Future.delayed(const Duration(milliseconds: 0), () {
            if (solveStopwatch.elapsed.inMilliseconds >=
                scrollAction[currentReplayScrollIndex]['time']) {
              _transformationController[_currentPage].value = Matrix4.identity()
                ..translate(scrollAction[currentReplayScrollIndex]['x'],
                    scrollAction[currentReplayScrollIndex]['y'])
                ..scale(scrollAction[currentReplayScrollIndex]['scale']);
              currentReplayScrollIndex++;
            }
          });
        }
        currentReplayScrollIndex = 0;
        break;
      case 'drawing':
        List<Map<String, dynamic>> points = action['data']['points'];
        while (currentReplayPointIndex < points.length) {
          await Future.delayed(const Duration(milliseconds: 0), () {
            if (solveStopwatch.elapsed.inMilliseconds >=
                points[currentReplayPointIndex]['time']) {
              drawReplayPoint(
                  points[currentReplayPointIndex],
                  action['data']['tool'],
                  action['data']['color'],
                  action['data']['strokeWidth']);
              currentReplayPointIndex++;
            }
          });
        }
        currentReplayPointIndex = 0;
        drawReplayNull(action['data']['tool']);
        break;
      case 'erasing':
        for (var eraseAction in action['data']) {
          if (eraseAction['action'] == 'moves') {
            int movingIndex = 0;
            while (movingIndex < eraseAction['points'].length) {
              await Future.delayed(const Duration(milliseconds: 0), () {
                if (solveStopwatch.elapsed.inMilliseconds >=
                    eraseAction['points'][movingIndex]['time']) {
                  setState(() {
                    _eraserPoints[_currentPage] = Offset(
                        eraseAction['points'][movingIndex]['x'],
                        eraseAction['points'][movingIndex]['y']);
                  });
                  movingIndex++;
                }
              });
            }
          } // move
          else if (eraseAction['action'] == 'erase') {
            while (
                solveStopwatch.elapsed.inMilliseconds < eraseAction['time']) {
              await Future.delayed(const Duration(milliseconds: 0), () {});
            }
            List<SolvepadStroke?> pointStack = _penPoints[_currentPage];
            if (eraseAction['mode'] == "DrawingMode.pen") {
              pointStack = _penPoints[_currentPage];
            } else if (eraseAction['mode'] == "DrawingMode.highlighter") {
              pointStack = _highlighterPoints[_currentPage];
            }
            setState(() {
              pointStack.removeRange(eraseAction['prev'], eraseAction['next']);
            });
          } // erase
        }
        setState(() {
          _eraserPoints[_currentPage] = const Offset(-100, -100);
        });
        break;
    }
  }

  void drawReplayPoint(
      Map<String, dynamic> point, String tool, String color, double stroke) {
    if (tool == "DrawingMode.pen") {
      _penPoints[_currentPage].add(SolvepadStroke(
        Offset(point['x'], point['y']),
        Color(int.parse(color, radix: 16)),
        stroke,
      ));
      setState(() {});
    } else if (tool == "DrawingMode.highlighter") {
      _highlighterPoints[_currentPage].add(SolvepadStroke(
        Offset(point['x'], point['y']),
        Color(int.parse(color, radix: 16)),
        stroke,
      ));
      setState(() {});
    }
  }

  void drawReplayNull(String tool) {
    if (tool == "DrawingMode.pen") {
      _penPoints[_currentPage].add(null);
    } else if (tool == "DrawingMode.highlighter") {
      _highlighterPoints[_currentPage].add(null);
    }
  }

  Future<void> writeToFile(String fileName, dynamic data) async {
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    final file = File('$tempPath/$fileName');
    final json = jsonEncode(data);
    file.writeAsString(json);
  }

  // ---------- FUNCTION: recording and playback
  Future<void> openTheRecorder() async {
    if (!kIsWeb) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
    }
    await _mRecorder!.openRecorder();
    if (!await _mRecorder!.isEncoderSupported(_codec) && kIsWeb) {
      _codec = Codec.opusWebM;
      _mPath = 'tau_file.webm';
      if (!await _mRecorder!.isEncoderSupported(_codec) && kIsWeb) {
        _mRecorderIsInited = true;
        return;
      }
    }
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

    _mRecorderIsInited = true;
  }

  void record() {
    _mRecorder!
        .startRecorder(
      toFile: _mPath,
      codec: _codec,
      audioSource: AudioSource.microphone,
    )
        .then((value) {
      setState(() {});
    });
  }

  void stopRecorder() async {
    await _mRecorder!.stopRecorder().then((value) {
      setState(() {
        //var url = value;
        _mPlaybackReady = true;
      });
    });
  }

  void playAudioPlayer() {
    assert(_mPlayerIsInited &&
        _mPlaybackReady &&
        _mRecorder!.isStopped &&
        _mPlayer!.isStopped);
    _mPlayer!.startPlayer(fromURI: _mPath);
  }

  void stopAudioPlayer() {
    _mPlayer!.stopPlayer();
  }

  void pauseAudioPlayer() {
    _mPlayer!.pausePlayer();
  }

  void resumeAudioPlayer() {
    _mPlayer!.resumePlayer();
  }

  void getRecorderFn() {
    if (!_mRecorderIsInited || !_mPlayer!.isStopped) {
      log('return from 1st condition', name: "getRecorderFn");
      return;
    }
    if (_mRecorder!.isStopped) {
      record();
    } else {
      stopRecorder();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPopScope,
      child: isCourseLoaded
          ? Scaffold(
              backgroundColor: CustomColors.grayCFCFCF,
              body: !Responsive.isMobile(context)
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
          if (isRecordEnd) slider(),
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
                                  _selectedIndexLines = index;
                                  openLines = !openLines;
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
                              ));
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

          ///tools widget
          if (!selectedTools) toolsMobile(),
          if (selectedTools) toolsActiveMobile(),
        ],
      ),
    );
  }

  Widget slider() {
    return Positioned(
      left: 140,
      top: 160,
      child: SizedBox(
        width: 60,
        height: 490,
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 25),
            child: FlutterSlider(
              axis: Axis.vertical,
              values: [replayProgress],
              max: replayDuration.toDouble(),
              min: 0,
              handlerAnimation: const FlutterSliderHandlerAnimation(scale: 1.2),
              tooltip: FlutterSliderTooltip(
                alwaysShowTooltip: true,
                direction: FlutterSliderTooltipDirection.top,
                positionOffset:
                    FlutterSliderTooltipPositionOffset(top: -5, left: -40),
                boxStyle: FlutterSliderTooltipBox(
                    decoration:
                        BoxDecoration(color: Colors.white.withOpacity(0))),
                format: (value) {
                  return _formatReplayElapsedTime(
                      Duration(milliseconds: double.parse(value).round()));
                },
              ),
              trackBar: FlutterSliderTrackBar(
                activeTrackBarHeight: 5,
                inactiveTrackBar: BoxDecoration(
                  color: const Color(0xff20B153).withOpacity(0.3),
                ),
                activeTrackBar: const BoxDecoration(
                  color: Color(0xff20B153),
                ),
              ),
              onDragging: (handlerIndex, lowerValue, upperValue) {
                var seekPosition = Duration(milliseconds: lowerValue.round());
                if (lowerValue > replayProgress) {
                  solveStopwatch.jumpTo(seekPosition);
                  _mPlayer!.seekToPlayer(seekPosition);
                  setState(() {});
                }
              },
              // onDragCompleted: (handlerIndex, lowerValue, upperValue) {},
            ),
          ),
          Positioned(
            top: 0,
            left: 12,
            child: Text('00:00', style: CustomStyles.med12GreenPrimary),
          ),
          Positioned(
            bottom: 0,
            left: 12,
            child: Text(
                _formatReplayElapsedTime(
                    Duration(milliseconds: replayDuration)),
                style: CustomStyles.med12GreenPrimary),
          ),
        ]),
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
          mySolvepadSize = Size(solvepadWidth, solvepadHeight);
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
                  double originalTranslationX = translation.x;
                  double originalTranslationY = translation.y;
                  if (isRecording && _mode == DrawingMode.drag) {
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
                              if (!isRecording) return;
                              activePointerId = details.pointer;
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
                              if (!isRecording) return;
                              activePointerId = details.pointer;
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
                              if (!isRecording) return;
                              activePointerId = null;
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
                              if (!isRecording) return;
                              activePointerId = null;
                              currentStroke.clear();
                              switch (_mode) {
                                case DrawingMode.pen:
                                  addDrawing(currentStroke,
                                      currentStroke[0].timestamp);
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
                                  currentEraserStroke.clear();
                                  _highlighterPoints[_currentPage].add(null);
                                  break;
                                case DrawingMode.eraser:
                                  addErasing(currentEraserStroke);
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
                              painter: SolvepadDrawerMarketplace(
                                _penPoints[index],
                                _replayPoints[index],
                                _eraserPoints[index],
                                _laserPoints[index],
                                _highlighterPoints[index],
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
        ]);
      }),
    );
  }

  Widget recordCourseButton() {
    return Center(
      child: SizedBox(
        width: 70,
        height: 100,
        child: GestureDetector(
          onTap: () {
            if (!isRecording) {
              _initRecord();
            } // Before record
            else {
              _stopSolvePadRecord();
            }
            getRecorderFn();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 14.0),
            decoration: BoxDecoration(
                color: isRecording
                    ? CustomColors.gray363636
                    : CustomColors.redFF4201,
                shape: BoxShape.circle),
            child: isRecording
                ? const Icon(
                    Icons.stop,
                    size: 20,
                    color: CustomColors.white,
                  )
                : const Icon(
                    Icons.radio_button_checked_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
          ),
        ),
      ),
    );
  }

  Widget replayRecordButton() {
    return Center(
      child: SizedBox(
        width: 70,
        height: 100,
        child: GestureDetector(
          onTap: () {
            if (!isReplaying) {
              if (isReplayEnd) {
                _initReplay();
              } else {
                resumeReplay();
              }
            } // before replay
            else {
              pauseReplay();
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 14.0),
            decoration: BoxDecoration(
                color: isReplaying
                    ? CustomColors.gray363636
                    : CustomColors.redFF4201,
                shape: BoxShape.circle),
            child: isReplaying
                ? const Icon(
                    Icons.pause,
                    size: 20,
                    color: CustomColors.white,
                  )
                : const Icon(
                    Icons.play_arrow,
                    size: 20,
                    color: Colors.white,
                  ),
          ),
        ),
      ),
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
          S.w(8),
          IconButton(
            icon: const Icon(Icons.arrow_back, color: CustomColors.gray878787),
            onPressed: () => Navigator.pop(context),
          ),
          S.w(Responsive.isTablet(context) ? 5 : 12),
          Expanded(
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
                padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    S.w(8),
                    InkWell(
                      onTap: () => headerLayer1Mobile(),
                      child: Image.asset(
                        ImageAssets.iconInfoPage,
                        height: 24,
                        width: 24,
                      ),
                    ),
                    S.w(8),
                    Container(
                      width: 1,
                      height: 24,
                      color: CustomColors.grayCFCFCF,
                    ),
                    S.w(6),
                    Material(
                      child: InkWell(
                        onTap: () {
                          if (_pageController.hasClients &&
                              _pageController.page!.toInt() != 0) {
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
                    S.w(6),
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
                    S.w(6),
                    Material(
                      child: InkWell(
                        // splashColor: Colors.lightGreen,
                        onTap: () {
                          if (_pages.length > 1) {
                            if (_pageController.hasClients &&
                                _pageController.page!.toInt() !=
                                    _pages.length - 1) {
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
                    S.w(6),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      micEnable = !micEnable;
                    });
                  },
                  child: Image.asset(
                    micEnable ? ImageAssets.micEnable : ImageAssets.micDis,
                    height: 44,
                    width: 44,
                  ),
                ),
                S.w(defaultPadding),
                const DividerVer(),
                if (!isRecordEnd) recordCourseButton(),
                if (isRecordEnd) S.w(defaultPadding),
                RichText(
                  text: TextSpan(
                    text: _formattedElapsedTime,
                    style: CustomStyles.bold14RedF44336,
                  ),
                ),
                if (isRecordEnd) replayRecordButton(),
              ],
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 200,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRecordEnd
                          ? CustomColors.greenPrimary
                          : CustomColors.inactivePagingBtn,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0), // <-- Radius
                      ), // NEW
                    ),
                    onPressed: () async {
                      if (isRecordEnd) {
                        await Alert.showOverlay(
                          asyncFunction: () async {
                            var courseController =
                                context.read<CourseController>();
                            await writeToFile('solvepad.txt', _data);
                            List uploadUrl =
                                await firebaseService.uploadMarketSolvepad(
                                    '${widget.course.id!}_${widget.lesson.lessonId.toString()}');
                            String solvepadId = await firebaseService
                                .writeSolvepadData(uploadUrl[0], uploadUrl[1]);
                            widget.lesson.media = solvepadId;
                            await courseController.updateCourseDetails(
                                courseController.courseData);
                          },
                          context: context,
                          loadingWidget: Alert.getOverlayScreen(),
                        );
                        if (!mounted) return;
                        showSnackBar(context, 'อัพโหลดสำเร็จ');
                      }
                    },
                    child: Row(
                      children: [
                        Text('อัพโหลด solvepad',
                            style: CustomStyles.bold14White),
                        S.w(8),
                        Container(
                          width: 3,
                          height: 16,
                          color: CustomColors.whitePrimary,
                        ),
                        S.w(2),
                        const Icon(
                          Icons.arrow_forward,
                          color: CustomColors.whitePrimary,
                          size: 20.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          S.w(16.0),
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
                                    style:
                                        CustomStyles.bold16Black363636Overflow,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                                      borderRadius: BorderRadius.circular(100)),
                                ),
                                S.w(defaultPadding),
                              ],
                            ),
                          )
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
                Image.asset(
                  ImageAssets.allPages,
                  height: 24,
                  width: 24,
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
                    borderRadius:
                        BorderRadius.only(topRight: Radius.circular(90)),
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
            )));
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
                            // // crossAxisAlignment: CrossAxisAlignment.start,
                            // mainAxisAlignment:
                            //     MainAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedIndexColors = index;

                                    // Close popup
                                    openColors = !openColors;
                                  });
                                  log('Tap : index $index');
                                  log('Tap : _selectIndex $_selectedIndexColors');
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
                                      setState(() {
                                        _selectedIndexLines = index;

                                        // Close popup
                                        openLines = !openLines;
                                      });
                                    });
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
                                            } else if (index == 1) {
                                              _mode = DrawingMode.pen;
                                            } else if (index == 2) {
                                              _mode = DrawingMode.highlighter;
                                            } else if (index == 3) {
                                              _mode = DrawingMode.eraser;
                                            } else if (index == 4) {
                                              _mode = DrawingMode.laser;
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
                                          if (!isRecording) return;
                                          _selectedIndexTools = index;
                                        });
                                        if (currentScrollZoom.isNotEmpty) {
                                          addScrollZoom(currentScrollZoom,
                                              currentScrollZoom[0].timestamp);
                                          currentScrollZoom.clear();
                                        }
                                        if (index == 0) {
                                          _mode = DrawingMode.drag;
                                        } // drag
                                        else if (index == 1) {
                                          _mode = DrawingMode.pen;
                                        } // pen
                                        else if (index == 2) {
                                          _mode = DrawingMode.highlighter;
                                        } // high
                                        else if (index == 3) {
                                          _mode = DrawingMode.eraser;
                                        } // eraser
                                        else if (index == 4) {
                                          _mode = DrawingMode.laser;
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
                )),

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
                          ),
                        ),

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
}
