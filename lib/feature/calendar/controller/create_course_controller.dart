import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solve_tutor/feature/calendar/model/course_model.dart';
import 'package:solve_tutor/feature/calendar/model/days.dart';
import 'package:solve_tutor/feature/calendar/model/document_model.dart';
import 'package:solve_tutor/feature/calendar/model/level_model.dart';
import 'package:solve_tutor/feature/calendar/model/menu_create_%20course_model.dart';

import 'package:solve_tutor/feature/calendar/model/select_option_item.dart';
import 'package:solve_tutor/feature/calendar/model/student_model.dart';
import 'package:solve_tutor/feature/calendar/model/subject_model.dart';
import 'package:solve_tutor/feature/calendar/pages/utils.dart';
import 'package:solve_tutor/feature/calendar/service/course_service.dart';
import 'package:solve_tutor/feature/calendar/widgets/format_date.dart';
import 'package:table_calendar/table_calendar.dart';

class CourseController extends ChangeNotifier {
  var courseNameTextEditing = TextEditingController();
  var courseDetailTextEditing = TextEditingController();
  var courseRecommendTextEditing = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final levels = <SelectOptionItem>[];
  final subjects = <SelectOptionItem>[];
  var courseNames = '';
  var selectedLevel = '';
  var selectedSubject = '';
  var indexSelected = 0;
  int? selectedDocumentIndex;
  var isLoading = false;
  var keywordTextEditingController = TextEditingController();
  List<String> studentIds = [];
  List<StudentModel> studentDetails = [];
  Map<DateTime, List<Event>> kEventSource = {};
  LinkedHashMap<DateTime, List<Event>>? kEvents;
  DocumentModel? document;
  File? pickedImage;
  bool showFile = false;
  Timer? _timer;
  List<CourseModel> courseFilter = [];
  List<CourseModel> courseList = [];
  var calendarListAll = <CalendarDate>[];
  CourseModel? courseData;
  DateTime? kFirstTime;
  var amountStudentTextEditing = TextEditingController();
  var skipWeekTextEditing = TextEditingController();
  var startDateController = TextEditingController();
  var endDateController = TextEditingController();
  var selectedDateController = TextEditingController();
  var startTimeController = TextEditingController();
  var endTimeController = TextEditingController();
  var findStudentController = TextEditingController();
  var haveErrorText = '';

  setHaveError(String text) {
    haveErrorText = text;
    notifyListeners();
  }

  setPublishing(bool value) {
    courseData?.publishing = value;
    notifyListeners();
  }

  List<Days> days = [
    Days(id: 7, day: 'อา'),
    Days(id: 1, day: 'จ'),
    Days(id: 2, day: 'อ'),
    Days(id: 3, day: 'พ'),
    Days(id: 4, day: 'พฤ'),
    Days(id: 5, day: 'ศ'),
    Days(id: 6, day: 'ส'),
  ];

  getDataCalendarList(List<CalendarDate> calendarClassList) {
    List<CalendarDate> dateNotRepeat = [];

    var date = dateNotRepeat.map((element) => DateTime(
          element.start?.year ?? 0,
          element.start?.month ?? 0,
          element.start?.day ?? 0,
        ));

    for (var i in calendarClassList) {
      if (date.contains(DateTime(
        i.start?.year ?? 0,
        i.start?.month ?? 0,
        i.start?.day ?? 0,
      ))) {
      } else {
        dateNotRepeat.add(i);
      }
    }

    List<CalendarDate> df(item) => calendarClassList
        .where((element) =>
            DateTime(
              element.start?.year ?? 0,
              element.start?.month ?? 0,
              element.start?.day ?? 0,
            ).compareTo(DateTime(
              dateNotRepeat[item].start?.year ?? 0,
              dateNotRepeat[item].start?.month ?? 0,
              dateNotRepeat[item].start?.day ?? 0,
            )) ==
            0)
        .toList();
    kEventSource = {
      for (var item in List.generate(dateNotRepeat.length, (index) => index))
        DateTime.utc(
          dateNotRepeat[item].start?.year ?? 0,
          dateNotRepeat[item].start?.month ?? 0,
          dateNotRepeat[item].start?.day ?? 0,
        ): List.generate(
          df(item).length,
          (index) => Event(
              title:
                  '${FormatDate.timeOnlyNumber(df(item)[index].start)} - ${FormatDate.timeOnlyNumber(df(item)[index].end)}',
              start: df(item)[index].start ?? DateTime.now(),
              end: df(item)[index].end ?? DateTime.now(),
              courseId: df(item)[index].courseId ?? '',
              courseName: df(item)[index].courseName ?? ''),
        )
    };

    kEvents = LinkedHashMap<DateTime, List<Event>>(
      equals: isSameDay,
      hashCode: getHashCode,
    )..addAll(kEventSource);
    notifyListeners();
  }

