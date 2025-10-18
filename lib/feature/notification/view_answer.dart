import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' as touch_ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sizer/sizer.dart';
import 'package:solve_tutor/feature/calendar/controller/create_course_controller.dart';

import '../../../firebase/database.dart';
import '../calendar/constants/assets_manager.dart';
import '../calendar/constants/custom_colors.dart';
import '../calendar/constants/custom_styles.dart';
import '../calendar/model/course_model.dart';
import '../calendar/widgets/sizebox.dart';
import '../live_classroom/components/divider.dart';
import '../live_classroom/components/room_loading_screen.dart';
import '../live_classroom/solvepad/solve_watch.dart';
import '../live_classroom/solvepad/solvepad_drawer.dart';
import '../live_classroom/solvepad/solvepad_stroke_model.dart';
import '../live_classroom/utils/responsive.dart';

class ViewAnswer extends StatefulWidget {
  final CourseModel course;
  final Lessons lesson;
  final int courseTime;
  final String solvepadId;

  const ViewAnswer({
    super.key,
    required this.lesson,
    required this.course,
    required this.courseTime,
    required this.solvepadId,
  });

  @override
  State<ViewAnswer> createState() => _ViewAnswerState();
}

class _ViewAnswerState extends State<ViewAnswer> {
  // Screen and tools
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

  int focusQuestion = 0;
  int radioTest = 0;
  FirebaseService firebaseService = FirebaseService();

  // ---------- VARIABLE: Solve Pad data
  late List<String> _pages = [];
  final List<List<SolvepadStroke?>> _penPoints = [[]];
  final List<List<SolvepadStroke?>> _laserPoints = [[]];
  final List<List<SolvepadStroke?>> _highlighterPoints = [[]];
  final List<Offset> _eraserPoints = [const Offset(-100, -100)];
  final List<List<SolvepadStroke?>> _coursePenPoints = [[]];
  final List<List<SolvepadStroke?>> _courseHighlighterPoints = [[]];
  final List<Offset> _courseEraserPoints = [const Offset(-100, -100)];
  final List<List<SolvepadStroke?>> _answerPenPoints = [[]];
  final List<List<SolvepadStroke?>> _answerLaserPoints = [[]];
  final List<List<SolvepadStroke?>> _answerHighlighterPoints = [[]];
  final List<Offset> _answerEraserPoints = [const Offset(-100, -100)];
  final List<List<Offset?>> _replayPoints = [[]];
  DrawingMode _mode = DrawingMode.drag;
  final SolveStopwatch answerStopwatch = SolveStopwatch();
  final SolveStopwatch questionStopwatch = SolveStopwatch();

  // ---------- VARIABLE: Solve Size
  Size mySolvepadSize = const Size(1059.0, 547.0);
  Size questionSolvepadSize = const Size(1059.0, 547.0);
  Size tutorSolvepadSize = const Size(1059.0, 547.0);
  Size courseSolvepadSize = const Size(1059.0, 547.0);
  double sheetImageRatio = 0.708;
  double myImageWidth = 0;
  double myExtraSpaceX = 0;
  double questionImageWidth = 0;
  double questionExtraSpaceX = 0;
  double questionScaleImageX = 0;
  double questionScaleX = 0;
  double questionScaleY = 0;
  double courseImageWidth = 0;
  double courseExtraSpaceX = 0;
  double courseScaleImageX = 0;
  double courseScaleX = 0;
  double courseScaleY = 0;

  // ---------- VARIABLE: Solve Pad features
  bool _isPrevBtnActive = false;
  bool _isNextBtnActive = true;
  bool _isStylusActive = false;
  int? activePointerId;

  // ---------- VARIABLE: page control
  Timer? _laserTimer;
  Timer? _recordTimer;
  int _currentPage = 0;
  int _coursePage = 0;
  final PageController _pageController = PageController();
  final List<TransformationController> _transformationController = [];
  var courseController = CourseController();
  late String courseName;
  bool isAnswerLoaded = false;
  bool isCourseLoaded = false;
  bool isDocLoaded = false;
  bool isAnswerPlaying = false;
  bool isAnswerPausing = false;
  bool isAnswerReplaying = false;
  bool isAnswerSent = false;
  bool isReplayLoading = false;
  bool isViewOnly = false;

