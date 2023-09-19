import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:speech_balloon/speech_balloon.dart';

import '../../calendar/constants/assets_manager.dart';
import '../../calendar/constants/custom_colors.dart';
import '../../calendar/constants/custom_styles.dart';
import '../../calendar/widgets/sizebox.dart';
import '../components/divider.dart';
import '../quiz/quiz_model.dart';
import '../solvepad/solve_watch.dart';
import '../solvepad/solvepad_drawer.dart';
import '../solvepad/solvepad_stroke_model.dart';
import '../utils/responsive.dart';

class ReviewLesson extends StatefulWidget {
  final String courseId, courseName, file, tutorId, userId, docId;
  const ReviewLesson({
    Key? key,
    required this.courseId,
    required this.courseName,
    required this.file,
    required this.tutorId,
    required this.userId,
    required this.docId,
  }) : super(key: key);

  @override
  State<ReviewLesson> createState() => _ReviewLessonState();
}

class _ReviewLessonState extends State<ReviewLesson>
    with SingleTickerProviderStateMixin {
  bool micEnable = false;
  bool displayEnable = false;
  bool selected = false;
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
  bool _switchValue = true;
  bool fullScreen = false;
  bool openShowDisplay = false;
  bool showSpeechBalloon = true;
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
  final List _listToolsMobile = [
    {
      "image_active": ImageAssets.highlightActive,
      "image_dis": ImageAssets.highlightDis,
    },
    {
      "image_active": ImageAssets.rubberActive,
      "image_dis": ImageAssets.rubberDis,
    }
  ];
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
  final List _listToolsDisable = [
    {"image": 'assets/images/hand-tran.png'},
    {"image": 'assets/images/pencil-tran.png'},
    {"image": 'assets/images/highlight-tran.png'},
    {"image": 'assets/images/rubber-tran.png'},
    {"image": 'assets/images/laserPen-tran.png'},
  ];
  final List _strokeColors = [
    Colors.red,
    Colors.black,
    Colors.green,
    Colors.yellow,
  ];
  final List _strokeWidths = [1.0, 2.0, 5.0];
  List<SelectQuizModel> quizList = [
    SelectQuizModel("ชุดที่#1 สมการเชิงเส้นตัวแปรเดียว", "1 ข้อ", false),
    SelectQuizModel("ชุดที่#2 สมการเชิงเส้น 2 ตัวแปร", "10 ข้อ", false),
    SelectQuizModel("ชุดที่#3  สมการจำนวนเชิงซ้อน", "5 ข้อ", false),
    SelectQuizModel("ชุดที่#4 สมการเชิงเส้นตัวแปรเดียว", "5 ข้อ", false),
    SelectQuizModel("ชุดที่#5 สมการเชิงเส้นตัวแปรเดียว", "5 ข้อ", false),
  ];
  int _tutorColorIndex = 0;
  int _tutorStrokeWidthIndex = 0;

  // ---------- VARIABLE: Solve Pad data
  late List<String> _pages = [];
  final List<List<SolvepadStroke?>> _penPoints = [[]];
  final List<List<SolvepadStroke?>> _laserPoints = [[]];
  final List<List<SolvepadStroke?>> _highlighterPoints = [[]];
  final List<List<SolvepadStroke?>> _tutorPenPoints = [[]];
  final List<List<SolvepadStroke?>> _tutorLaserPoints = [[]];
  final List<List<SolvepadStroke?>> _tutorHighlighterPoints = [[]];
  final List<Offset> _eraserPoints = [const Offset(-100, -100)];
  final List<Offset> _tutorEraserPoints = [const Offset(-100, -100)];
  final List<List<Offset?>> _replayPoints = [[]];
  DrawingMode _mode = DrawingMode.drag;
  DrawingMode _tutorMode = DrawingMode.drag;
  String _tutorCurrentScrollZoom = '';
  final SolveStopwatch stopwatch = SolveStopwatch();
  Size studentSolvepadSize = const Size(1059.0, 547.0);
  Size? mySolvepadSize;
  double sheetImageRatio = 0.7373;
  double studentImageWidth = 0;
  double studentExtraSpaceX = 0;
  double myImageWidth = 0;
  double myExtraSpaceX = 0;
  double scaleImageX = 0;
  double scaleX = 0;
  double scaleY = 0;

  // ---------- VARIABLE: Solve Pad features
  bool _isReplaying = false;
  // bool _isStarted = true;
  bool _isPrevBtnActive = false;
  bool _isNextBtnActive = true;
  int? activePointerId;
  bool _isPageReady = false;
  bool _isSolvepadDataReady = false;

  // ---------- VARIABLE: page control
  String _formattedElapsedTime = ' 00 : 00 : 00 ';
  Timer? _laserTimer;
  Timer? _tutorLaserTimer;
  Timer? _replayTimer;
  int _currentPage = 0;
  int _tutorCurrentPage = 0;
  final PageController _pageController = PageController();
  final List<TransformationController> _transformationController = [];
  late Map<String, Function(String)> handlers;
  List<dynamic> downloadedSolvepad = [];
  bool tabFollowing = false;
  bool tabFreestyle = true;
  bool _isPause = true;
  late AnimationController progressController;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    initPagesData();
    initPagingBtn();
    initDownloadSolvepad();
  }

  Future<void> initPagesData() async {
    print('init data');
    print(widget.file);
    print(widget.docId);
    if (widget.docId == '') return;
    var sheet = await getDocFiles(widget.tutorId, widget.docId);
    print(sheet.length);
    setState(() {
      _pages = sheet;
      _isPageReady = true;
      startInstantReplay();
    });
    for (int i = 1; i < _pages.length; i++) {
      _addPage();
    }
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

  Future<void> initDownloadSolvepad() async {
    try {
      String url = widget.file;
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          downloadedSolvepad = jsonDecode(response.body);
          _isSolvepadDataReady = true;
        });
        print('load solvepad complete');
        startInstantReplay();
      } else {
        print('Failed to download file');
      }
    } catch (e) {
      print('Get file URL error: $e');
    }
  }

  void startInstantReplay() {
    if (_isPageReady && _isSolvepadDataReady) {
      instantReplay();
    }
  }

  void initSolvepadScaling(double solvepadWidth, double solvepadHeight) {
    studentImageWidth = studentSolvepadSize.height * sheetImageRatio;
    studentExtraSpaceX = (studentSolvepadSize.width - studentImageWidth) / 2;
    mySolvepadSize = Size(solvepadWidth, solvepadHeight);
    myImageWidth = mySolvepadSize!.height * sheetImageRatio;
    myExtraSpaceX = (mySolvepadSize!.width - myImageWidth) / 2;
    scaleImageX = myImageWidth / studentImageWidth;
    scaleX = mySolvepadSize!.width / studentSolvepadSize.width;
    scaleY = mySolvepadSize!.height / studentSolvepadSize.height;
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

    double myWidth = mySolvepadSize!.width;
    double myHeight = mySolvepadSize!.height;
    double myImageWidth = myHeight * sheetImageRatio;
    double myExtraSpaceX = (myWidth - myImageWidth) / 2;

    double scaleImageX = myImageWidth / studentImageWidth;
    double scaleY = myHeight / studentHeight;

    return Offset(
        (offset.dx - studentExtraSpaceX) * scaleImageX + myExtraSpaceX,
        offset.dy * scaleY);
  }

  double scaleScrollX(double scrollX) => scrollX * scaleX;
  double scaleScrollY(double scrollY) => scrollY * scaleY;

  @override
  dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    _replayTimer?.cancel();
    super.dispose();
  }

  Future<List<String>> getDocFiles(String userId, String docId) async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('medias')
          .doc(userId)
          .collection('docs_list')
          .doc(docId)
          .get();
      Map<String, dynamic>? dataMap =
          documentSnapshot.data() as Map<String, dynamic>?;
      List<dynamic> docFiles = dataMap?['doc_files'] ?? [];
      return docFiles.cast<String>(); // Casting to List<String>
    } catch (e) {
      print('An error occurred while fetching doc_files: $e');
      return [];
    }
  }

  void replayLoopLive() async {
    print('start replay loop');
    _replayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _formattedElapsedTime = _formatElapsedTime(stopwatch.elapsed);
        });
      } else {
        timer.cancel();
      }
    });
    for (int i = 0; i < downloadedSolvepad.length; i++) {
      if (downloadedSolvepad[i]['uid'] != widget.tutorId) {
        continue;
      }
      int actionTime = downloadedSolvepad[i]['time'];
      String actionData = downloadedSolvepad[i]['data'];
      while (stopwatch.elapsed.inMilliseconds < actionTime) {
        await Future.delayed(Duration(milliseconds: 0), () {});
      }
      if (actionData.startsWith('Offset')) {
        var offset = convertToOffset(actionData);
        Color strokeColor = _strokeColors[_tutorColorIndex];
        double strokeWidth = _strokeWidths[_tutorStrokeWidthIndex];
        switch (_tutorMode) {
          case DrawingMode.drag:
            break;
          case DrawingMode.pen:
            setState(() {
              _tutorPenPoints[_tutorCurrentPage] =
                  List.from(_tutorPenPoints[_tutorCurrentPage])
                    ..add(SolvepadStroke(offset, strokeColor, strokeWidth));
            });
            break;
          case DrawingMode.laser:
            setState(() {
              _tutorLaserPoints[_tutorCurrentPage] =
                  List.from(_tutorLaserPoints[_tutorCurrentPage])
                    ..add(SolvepadStroke(offset, strokeColor, strokeWidth));
              _tutorLaserDrawing();
            });
            break;
          case DrawingMode.highlighter:
            setState(() {
              _tutorHighlighterPoints[_tutorCurrentPage] =
                  List.from(_tutorHighlighterPoints[_tutorCurrentPage])
                    ..add(SolvepadStroke(offset, strokeColor, strokeWidth));
            });
            _tutorHighlighterPoints[_tutorCurrentPage]
                .add(SolvepadStroke(offset, strokeColor, strokeWidth));
            break;
          case DrawingMode.eraser:
            setState(() {
              _tutorEraserPoints[_tutorCurrentPage] = offset;
            });
            break;
          default:
            break;
        }
      } // Offset
      else if (actionData.startsWith('null')) {
        switch (_tutorMode) {
          case DrawingMode.drag:
            break;
          case DrawingMode.pen:
            _tutorPenPoints[_tutorCurrentPage].add(null);
            break;
          case DrawingMode.laser:
            _tutorLaserPoints[_tutorCurrentPage].add(null);
            _tutorLaserTimer = Timer(
                const Duration(milliseconds: 1500), _tutorStopLaserDrawing);
            break;
          case DrawingMode.highlighter:
            _tutorHighlighterPoints[_tutorCurrentPage].add(null);
            break;
          case DrawingMode.eraser:
            _tutorEraserPoints[_tutorCurrentPage] = const Offset(-100, -100);
            break;
          default:
            break;
        }
      } // Null
      else if (actionData.startsWith('DrawingMode')) {
        String modeString = actionData.replaceAll('DrawingMode.', '');
        DrawingMode drawingMode = DrawingMode.values.firstWhere(
            (e) => e.toString() == 'DrawingMode.$modeString',
            orElse: () => DrawingMode.drag);
        setState(() {
          _tutorMode = drawingMode;
        });
      } // Mode
      else if (actionData.startsWith('Erase')) {
        var parts = actionData.split('.');
        var index = int.parse(parts.last);
        if (actionData.startsWith('Erase.pen')) {
          removePointStack(_tutorPenPoints[_tutorCurrentPage], index);
        } else if (actionData.startsWith('Erase.high')) {
          removePointStack(_tutorHighlighterPoints[_tutorCurrentPage], index);
        }
      } // Erase
      else if (actionData.startsWith('StrokeColor')) {
        var parts = actionData.split('.');
        var index = int.parse(parts.last);
        setState(() {
          _tutorColorIndex = index;
        });
      } // Color
      else if (actionData.startsWith('StrokeWidth')) {
        var parts = actionData.split('.');
        var index = int.parse(parts.last);
        setState(() {
          _tutorStrokeWidthIndex = index;
        });
      } // Width
      else if (actionData.startsWith('ScrollZoom')) {
        var parts = actionData.split(':');
        var scrollX = double.parse(parts[1]);
        var scrollY = double.parse(parts[2]);
        var zoom = double.parse(parts.last);
        _tutorCurrentScrollZoom = '${parts[1]}:${parts[2]}:${parts[3]}';
        if (tabFreestyle) continue;
        _transformationController[_tutorCurrentPage].value = Matrix4.identity()
          ..translate(scaleScrollX(scrollX), scaleScrollY(scrollY))
          ..scale(zoom);
      } // ScrollZoom
      else if (actionData.startsWith('ChangePage')) {
        var parts = actionData.split(':');
        var pageAction = parts.last;
        if (pageAction == 'prev') {
          _tutorCurrentPage--;
          if (tabFreestyle) continue;
          _pageController.animateToPage(
            _pageController.page!.toInt() - 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else if (pageAction == 'next') {
          _tutorCurrentPage++;
          if (tabFreestyle) continue;
          _pageController.animateToPage(
            _pageController.page!.toInt() + 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      } // Paging
    }
    print('exit replay loop');
    setState(() {
      _isPause = !_isPause;
      _isReplaying = false;
    });
  }

  void instantReplay() async {
    for (int i = 0; i < downloadedSolvepad.length; i++) {
      if (downloadedSolvepad[i]['uid'] != widget.tutorId &&
          downloadedSolvepad[i]['uid'] != widget.userId) {
        continue;
      }
      String actionData = downloadedSolvepad[i]['data'];
      if (actionData.startsWith('Offset')) {
        var offset = convertToOffset(actionData);
        Color strokeColor = _strokeColors[_tutorColorIndex];
        double strokeWidth = _strokeWidths[_tutorStrokeWidthIndex];
        switch (_tutorMode) {
          case DrawingMode.drag:
            break;
          case DrawingMode.pen:
            setState(() {
              _tutorPenPoints[_tutorCurrentPage] =
                  List.from(_tutorPenPoints[_tutorCurrentPage])
                    ..add(SolvepadStroke(offset, strokeColor, strokeWidth));
            });
            break;
          case DrawingMode.highlighter:
            setState(() {
              _tutorHighlighterPoints[_tutorCurrentPage] =
                  List.from(_tutorHighlighterPoints[_tutorCurrentPage])
                    ..add(SolvepadStroke(offset, strokeColor, strokeWidth));
            });
            _tutorHighlighterPoints[_tutorCurrentPage]
                .add(SolvepadStroke(offset, strokeColor, strokeWidth));
            break;
          case DrawingMode.eraser:
            setState(() {
              _tutorEraserPoints[_tutorCurrentPage] = offset;
            });
            break;
          default:
            break;
        }
      } // Offset
      else if (actionData.startsWith('null')) {
        switch (_tutorMode) {
          case DrawingMode.drag:
            break;
          case DrawingMode.pen:
            _tutorPenPoints[_tutorCurrentPage].add(null);
            break;
          case DrawingMode.highlighter:
            _tutorHighlighterPoints[_tutorCurrentPage].add(null);
            break;
          case DrawingMode.eraser:
            _tutorEraserPoints[_tutorCurrentPage] = const Offset(-100, -100);
            break;
          default:
            break;
        }
      } // Null
      else if (actionData.startsWith('DrawingMode')) {
        String modeString = actionData.replaceAll('DrawingMode.', '');
        DrawingMode drawingMode = DrawingMode.values.firstWhere(
            (e) => e.toString() == 'DrawingMode.$modeString',
            orElse: () => DrawingMode.drag);
        setState(() {
          _tutorMode = drawingMode;
        });
      } // Mode
      else if (actionData.startsWith('Erase')) {
        var parts = actionData.split('.');
        var index = int.parse(parts.last);
        if (actionData.startsWith('Erase.pen')) {
          removePointStack(_tutorPenPoints[_tutorCurrentPage], index);
        } else if (actionData.startsWith('Erase.high')) {
          removePointStack(_tutorHighlighterPoints[_tutorCurrentPage], index);
        }
      } // Erase
      else if (actionData.startsWith('StrokeColor')) {
        var parts = actionData.split('.');
        var index = int.parse(parts.last);
        setState(() {
          _tutorColorIndex = index;
        });
      } // Color
      else if (actionData.startsWith('StrokeWidth')) {
        var parts = actionData.split('.');
        var index = int.parse(parts.last);
        setState(() {
          _tutorStrokeWidthIndex = index;
        });
      } // Width
      else if (actionData.startsWith('ChangePage')) {
        var parts = actionData.split(':');
        var pageAction = parts.last;
        if (pageAction == 'prev') {
          _tutorCurrentPage--;
        } else if (pageAction == 'next') {
          _tutorCurrentPage++;
        }
      } // Paging
    }
  }

  @override
  Widget build(BuildContext context) {
    return !Responsive.isMobile(context)
        ? _buildTablet()
        : fullScreen
            ? _buildMobileFullScreen()
            : _buildMobile();
  }

  _buildTablet() {
    return Scaffold(
      backgroundColor: CustomColors.grayCFCFCF,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                headerLayer1(),
                const DividerLine(),
                // headerLayer2(),
                // const DividerLine(),

                //Body Layout
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      tabFreestyle ? tools() : toolsDisable(),
                      solvePad(),
                    ],
                  ),
                ),
              ],
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
      ),
      // floatingActionButton:
      //     Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      //   Row(
      //     mainAxisAlignment: MainAxisAlignment.end,
      //     children: [
      //       if (showSpeechBalloon)
      //         InkWell(
      //           onTap: () {
      //             print('bolloon tap');
      //             setState(() {
      //               showSpeechBalloon = false;
      //             });
      //           },
      //           child: SpeechBalloon(
      //             width: 150,
      //             height: 40,
      //             borderRadius: 3,
      //             nipLocation: NipLocation.right,
      //             color: CustomColors.greenPrimary,
      //             child: Center(
      //               child: Text(
      //                 "คำถามที่เคยถาม",
      //                 style: CustomStyles.bold16whitePrimary,
      //               ),
      //             ),
      //           ),
      //         ),
      //       S.w(13),
      //       Stack(
      //         children: [
      //           InkWell(
      //             onTap: () {
      //               showSpeechBalloon = false;
      //               print('List searh found');
      //               // Navigator.push(
      //               //   context,
      //               //   MaterialPageRoute(
      //               //       builder: (context) => const QAListSearchFound()),
      //               // );
      //
      //               //todo for Search Not Found question
      //               // Navigator.push(
      //               //   context,
      //               //   MaterialPageRoute(
      //               //       builder: (context) =>
      //               //           const QuestionSearchNotFound()),
      //               // );
      //             },
      //             child: Image.asset(
      //               'assets/images/ic_qa_float_black.png',
      //               width: 72,
      //             ),
      //           ),
      //           Positioned(
      //             top: 1,
      //             right: 1,
      //             child: Align(
      //               alignment: Alignment.topRight,
      //               child: Container(
      //                 decoration: const BoxDecoration(
      //                     color: CustomColors.greenPrimary,
      //                     shape: BoxShape.circle),
      //                 width: 25,
      //                 height: 25,
      //                 child: Center(
      //                   child: Text(
      //                     "13",
      //                     style: CustomStyles.bold11White,
      //                   ),
      //                 ),
      //               ),
      //             ),
      //           )
      //         ],
      //       ),
      //     ],
      //   ),
      //   S.h(20),
      //   Row(
      //     mainAxisAlignment: MainAxisAlignment.end,
      //     children: [
      //       if (showSpeechBalloon)
      //         InkWell(
      //           onTap: () {
      //             setState(() {
      //               showSpeechBalloon = false;
      //             });
      //           },
      //           child: SpeechBalloon(
      //             width: 150,
      //             height: 40,
      //             borderRadius: 3,
      //             nipLocation: NipLocation.right,
      //             color: CustomColors.greenPrimary,
      //             child: Center(
      //               child: Text(
      //                 "กดเพื่อถามคำถาม",
      //                 style: CustomStyles.bold16whitePrimary,
      //               ),
      //             ),
      //           ),
      //         ),
      //       S.w(13),
      //       InkWell(
      //         onTap: () {
      //           showSpeechBalloon = false;
      //           print('ask tutor');
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => const AskTutor()),
      //           );
      //         },
      //         child: Image.asset(
      //           'assets/images/ic_mic_off_float.png',
      //           width: 72,
      //         ),
      //       ),
      //     ],
      //   )
      // ]),
    );
  }

  _buildMobile() {
    return Scaffold(
        backgroundColor: CustomColors.grayCFCFCF,
        body: SafeArea(
            right: false,
            left: false,
            bottom: false,
            child: Stack(
              children: [
                Column(
                  children: [
                    headerLayer2Mobile(),
                    const DividerLine(),
                  ],
                ),

                ///tools widget
                if (!selectedTools) toolsUndoMobile(),
                if (!selectedTools) toolsMobile(),
                if (selectedTools) toolsActiveMobile(),

                /// Control menu
                if (openShowDisplay == false) toolsControlMobile(),
              ],
            )));
  }

  _buildMobileFullScreen() {
    return Scaffold(
      backgroundColor: CustomColors.grayCFCFCF,
      body: Stack(
        children: [
           Column(
            children: [
              SizedBox(),
            ],
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 40, bottom: 45),
              child: InkWell(
                onTap: () {
                  setState(() {
                    fullScreen = !fullScreen;
                  });
                },
                child: Image.asset(
                  'assets/images/ic__hide_full_float.png',
                  width: 44,
                ),
              ),
            ),
          )
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
        if (mySolvepadSize?.width != solvepadWidth) {
          initSolvepadScaling(solvepadWidth, solvepadHeight);
          _tutorCurrentScrollZoom =
              '${(-1 * solvepadWidth / 2).toStringAsFixed(2)}:0:2';
        }
        return PageView.builder(
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
            return IgnorePointer(
              ignoring: tabFollowing,
              child: InteractiveViewer(
                transformationController: _transformationController[index],
                alignment: const Alignment(-1, -1),
                minScale: 1.0,
                maxScale: 4.0,
                onInteractionUpdate: (ScaleUpdateDetails details) {
                  setState(() {
                    showSpeechBalloon = false;
                  });
                  var translation =
                      _transformationController[index].value.getTranslation();
                  double originalTranslationY = translation.y;
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
                        ignoring: (_mode == DrawingMode.drag || tabFollowing),
                        child: GestureDetector(
                          onPanDown: (_) {},
                          child: Listener(
                            onPointerDown: (details) {
                              showSpeechBalloon = false;
                              if (tabFollowing) return;
                              if (activePointerId != null) return;
                              activePointerId = details.pointer;
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
                              if (tabFollowing) return;
                              if (activePointerId != details.pointer) return;
                              activePointerId = details.pointer;
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
                              if (tabFollowing) return;
                              if (activePointerId != details.pointer) return;
                              activePointerId = null;
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
                                        Offset(-100, -100);
                                  });
                                  break;
                                default:
                                  break;
                              }
                            },
                            onPointerCancel: (details) {
                              if (tabFollowing) return;
                              if (activePointerId != details.pointer) return;
                              activePointerId = null;
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
                                        Offset(-100, -100);
                                  });
                                  break;
                                default:
                                  break;
                              }
                            },
                            child: CustomPaint(
                              painter: SolvepadDrawer(
                                _penPoints[index],
                                _replayPoints[index],
                                _eraserPoints[index],
                                _laserPoints[index],
                                _highlighterPoints[index],
                                _tutorPenPoints[index],
                                _tutorLaserPoints[index],
                                _tutorHighlighterPoints[index],
                                _tutorEraserPoints[index],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // ---------- FUNCTION: solve pad feature
  double square(double x) => x * x;
  double sqrDistanceBetween(Offset p1, Offset p2) =>
      square(p1.dx - p2.dx) + square(p1.dy - p2.dy);

  void doErase(int index, DrawingMode mode) {
    List<SolvepadStroke?> pointStack;
    if (mode == DrawingMode.pen) {
      if (_isReplaying) {
        // TODO: resolve this after initial test
        // pointStack = _replayPoints[_currentReplayPage];
        pointStack = _penPoints[_currentPage];
      } else {
        pointStack = _penPoints[_currentPage];
      }
      removePointStack(pointStack, index);
    } else if (mode == DrawingMode.highlighter) {
      pointStack = _highlighterPoints[_currentPage];
      removePointStack(pointStack, index);
    }
  }

  void removePointStack(List<SolvepadStroke?> pointStack, int index) {
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

  void _tutorLaserDrawing() {
    _tutorLaserTimer?.cancel();
  }

  void _tutorStopLaserDrawing() {
    setState(() {
      _tutorLaserPoints[_currentPage].clear();
    });
  }

  // ---------- FUNCTION: page control
  void _addPage() {
    setState(() {
      _penPoints.add([]);
      _laserPoints.add([]);
      _highlighterPoints.add([]);
      _eraserPoints.add(const Offset(-100, -100));
      _replayPoints.add([]);
      _tutorPenPoints.add([]);
      _tutorLaserPoints.add([]);
      _tutorHighlighterPoints.add([]);
      _tutorEraserPoints.add(const Offset(-100, -100));
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

  String _formatElapsedTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return ' $hours : $minutes : $seconds ';
  }

  void animateCircleProgress() {
    if (animation.value == 100) {
      progressController.reverse();
    } else {
      progressController.forward();
    }
  }

  Widget play() {
    return Center(
      child: SizedBox(
        width: 45,
        height: 45,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _isPause = !_isPause;
            });
            if (!_isPause) {
              if (!_isReplaying) {
                stopwatch.reset();
                stopwatch.start();
                replayLoopLive();
              } else {
                stopwatch.start();
              }
            } else {
              stopwatch.stop();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color:
                  !_isPause ? CustomColors.gray363636 : CustomColors.redFF4201,
              border: Border.all(
                color: !_isPause
                    ? CustomColors.redFF4201
                    : CustomColors.gray363636,
                style: BorderStyle.solid,
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(100),
            ),
            child: !_isPause
                ? const Icon(
                    Icons.pause,
                    size: 25,
                    color: CustomColors.white,
                  )
                : const Icon(
                    Icons.play_arrow,
                    size: 25,
                    color: CustomColors.white,
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
              flex: Responsive.isTablet(context) ? 4 : 3,
              child: Row(
                children: [
                  const Icon(
                    Icons.arrow_back,
                    color: CustomColors.gray878787,
                    size: 20.0,
                  ),
                  S.w(8),
                  Text(
                    widget.courseName,
                    style: CustomStyles.bold16Black363636Overflow,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          if (Responsive.isDesktop(context))
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.arrow_back,
                        color: CustomColors.gray878787,
                        size: 20.0,
                      ),
                    ),
                  ),
                  S.w(defaultPadding),
                  Text(
                    widget.courseName,
                    style: CustomStyles.bold16Black363636Overflow,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          Align(alignment: Alignment.centerRight, child: pagingTools()),
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
            flex: 3,
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
                    // Image.asset(
                    //   ImageAssets.allPages,
                    //   height: 30,
                    //   width: 32,
                    // ),
                    // S.w(defaultPadding),
                    // Container(
                    //   width: 1,
                    //   height: 24,
                    //   color: CustomColors.grayCFCFCF,
                    // ),
                    // S.w(defaultPadding),
                    Material(
                      child: InkWell(
                        onTap: () {
                          if (tabFollowing) return;
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
                        // splashColor: Colors.lightGreen,
                        onTap: () {
                          if (tabFollowing) return;
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
                    S.w(6.0),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      if (tabFreestyle == true) {
                        tabFollowing = !tabFollowing;
                        tabFreestyle = false;
                        var parts = _tutorCurrentScrollZoom.split(':');
                        var scrollX = double.parse(parts[0]);
                        var scrollY = double.parse(parts[1]);
                        var zoom = double.parse(parts.last);
                        if (_currentPage != _tutorCurrentPage) {
                          _pageController.animateToPage(
                            _tutorCurrentPage,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } // re-correct page
                        _transformationController[_tutorCurrentPage].value =
                            Matrix4.identity()
                              ..translate(
                                  scaleScrollX(scrollX), scaleScrollY(scrollY))
                              ..scale(zoom);
                      }
                    });
                  },
                  child: Container(
                    height: 50,
                    width: 120,
                    decoration: BoxDecoration(
                      color: tabFollowing
                          ? CustomColors.greenE5F6EB
                          : CustomColors.whitePrimary,
                      shape: BoxShape.rectangle,
                      border: Border.all(
                        color: CustomColors.grayCFCFCF,
                        style: BorderStyle.solid,
                        width: 1.0,
                      ),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(50.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Image.asset(
                          tabFollowing
                              ? ImageAssets.avatarMen
                              : ImageAssets.avatarDisMen,
                          width: 32,
                        ),
                        S.w(8),
                        Text("เรียนรู้",
                            style: tabFollowing
                                ? CustomStyles.bold14greenPrimary
                                : CustomStyles.bold14grayCFCFCF),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      if (tabFollowing == true) {
                        tabFreestyle = !tabFreestyle;
                        tabFollowing = false;
                      }
                    });
                  },
                  child: Container(
                    height: 50,
                    width: 120,
                    decoration: BoxDecoration(
                      color: tabFreestyle
                          ? CustomColors.greenE5F6EB
                          : CustomColors.whitePrimary,
                      shape: BoxShape.rectangle,
                      border: Border.all(
                        color: CustomColors.grayCFCFCF,
                        style: BorderStyle.solid,
                        width: 1.0,
                      ),
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(50.0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Image.asset(
                          tabFreestyle
                              ? ImageAssets.pencilActive
                              : ImageAssets.penDisTab,
                          width: 32,
                        ),
                        S.w(8),
                        Text("เขียนอิสระ",
                            style: tabFreestyle
                                ? CustomStyles.bold14greenPrimary
                                : CustomStyles.bold14grayCFCFCF),
                      ],
                    ),
                  ),
                ),
                S.w(12),
                S.w(12),
              ],
            ),
          ),
          play(),
          S.w(20),
        ],
      ),
    );
  }

  Widget pagingTools() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Material(
          child: InkWell(
            onTap: () {
              if (tabFollowing) return;
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text("Page ${_currentPage + 1}",
                  style: CustomStyles.bold14greenPrimary),
            ],
          ),
        ),
        S.w(8.0),
        Text("/ ${_pages.length}", style: CustomStyles.med14Gray878787),
        S.w(8),
        Material(
          child: InkWell(
            // splashColor: Colors.lightGreen,
            onTap: () {
              if (tabFollowing) return;
              if (_pages.length > 1) {
                if (_pageController.hasClients &&
                    _pageController.page!.toInt() != _pages.length - 1) {
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
        S.w(6.0),
      ],
    );
  }

  Future<void> headerLayer1Mobile() {
    return showDialog(
      useSafeArea: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
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
                                      "คอร์สปรับพื้นฐานคณิตศาสตร์ ก่อนขึ้น ม.4  - 01 ม.ค. 2023",
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
                                        text: '01 : 59 : 59',
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
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          S.w(28),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              child: Container(
                  height: 38,
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
                      S.w(8),
                      Transform.scale(
                        scale: 0.6,
                        child: CupertinoSwitch(
                          value: _switchValue,
                          onChanged: (bool value) {
                            setState(() {
                              _switchValue = value;
                            });
                            print(value);
                          },
                        ),
                      ),
                      Text("เลื่อนหน้าตามติวเตอร์",
                          style: CustomStyles.bold12gray878787),
                      S.w(8.0),
                    ],
                  )),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Image.asset(
                  ImageAssets.avatarMen,
                  height: 32,
                  width: 32,
                ),
                S.w(8),
                Container(
                  height: 32,
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
                      S.w(8),
                      InkWell(
                        onTap: () {
                          print('leader');
                          // showLeader(context);
                        },
                        child: Image.asset(
                          ImageAssets.leaderboard,
                          height: 24,
                          width: 24,
                        ),
                      ),
                      S.w(8),
                    ],
                  ),
                ),
                S.w(defaultPadding),
                InkWell(
                  onTap: () {},
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: CustomColors.greenPrimary,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child:
                        Text("ไปหน้าที่สอน", style: CustomStyles.bold11White),
                  ),
                ),
              ],
            ),
          ),
          S.w(28),
        ],
      ),
    );
  }

  void updateDataHistory(dynamic updateMode) {
    _mode = updateMode;
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
              height: selectedTools
                  ? 270
                  : MediaQuery.of(context).size.height - 300,
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
                  //             print("Undo");
                  //           },
                  //           child: Image.asset(
                  //             ImageAssets.undo,
                  //             width: 38,
                  //           ),
                  //         ),
                  //         InkWell(
                  //           onTap: () {
                  //             print("Redo");
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
                                        if (index == 0) {
                                          updateDataHistory(DrawingMode.drag);
                                        } else if (index == 1) {
                                          updateDataHistory(DrawingMode.pen);
                                        } else if (index == 2) {
                                          updateDataHistory(
                                              DrawingMode.highlighter);
                                        } else if (index == 3) {
                                          updateDataHistory(DrawingMode.eraser);
                                        } else if (index == 4) {
                                          updateDataHistory(DrawingMode.laser);
                                        }
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
                                  //           print("Clear");
                                  //         },
                                  //         child: Image.asset(
                                  //           ImageAssets.bin,
                                  //           width: 38,
                                  //         ),
                                  //       ),
                                  //       InkWell(
                                  //         onTap: () {
                                  //           print("More");
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

  Widget toolsDisable() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (Responsive.isDesktop(context)) S.w(10),
        InkWell(
          onTap: () {
            final snackBar = SnackBar(
              content: Text(
                'เปลี่ยนเป็นโหมด “เขียนอิสระ” ก่อนเพื่อใช้ปากกา',
                style: CustomStyles.bold16whitePrimary,
              ),
              action: SnackBarAction(
                label: 'ไปที่โหมดเขียนอิสระ',
                textColor: CustomColors.greenPrimary,
                onPressed: () {
                  // Some code to undo the change.
                },
              ),
            );

            // Find the ScaffoldMessenger in the widget tree
            // and use it to show a SnackBar.
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          },
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnimatedContainer(
                duration: const Duration(seconds: 1),
                curve: Curves.fastOutSlowIn,
                height:
                    selectedTools ? 270 : MediaQuery.of(context).size.height,
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
                    S.h(8),
                    // Expanded(
                    //   flex: 1,
                    //   child: Padding(
                    //     padding: const EdgeInsets.symmetric(
                    //         horizontal: defaultPadding, vertical: 1),
                    //     child: Row(
                    //       mainAxisAlignment: MainAxisAlignment.spaceAround,
                    //       children: [
                    //         Image.asset(
                    //           ImageAssets.undoTran,
                    //           width: 38,
                    //         ),
                    //         Image.asset(
                    //           ImageAssets.redoTran,
                    //           width: 38,
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    Container(
                        height: 2, width: 80, color: CustomColors.grayF3F3F3),
                    Expanded(
                      flex: 4,
                      child: ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          itemCount: _listToolsDisable.length,
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                S.h(8),
                                Image.asset(
                                  _listToolsDisable[index]['image'],
                                  width: 10.w,
                                ),
                              ],
                            );
                          }),
                    ),
                    Container(
                        height: 2, width: 80, color: CustomColors.grayF3F3F3),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          S.h(defaultPadding),
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
                                          Image.asset(
                                            'assets/images/pick-green-tran.png',
                                            width: 38,
                                          ),
                                          Image.asset(
                                            'assets/images/pick-line-tran.png',
                                            width: 38,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Image.asset(
                                            'assets/images/clear_tran.png',
                                            width: 38,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
                setState(() {
                  openShowDisplay = !openShowDisplay;
                });
              },
              child: Image.asset(
                'assets/images/ic_open_show.png',
                width: 44,
              ),
            ),
            S.h(8),
            Stack(
              children: [
                InkWell(
                  onTap: () {
                    print('search found');
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //       builder: (context) => const QAListSearchFound()),
                    // );

                    /// TODO: for Search Not Found question
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //       builder: (context) => const QuestionSearchNotFound()),
                    // );
                  },
                  child: Image.asset(
                    'assets/images/ic_qa_float_black.png',
                    height: 44,
                    width: 44,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 21),
                  child: Container(
                    decoration: const BoxDecoration(
                        color: CustomColors.greenPrimary,
                        shape: BoxShape.circle),
                    width: 25,
                    height: 25,
                    child: Center(
                      child: Text(
                        "13",
                        style: CustomStyles.bold11White,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            S.h(8),
            InkWell(
              onTap: () {
                if (Responsive.isMobile(context)) {
                  print('screenshot');
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //       builder: (context) => const ScreenShotModalMobile()),
                  // );
                } else {
                  print('ask tutor');
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => const AskTutor()),
                  // );
                }
              },
              child: Image.asset(
                'assets/images/ic_mic_off_float.png',
                width: 44,
              ),
            ),
            S.h(8),
            InkWell(
              onTap: () {
                setState(() {
                  fullScreen = !fullScreen;
                });
              },
              child: Image.asset(
                'assets/images/ic_full_float.png',
                width: 44,
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
                                    print('Tap : index $index');
                                    print(
                                        'Tap : _selectIndex $_selectedIndexColors');
                                  },
                                  child: Image.asset(
                                      _listColors[index]['color'],
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
                                              ? _listLines[index]
                                                  ['image_active']
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
                width: selectedTools ? 0 : 310,
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
                                    _listToolsMobile[_selectedIndexTools]
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
                                  itemCount: _listToolsMobile.length,
                                  itemBuilder: (context, index) {
                                    return Row(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedIndexTools = index;
                                            });
                                            print('Tap : index $index');
                                            print(
                                                'Tap : _selectIndex $_selectedIndexTools');
                                          },
                                          child: Image.asset(
                                            _selectedIndexTools == index
                                                ? _listToolsMobile[index]
                                                    ['image_active']
                                                : _listToolsMobile[index]
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
                                  print("Pick Line");

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
                              S.w(defaultPadding),
                              InkWell(
                                onTap: () {
                                  print("Clear");
                                },
                                child: Image.asset(
                                  ImageAssets.bin,
                                  width: 38,
                                ),
                              ),
                              S.w(defaultPadding),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedTools = !selectedTools;
                                  });
                                },
                                child: Image.asset(
                                  ImageAssets.arrowLeftDouble,
                                  width: 14,
                                ),
                              ),
                            ],
                          )),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  Widget toolsUndoMobile() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            InkWell(
              onTap: () {
                print("Undo");
              },
              child: Image.asset(
                ImageAssets.undo,
                width: 38,
              ),
            ),
            S.h(8),
            InkWell(
              onTap: () {
                print("Redo");
              },
              child: Image.asset(
                ImageAssets.redo,
                width: 38,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                  _listToolsMobile[_selectedIndexTools]['image_active'],
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
}