  setSelectedDocument(int index) {
    selectedDocumentIndex = index;
    notifyListeners();
  }

  // setDocument(DocumentModel doc) {
  //   document = doc;
  //   notifyListeners();
  // }

  void initialize() {
    keywordTextEditingController.addListener(() {
      String keyword = keywordTextEditingController.text.trim();
      _timer?.cancel();
      debugPrint('filter object for keyword = $keyword');
      courseFilter.clear();
      if (courseList.isNotEmpty) {
        for (var i = 0; i < courseList.length; i++) {
          if (courseList[i].courseName?.contains(keyword) == true) {
            courseFilter.add(courseList[i]);
          }
          notifyListeners();
        }
      }
    });
  }

  Future<void> setInitData(CourseModel courseModel) async {
    courseNameTextEditing.text = courseData?.courseName ?? '';
    courseDetailTextEditing.text = courseData?.detailsText ?? '';
    courseRecommendTextEditing.text = courseData?.recommendText ?? '';
    courseRecommendTextEditing.text = courseData?.recommendText ?? '';
    startDateController.text = FormatDate.dayOnlyNumber(courseData?.firstDay);
    endDateController.text = FormatDate.dayOnlyNumber(courseData?.lastDay);
    notifyListeners();
  }

  clearData() {
    if (courseNameTextEditing.text.isNotEmpty) {
      courseNameTextEditing.text = '';
    }
    if (courseDetailTextEditing.text.isNotEmpty) {
      courseDetailTextEditing.text = '';
    }
    if (courseRecommendTextEditing.text.isNotEmpty) {
      courseRecommendTextEditing.text = '';
    }
    if (courseRecommendTextEditing.text.isNotEmpty) {
      courseRecommendTextEditing.text = '';
    }
    if (selectedLevel.isNotEmpty) {
      selectedLevel = '';
    }
    if (selectedSubject.isNotEmpty) {
      selectedSubject = '';
    }
    if (pickedImage != null) {
      pickedImage = null;
    }
    if (startTimeController.text.isNotEmpty) {
      startTimeController.clear();
    }
    if (endTimeController.text.isNotEmpty) {
      endTimeController.clear();
    }
    if (startDateController.text.isNotEmpty) {
      startDateController.text = '';
    }
    if (endDateController.text.isNotEmpty) {
      endDateController.text = '';
    }
  }

  lastChangeName(String value) {
    // courseNameTextEditing.text = value;
    notifyListeners();
  }

  lastAmountSkipWeek(String value) {
    if (value.isEmpty) {
      value = "0";
    }
    skipWeekTextEditing.text = value;
    notifyListeners();
  }

  setLevel(String value) {
    // requestCreateCourseModel.levelId = value;

    notifyListeners();
  }

  setSubject(String value) {
    // requestCreateCourseModel.subjectId = value;

    notifyListeners();
  }

  lastChangeDetails(String value) {
    // requestCreateCourseModel.detailsText = value;
    notifyListeners();
  }

  lastChangeRecommend(String value) {
    // requestCreateCourseModel.recommendText = value;
    notifyListeners();
  }

  void isShouldShowFile(bool value) {
    showFile = value;
    notifyListeners();
  }

  Future<void> getCourseListByTutorId(String tutor) async {
    isLoading = true;
    courseList.clear();
    final data = await CourseService().getCourseListByTutorId(tutor);
    courseList.addAll(data);
    isLoading = false;
    notifyListeners();
  }

  Future<void> refreshCourseListByTutorId(String tutor) async {
    isLoading = true;
    courseList.clear();
    notifyListeners();
    final data = await CourseService().getCourseListByTutorId(tutor);
    courseList.addAll(data);
    isLoading = false;
    notifyListeners();
  }