  // String _mPath = 'tau_file.mp4';
  late String questionVoicePath;
  late String answerVoicePath;
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  bool _mPlayerIsInited = false;
  bool _mPlaybackReady = false;

  // ---------- VARIABLE: data collection
  late Map<String, dynamic> _questionData;
  late Map<String, dynamic> _courseData;
  String jsonData = '';
  late List<Map<String, dynamic>> _actions;
  int currentReplayIndex = 0;
  int currentReplayPointIndex = 0;
  int currentReplayScrollIndex = 0;
  double currentScale = 2.0;
  double currentScrollX = 0;
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
      isDocLoaded = true;
      initCourseData(courseController.courseData!.lessons![(widget.lesson.lessonId!)-1].media!);
      initAnswerData();
    });
  }

  void initCourseData(String solvepadId) async {
    var downloadData = await firebaseService.getMarketCourseSolvepadData(solvepadId);
    _courseData = downloadData[0];
    setState(() {
      courseSolvepadSize = Size(_courseData['solvepadWidth'], _courseData['solvepadHeight']);
    });
    initCourseSolvepadScaling();
    isCourseLoaded = true;
  }

  void initAnswerData() async {
    var downloadData = await firebaseService.getMarketCourseSolvepadData(widget.solvepadId);
    String voicePath = await firebaseService.getMarketCourseAudioFile(downloadData[1]);
    _questionData = downloadData[0];
    setState(() {
      questionVoicePath = voicePath;
      _mPlaybackReady = true;
      questionSolvepadSize = Size(_questionData['solvepadWidth'], _questionData['solvepadHeight']);
      replayDuration = _questionData['metadata']['duration'];
    });
    initQuestionSolvepadScaling();
    isAnswerLoaded = true;
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

  void initCourseSolvepadScaling() {
    courseImageWidth = courseSolvepadSize.height * sheetImageRatio;
    courseExtraSpaceX = (courseSolvepadSize.width - courseImageWidth) / 2;
    myImageWidth = mySolvepadSize.height * sheetImageRatio;
    myExtraSpaceX = (mySolvepadSize.width - myImageWidth) / 2;
    courseScaleImageX = myImageWidth / courseImageWidth;
    courseScaleX = mySolvepadSize.width / courseSolvepadSize.width;
    courseScaleY = mySolvepadSize.height / courseSolvepadSize.height;
    populateCourseNote(_courseData);
  }

  void initQuestionSolvepadScaling() {
    questionImageWidth = questionSolvepadSize.height * sheetImageRatio;
    questionExtraSpaceX = (questionSolvepadSize.width - questionImageWidth) / 2;
    myImageWidth = mySolvepadSize.height * sheetImageRatio;
    myExtraSpaceX = (mySolvepadSize.width - myImageWidth) / 2;
    questionScaleImageX = myImageWidth / questionImageWidth;
    questionScaleX = mySolvepadSize.width / questionSolvepadSize.width;
    questionScaleY = mySolvepadSize.height / questionSolvepadSize.height;
  }

  Offset questionScaleOffset(Offset offset) {
    return Offset(
        (offset.dx - questionExtraSpaceX) * questionScaleImageX + myExtraSpaceX,
        offset.dy * questionScaleY);
  }
  double questionScaleScrollX(double scrollX) => scrollX * questionScaleX;
  double questionScaleScrollY(double scrollY) => scrollY * questionScaleY;

  Offset courseScaleOffset(Offset offset) {
    return Offset(
        (offset.dx - courseExtraSpaceX) * courseScaleImageX + myExtraSpaceX,
        offset.dy * courseScaleY);
  }
  double courseScaleScrollX(double scrollX) => scrollX * courseScaleX;
  double courseScaleScrollY(double scrollY) => scrollY * courseScaleY;

  void populateCourseNote(Map<String, dynamic> jsonData) {
    int questionIndex = 0;
    while (questionIndex < jsonData['actions'].length) {
      if (_courseData['actions'][questionIndex]['time'] <= widget.courseTime) {
        executeCourseAction(jsonData['actions'][questionIndex]);
        questionIndex++;
      } else {
        break;
      }
    }
  }

  Future<void> executeCourseAction(Map<String, dynamic> action) async {
    int currentCoursePointIndex = 0;
    switch (action['type']) {
      case 'start-recording':
        _coursePage = action['page'];
        break;
      case 'change-page':
        _coursePage = action['data'];
        break;
      case 'stop-recording':
        break;
      case 'scroll-zoom':
        break;
      case 'drawing':
        List<dynamic> points = action['data']['points'];
        while (currentCoursePointIndex < points.length) {
          drawCoursePoint(
              points[currentCoursePointIndex],
              action['data']['tool'],
              action['data']['color'],
              action['data']['strokeWidth']);
          currentCoursePointIndex++;
        }
        currentCoursePointIndex = 0;
        drawCourseNull(action['data']['tool']);
        break;
      case 'erasing':
        for (var eraseAction in action['data']) {
          if (eraseAction['action'] == 'moves') {
            int movingIndex = 0;
            while (movingIndex < eraseAction['points'].length) {
              setState(() {
                _courseEraserPoints[_currentPage] = courseScaleOffset(Offset(
                    eraseAction['points'][movingIndex]['x'],
                    eraseAction['points'][movingIndex]['y']));
              });
              movingIndex++;
            }
          } // move
          else if (eraseAction['action'] == 'erase') {
            List<SolvepadStroke?> pointStack =
            _coursePenPoints[_coursePage];
            if (eraseAction['mode'] == "pen") {
              pointStack = _coursePenPoints[_coursePage];
            } else if (eraseAction['mode'] == "high") {
              pointStack = _courseHighlighterPoints[_coursePage];
            }
            setState(() {
              var start = eraseAction['prev'].clamp(0, pointStack.length);
              var end = eraseAction['next'].clamp(start, pointStack.length);
              pointStack.removeRange(start, end);
            });
          } // erase
        }
        setState(() {
          _courseEraserPoints[_coursePage] = const Offset(-100, -100);
        });
        break;
    }
  }

  void drawCoursePoint(
      Map<String, dynamic> point, String tool, String color, double stroke) {
    if (tool == "DrawingMode.pen") {
      _coursePenPoints[_coursePage].add(SolvepadStroke(
        courseScaleOffset(Offset(point['x'], point['y'])),
        Color(int.parse(color, radix: 16)),
        stroke,
      ));
      setState(() {});
    } // pen
    else if (tool == "DrawingMode.highlighter") {
      _courseHighlighterPoints[_coursePage].add(SolvepadStroke(
        courseScaleOffset(Offset(point['x'], point['y'])),
        Color(int.parse(color, radix: 16)),
        stroke,
      ));
      setState(() {});
    } // high
  }

  void drawCourseNull(String tool) {
    if (tool == "DrawingMode.pen") {
      _coursePenPoints[_coursePage].add(null);
    } else if (tool == "DrawingMode.highlighter") {
      _courseHighlighterPoints[_coursePage].add(null);
    }
  }

  void drawAnswerPoint(
      Map<String, dynamic> point, String tool, String color, double stroke) {
    final buckets = _pickStrokeBucket(tool, true);
    buckets[_currentPage].add(SolvepadStroke(
      questionScaleOffset(Offset(point['x'], point['y'])),
      Color(int.parse(color, radix: 16)),
      stroke,
    ));
    setState(() {});
  }

  void drawAnswerNull(String tool) {
    final buckets = _pickStrokeBucket(tool, true);
    buckets[_currentPage].add(null);
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
    _pageController.dispose();
    _recordTimer?.cancel();
    _sliderTimer?.cancel();
    _laserTimer?.cancel();
    super.dispose();
  }

  Future<void> _setPortraitOnPop(bool didPop, Object? result) async {
    if (!didPop) return; // pop didn’t happen, nothing to do
    // await SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.portraitDown,
    // ]);
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
      _answerPenPoints.add([]);
      _answerLaserPoints.add([]);
      _answerHighlighterPoints.add([]);
      _answerEraserPoints.add(const Offset(-100, -100));
      _coursePenPoints.add([]);
      _courseHighlighterPoints.add([]);
      _courseEraserPoints.add(const Offset(-100, -100));
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
    List<SolvepadStroke?> pointStack;
    if (mode == DrawingMode.pen) {
      pointStack = _penPoints[_currentPage];
      removePointStack(pointStack, index, removeMode: 'pen');
    } // pen
    else if (mode == DrawingMode.highlighter) {
      pointStack = _highlighterPoints[_currentPage];
      removePointStack(pointStack, index, removeMode: 'high');
    } // high
  }

  void removePointStack(List<SolvepadStroke?> pointStack, int index, {String? removeMode}) {
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
    // log(scrollZoomStamp.toString());
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

  void clearQuestionPoint() {
    for (var point in _answerPenPoints) {
      point.clear();
    }
    for (var point in _answerHighlighterPoints) {
      point.clear();
    }
  }

  void clearZoomPosition() {
    for (int i = 0; i < _transformationController.length; i++) {
      _transformationController[i].value = Matrix4.identity()
        ..scale(2.0)
        ..translate(-1 * mySolvepadSize.width / 4, 0);
    }
  }

  void pauseReplay() {
    log('pause replay');
    pauseAudioPlayer();
    answerStopwatch.stop();
  }

  void resumeReplay() {
    log('resume replay');
    resumeAudioPlayer();
    answerStopwatch.start();
  }

  void pauseAnswer() {
    log('pause replay');
    pauseAudioPlayer();
    questionStopwatch.stop();
  }

  void resumeAnswer() {
    log('resume replay');
    resumeAudioPlayer();
    questionStopwatch.start();
  }

  void _initAnswer() {
    setState(() {
      clearQuestionPoint();
      clearZoomPosition();
    });
    _playAnswer();
    playAnswerAudioPlayer();
  }

  void endAnswer() {
    setState(() {
      isAnswerPlaying = false;
    });
    stopAudioPlayer();
    _sliderTimer?.cancel();
    questionStopwatch.reset();
    currentReplayIndex = 0;
    log(' --------- end question ----------');
  }

  Future<void> _playAnswer() async {
    questionStopwatch.start();
    _sliderTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      setState(() {
        replayProgress = questionStopwatch.elapsed.inMilliseconds.toDouble();
        if (replayProgress >= replayDuration.toDouble()) {
          replayProgress = replayDuration.toDouble();
          timer.cancel();
        }
      });
    });
    while (currentReplayIndex < _questionData['actions'].length) {
      await Future.delayed(const Duration(milliseconds: 0), () async {
        if (questionStopwatch.elapsed.inMilliseconds >=
            _questionData['actions'][currentReplayIndex]['time']) {
          await executePlayAnswerAction(
              _questionData['actions'][currentReplayIndex]);
          currentReplayIndex++;
        }
      });
    }
    endAnswer();
  }

  Future<void> executePlayAnswerAction(Map<String, dynamic> action) async {
    switch (action['type']) {
      case 'start-recording':
        var page = action['page'];
        await _pageController.animateToPage(
          page,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        await WidgetsBinding.instance.endOfFrame;
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
        List<dynamic> scrollAction = action['data'];
        while (currentReplayScrollIndex < scrollAction.length) {
          await Future.delayed(const Duration(milliseconds: 0), () {
            if (questionStopwatch.elapsed.inMilliseconds >=
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
        List<dynamic> points = action['data']['points'];
        while (currentReplayPointIndex < points.length) {
          await Future.delayed(const Duration(milliseconds: 0), () {
            if (questionStopwatch.elapsed.inMilliseconds >=
                points[currentReplayPointIndex]['time']) {
              drawAnswerPoint(
                points[currentReplayPointIndex],
                action['data']['tool'],
                action['data']['color'],
                action['data']['strokeWidth'],
              );
              currentReplayPointIndex++;
            }
          });
        }
        currentReplayPointIndex = 0;
        drawAnswerNull(action['data']['tool']);
        break;
      case 'erasing':
        for (var eraseAction in action['data']) {
          if (eraseAction['action'] == 'moves') {
            int movingIndex = 0;
            while (movingIndex < eraseAction['points'].length) {
              await Future.delayed(const Duration(milliseconds: 0), () {
                if (questionStopwatch.elapsed.inMilliseconds >=
                    eraseAction['points'][movingIndex]['time']) {
                  setState(() {
                    _answerEraserPoints[_currentPage] = Offset(
                        eraseAction['points'][movingIndex]['x'],
                        eraseAction['points'][movingIndex]['y']);
                  });
                  movingIndex++;
                }
              });
            }
          } // move
          else if (eraseAction['action'] == 'erase') {
            while (questionStopwatch.elapsed.inMilliseconds <
                eraseAction['time']) {
              await Future.delayed(const Duration(milliseconds: 0), () {});
            }
            if (eraseAction['mode'] == "pen") {
              setState(() {
                _answerPenPoints[_currentPage]
                    .removeRange(eraseAction['prev'], eraseAction['next']);
              });
            } // pen
            else if (eraseAction['mode'] == "high") {
              setState(() {
                _answerHighlighterPoints[_currentPage]
                    .removeRange(eraseAction['prev'], eraseAction['next']);
              });
            }
          } // erase
        }
        setState(() {
          _answerEraserPoints[_currentPage] = const Offset(-100, -100);
        });
        break;
    }
  }

  List<List<SolvepadStroke?>> _pickStrokeBucket(String tool, bool isQuestion) {
    switch (tool) {
      case 'DrawingMode.pen':
        return isQuestion ? _answerPenPoints : _penPoints;
      case 'DrawingMode.highlighter':
        return isQuestion ? _answerHighlighterPoints : _highlighterPoints;
      default:
        return isQuestion ? _answerPenPoints : _penPoints;
    }
  }

  void drawReplayPoint(
      Map<String, dynamic> point, String tool, String color, double stroke) {
    final buckets = _pickStrokeBucket(tool, false);
    setState(() {
      buckets[_currentPage].add(SolvepadStroke(
        Offset(point['x'], point['y']),
        Color(int.parse(color, radix: 16)),
        stroke,
      ));
    });
  }

  void drawReplayNull(String tool) {
    final buckets = _pickStrokeBucket(tool, false);
    buckets[_currentPage].add(null);
  }

  Future<void> writeToFile(String fileName, dynamic data) async {
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    final file = File('$tempPath/$fileName');
    final json = jsonEncode(data);
    file.writeAsString(json);
  }

  // ---------- FUNCTION: recording and playback
  void playAudioPlayer() {
    assert(_mPlayerIsInited &&
        _mPlaybackReady);
    _mPlayer!.startPlayer(fromURI: answerVoicePath);
  }

  void playAnswerAudioPlayer() {
    assert(_mPlayerIsInited &&
        _mPlaybackReady);
    _mPlayer!.startPlayer(fromURI: questionVoicePath);
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: _setPortraitOnPop,
      child: isDocLoaded
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
          // if (isRecordEnd) slider(),
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
                  answerStopwatch.jumpTo(seekPosition);
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
              log('my solvepad size: $mySolvepadSize');
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
                      if (_mode == DrawingMode.drag) {
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
                                  if (details.kind ==
                                      touch_ui.PointerDeviceKind.stylus) {
                                    _isStylusActive = true;
                                  }
                                  if (_isStylusActive &&
                                      details.kind ==
                                          touch_ui.PointerDeviceKind.touch) {
                                    return;
                                  }
                                  switch (_mode) {
                                    case DrawingMode.pen:
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
                                      _highlighterPoints[_currentPage].add(
                                        SolvepadStroke(
                                            details.localPosition,
                                            _strokeColors[_selectedIndexColors],
                                            _strokeWidths[_selectedIndexLines]),
                                      );
                                      break;
                                    case DrawingMode.eraser:
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
                                  if (details.kind ==
                                      touch_ui.PointerDeviceKind.stylus) {
                                    _isStylusActive = true;
                                  }
                                  if (_isStylusActive &&
                                      details.kind ==
                                          touch_ui.PointerDeviceKind.touch) {
                                    return;
                                  }
                                  switch (_mode) {
                                    case DrawingMode.pen:
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
                                      details.kind ==
                                          touch_ui.PointerDeviceKind.touch) {
                                    return;
                                  }
                                  switch (_mode) {
                                    case DrawingMode.pen:
                                      _penPoints[_currentPage].add(null);
                                      break;
                                    case DrawingMode.laser:
                                      _laserPoints[_currentPage].add(null);
                                      _laserTimer = Timer(
                                          const Duration(milliseconds: 1500),
                                          _stopLaserDrawing);
                                      break;
                                    case DrawingMode.highlighter:
                                      _highlighterPoints[_currentPage].add(null);
                                      break;
                                    case DrawingMode.eraser:
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
                                      details.kind ==
                                          touch_ui.PointerDeviceKind.touch) {
                                    return;
                                  }
                                  switch (_mode) {
                                    case DrawingMode.pen:
                                      _penPoints[_currentPage].add(null);
                                      break;
                                    case DrawingMode.laser:
                                      _laserPoints[_currentPage].add(null);
                                      _laserTimer = Timer(
                                          const Duration(milliseconds: 1500),
                                          _stopLaserDrawing);
                                      break;
                                    case DrawingMode.highlighter:
                                      _highlighterPoints[_currentPage].add(null);
                                      break;
                                    case DrawingMode.eraser:
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
                                  painter: SolvepadDrawerViewQuestion(
                                    _penPoints[index],
                                    _replayPoints[index],
                                    _eraserPoints[index],
                                    _laserPoints[index],
                                    _highlighterPoints[index],
                                    _answerPenPoints[index],
                                    _answerLaserPoints[index],
                                    _answerHighlighterPoints[index],
                                    _answerEraserPoints[index],
                                    _coursePenPoints[index],
                                    _courseHighlighterPoints[index],
                                    _courseEraserPoints[index],
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

  Widget playAnswerButton() {
    return Center(
      child: SizedBox(
        width: 50,
        height: 100,
        child: GestureDetector(
          onTap: () {
            setPlayState();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            decoration: BoxDecoration(
                color: isAnswerPlaying
                    ? CustomColors.gray363636
                    : CustomColors.redFF4201,
                shape: BoxShape.circle),
            child: !isAnswerLoaded
                ? Image.asset(
              ImageAssets.loading,
              height: 44,
              width: 44,
            )
                : isAnswerPlaying
                ? isAnswerPausing
                ? const Icon(
              Icons.play_arrow,
              size: 20,
              color: CustomColors.white,
            )
                : const Icon(
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

  void setPlayState() {
    if (!isAnswerLoaded) return;
    if (isAnswerPlaying) {
      if (isAnswerPausing) {
        setState(() {
          isAnswerPausing = false;
        });
        resumeAnswer();
      } else {
        setState(() {
          isAnswerPausing = true;
        });
        pauseAnswer();
      }
    } // before replay
    else {
      setState(() {
        isAnswerPlaying = true;
      });
      _initAnswer();
    }
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
            child: Row(
              children: [
                Align(
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
                    padding:
                    const EdgeInsets.symmetric(horizontal: 1, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        S.w(8),
                        InkWell(
                          // onTap: () => headerLayer1Mobile(),
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
                S.w(8),
                statusTouchModeIcon(),
              ],
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text('answer name',
                    style: CustomStyles.bold14RedF44336,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              playAnswerButton(),
            ],
          )),
          S.w(8.0),
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
              height: selectedTools ? 200 : 440,
              width: 100,
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
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
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
                                        ? _listTools[index]
                                    ['image_active']
                                        : _listTools[index]['image_dis'],
                                    width: 10.w,
                                  ),
                                ),
                              ],
                            );
                          }),
                    ),
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
}