  Future<void> openGallery({
    required BuildContext context,
    required CourseModel courseData,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 100,
      );

      if (pickedFile == null) return;

      pickedImage = File(pickedFile.path);
      final imageUrl = await CourseService().uploadThumbnail(
        tutorId: courseData.tutorId ?? "",
        file: pickedImage!,
        id: courseData.id ?? "",
      );
      courseData.thumbnailUrl = imageUrl;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<String?> openFileVideo({
    required BuildContext context,
    required CourseModel courseData,
  }) async {
    try {
      List<String>? videoUrl;
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'wav'],
      );
      if (result == null) return '';

      if (result.files.isNotEmpty) {
        File file = File(result.files.single.path ?? '');
        List<File> files = [];
        files.add(file);

        videoUrl = await CourseService().uploadVideo(
            file: file,
            tutorId: courseData.tutorId ?? '',
            id: courseData.id ?? '');
      }
      return videoUrl?.first.toString();
    } catch (error) {
      rethrow;
    }
  }

  void indexTo(int index) {
    indexSelected = index;
    for (var i = 0; i < menuCreateCourse.length; i++) {
      if (index == i) {
        menuCreateCourse[i].active = true;
      } else {
        menuCreateCourse[i].active = false;
      }
    }

    notifyListeners();
  }

  void discardIndexTo(int index) {
    indexSelected = index;
    for (var i = 0; i < menuCreateCourse.length; i++) {
      if (index == i) {
        menuCreateCourse[i].active = true;
      } else {
        menuCreateCourse[i].active = false;
      }
    }
  }

  getSubjects() async {
    subjects.clear();
    final List<SubjectModel> data = await CourseService().getSubjectList();
    subjects.addAll(List.generate(
      data.length,
      (index) => SelectOptionItem(
          id: data[index].subjectId, name: data[index].subjectName),
    ));
    subjects.add(SelectOptionItem(id: '999', name: 'อื่นๆ'));
    notifyListeners();
  }

  getLevels() async {
    levels.clear();
    final List<LevelModel> data = await CourseService().getLevelsList();
    var list = List.generate(
      data.length,
      (index) => SelectOptionItem(
          id: data[index].levelId, name: data[index].levelName),
    );
    list.sort((a, b) {
      if (a.name == null && b.name == null) return 0;
      if (a.name == null) return 1;
      if (b.name == null) return -1;
      return a.name!.compareTo(b.name!);
    });
    levels.addAll(list);
    notifyListeners();
  }

  final List<MenuCreateCourseModel> menuCreateCourse = [
    MenuCreateCourseModel(title: 'รายละเอียดคอร์ส', active: true),
    MenuCreateCourseModel(title: 'เลือกเอกสาร'),
    MenuCreateCourseModel(title: 'บันทึกบทเรียน'),
    // MenuCreateCourseModel(title: 'ตั้งค่าคำถาม')
  ];

  Future<CourseModel> getCourseById(String id) async {
    try {
      final data = await CourseService().getCourseById(id);
      courseData = data;
      return data;
    } catch (error) {
      debugPrint(error.toString());
      rethrow;
    }
  }

  Future<String> saveCourse(CourseModel courseData) async {
    try {
      final String id = await CourseService().createCourse(courseData);
      return id;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteCourseById({required String id}) async {
    try {
      await CourseService().deleteCourseById(id);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateCourseDetails(CourseModel? courseData) async {
    try {
      if (courseData == null) return;
      if (courseData.id?.isNotEmpty == true &&
          courseData.tutorId?.isNotEmpty == true) {
        await CourseService().updateCourseDetails(courseData);
        if (courseData.publishing ?? false) {
          await updateCoursePublishing(courseData, true);
        }
      }
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  Future<void> updateCoursePublishing(
      CourseModel? courseData, bool value) async {
    try {
      if (courseData == null) return;
      if (courseData.id?.isNotEmpty == true &&
          courseData.tutorId?.isNotEmpty == true) {
        await CourseService().updateCoursePublishing(courseData, value);
      }
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  Future<void> getCalendarListAll(String tutorId) async {
    try {
      calendarListAll = await CourseService().getCalendarList(tutorId);
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<bool> deleteFileById({
    required String tutorId,
    required String documentId,
    required String fileId,
  }) async {
    try {
      await CourseService().deleteFileById(
          tutorId: tutorId, documentId: documentId, fileId: fileId);
      return true;
    } catch (error) {
      return false;
    }
  }
}
