import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/feature/calendar/model/course_model.dart';
import 'package:solve_tutor/feature/calendar/model/days.dart';
import 'package:solve_tutor/feature/calendar/model/document_model.dart';
import 'package:solve_tutor/feature/calendar/model/level_model.dart';
import 'package:solve_tutor/feature/calendar/model/menu_create_%20course_model.dart';
import 'package:solve_tutor/feature/calendar/model/select_option_item.dart';
import 'package:solve_tutor/feature/calendar/model/show_course.dart';
import 'package:solve_tutor/feature/calendar/model/student_model.dart';
import 'package:solve_tutor/feature/calendar/model/subject_model.dart';
import 'package:solve_tutor/feature/calendar/pages/utils.dart';
import 'package:solve_tutor/feature/calendar/service/course_live_service.dart';
import 'package:solve_tutor/feature/calendar/widgets/format_date.dart';
import 'package:solve_tutor/feature/chat/models/chat_model.dart';
import 'package:solve_tutor/feature/chat/models/message.dart';
import 'package:solve_tutor/feature/chat/service/chat_provider.dart';
import 'package:solve_tutor/feature/order/model/order_class_model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';

class CourseLiveController extends ChangeNotifier {
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
  var isLoadingCalendarListAll = false;
  var isLoadingCourseTutorToday = false;
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
  List<ShowCourseTutor> showCourseTutorToday = [];
  List<ShowCourseTutor> showCourseTutorFilterToday = [];
  var amountStudentTextEditing = TextEditingController();
  var skipWeekTextEditing = TextEditingController();
  var startDateController = TextEditingController();
  var endDateController = TextEditingController();
  var selectedDateController = TextEditingController();
  var startTimeController = TextEditingController();
  var endTimeController = TextEditingController();
  var findStudentController = TextEditingController();
  var haveErrorText = '';

  final StreamController _updateController = StreamController.broadcast();
  Stream get updateStream => _updateController.stream;

  @override
  void dispose() {
    _updateController.close();
    super.dispose();
  }

  void refresh() {
    _updateController.add(null);
  }

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

  List<Days> daysDD = [
    Days(id: 7, day: 'Sun'),
    Days(id: 1, day: 'Mon'),
    Days(id: 2, day: 'Tues'),
    Days(id: 3, day: 'Wed'),
    Days(id: 4, day: 'Thu'),
    Days(id: 5, day: 'Fri'),
    Days(id: 6, day: 'Sat'),
  ];

  List<Days> daysForTablet = [
    Days(id: 1, day: 'จันทร์'),
    Days(id: 2, day: 'อังคาร'),
    Days(id: 3, day: 'พุธ'),
    Days(id: 4, day: 'พฤหัสบดี'),
    Days(id: 5, day: 'ศุกร์'),
    Days(id: 6, day: 'เสาร์'),
    Days(id: 7, day: 'อาทิตย์'),
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
    final data = await CourseLiveService().getCourseLiveListByTutorId(tutor);
    courseList.addAll(data);
    isLoading = false;
    notifyListeners();
  }

  Future<void> getCourseListByTutorIdAndCourseType(
      String tutor, String courseType) async {
    isLoading = true;
    courseList.clear();
    final data = await CourseLiveService()
        .getCourseLiveListByTutorIdAndCourseType(tutor, courseType);
    courseList.addAll(data);
    isLoading = false;
    notifyListeners();
  }

  Future<void> refreshCourseListByTutorId(String tutor) async {
    isLoading = true;
    courseList.clear();
    notifyListeners();
    final data = await CourseLiveService().getCourseLiveListByTutorId(tutor);
    courseList.addAll(data);
    isLoading = false;
    notifyListeners();
  }

  Future<void> refreshCourseListByTutorIdAndCourseType(
      String tutor, String courseType) async {
    isLoading = true;
    courseList.clear();
    notifyListeners();
    final data = await CourseLiveService()
        .getCourseLiveListByTutorIdAndCourseType(tutor, courseType);
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
      final imageUrl = await CourseLiveService().uploadThumbnail(
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
    final List<SubjectModel> data = await CourseLiveService().getSubjectList();
    subjects.addAll(List.generate(
      data.length,
      (index) => SelectOptionItem(
          id: data[index].subjectId, name: data[index].subjectName),
    ));
    notifyListeners();
  }

  getLevels() async {
    levels.clear();
    final List<LevelModel> data = await CourseLiveService().getLevelsList();
    levels.addAll(
      List.generate(
        data.length,
        (index) => SelectOptionItem(
            id: data[index].levelId, name: data[index].levelName),
      ),
    );

    notifyListeners();
  }

  final List<MenuCreateCourseModel> menuCreateCourse = [
    MenuCreateCourseModel(title: 'รายละเอียดคอร์ส', active: true),
    MenuCreateCourseModel(title: 'เลือกเอกสาร'),
    MenuCreateCourseModel(title: 'ตารางเรียน'),
    // MenuCreateCourseModel(title: 'ตั้งค่าคำถาม')
  ];

  Future<CourseModel> getCourseById(String id) async {
    try {
      final data = await CourseLiveService().getCourseLiveById(id);
      courseData = data;
      notifyListeners();
      return data;
    } catch (error) {
      debugPrint(error.toString());
      rethrow;
    }
  }

  Future<String> saveCourse(CourseModel courseData) async {
    try {
      final String id = await CourseLiveService().createCourseLive(courseData);
      return id;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteCourseById({required String id}) async {
    try {
      await CourseLiveService().deleteCourseLiveById(id);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateCourseDetails(
      BuildContext context, CourseModel? courseData) async {
    try {
      ChatProvider chat = Provider.of<ChatProvider>(context, listen: false);
      if (courseData == null) return;
      if (courseData.id?.isNotEmpty == true &&
          courseData.tutorId?.isNotEmpty == true) {
        await CourseLiveService().updateCourseLiveDetails(courseData);
        for (var i = 0; i < (courseData.studentIds?.length ?? 0); i++) {
          OrderClassModel orderNew = await createMarketOrder(
            courseData.id ?? "",
            courseData.courseName ?? "",
            courseData.detailsText ?? "",
            courseData.tutorId ?? "",
            courseData.studentIds?[i] ?? "",
          );
          ChatModel? data = await createMarketChat(
            courseData.id ?? "",
            courseData.tutorId ?? "",
            courseData.studentIds?[i] ?? "",
          );
          // await chat.setMyChat(data);
          await chat.sendFirstMessage(
            data?.chatId ?? "",
            data?.customerId ?? "",
            "ข้อความอัตโนมัตินี้สร้างโดย SOLVE คุณสามารถส่งข้อความหากันภายในช่องแชทนี้ได้แล้ว",
            MessageType.text,
          );
        }
      }
    } catch (error) {
      debugPrint('updateCourseDetails error: $error');
    }
  }

  Future<void> updateSessionDetails(
      BuildContext context, CourseModel? courseData) async {
    try {
      if (courseData == null) return;
      if (courseData.id?.isNotEmpty == true &&
          courseData.tutorId?.isNotEmpty == true) {
        await CourseLiveService().updateCourseLiveDetails(courseData);
      }
    } catch (error) {
      debugPrint('updateCourseDetails error: $error');
    }
  }

  Future<OrderClassModel> createMarketOrder(
    String courseId,
    String courseTitle,
    String courseContent,
    String tutorId,
    String studentId,
  ) async {
    final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
    var uuid = const Uuid();
    String refId = "#${(uuid.hashCode + 1).toString().padLeft(5, '0')}";
    String orderUid = uuid.v4();

    orderUid = "${courseId}_${studentId}_${tutorId}";
    OrderClassModel? order;
    var ref = await firebaseFirestore.collection('orders').doc(orderUid).get();
    if (ref.data()?.isNotEmpty ?? false) {
      order = OrderClassModel.fromJson(ref.data()!);
    } else {
      order = OrderClassModel(
        id: orderUid,
        tutorId: tutorId,
        studentId: studentId,
        classId: courseId,
        refId: refId,
        title: courseTitle,
        content: courseContent,
        fromMarketPlace: true,
      );
      await firebaseFirestore
          .collection('orders')
          .doc(orderUid)
          .set(order.toJson());
    }
    return order;
  }

  Future<ChatModel?> createMarketChat(
    String orderId,
    String tutorId,
    String studentId,
  ) async {
    final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
    String chatId = "${orderId}_${studentId}_$tutorId";
    await firebaseFirestore.collection('chats').doc(chatId).set({
      'chat_id': chatId,
      'order_id': orderId,
      'customer_id': studentId,
      'tutor_id': tutorId,
    });
    // await makeMessage(chatId, studentId);
    // await makeMessage(chatId, tutorId);
    log('created =>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
    return await getChatInfo(chatId);
  }

  Future<ChatModel?> getChatInfo(String chatId) async {
    final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
    ChatModel? chat;
    await firebaseFirestore
        .collection('chats')
        .doc(chatId)
        .get()
        .then((userFirebase) async {
      if (userFirebase.exists) {
        chat = ChatModel.fromJson(userFirebase.data()!);
      }
    });
    return chat;
  }

  Future<void> updateCourseDetailsOnlyStudent(CourseModel courseData) async {
    try {
      await CourseLiveService().updateCourseLiveDetails(courseData);
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
        await CourseLiveService().updateCourseLivePublishing(courseData, value);
      }
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  Future<void> getCalendarListAll(String tutorId) async {
    try {
      isLoadingCalendarListAll = true;
      calendarListAll = await CourseLiveService().getCalendarLiveList(tutorId);
      isLoadingCalendarListAll = false;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> getCourseTutorToday(String tutorId) async {
    try {
      showCourseTutorFilterToday.clear();
      var now = DateTime.now();
      var today = DateTime(now.year, now.month, now.day);
      isLoadingCourseTutorToday = true;
      var data = await CourseLiveService().getCourseTutorToday(tutorId);
      showCourseTutorToday = data;
      showCourseTutorFilterToday = data.where((element) {
        final aDate = DateTime(element.start?.year ?? 0,
            element.start?.month ?? 0, element.start?.day ?? 0);
        if (aDate == today) {
          return true;
        } else {
          return false;
        }
      }).toList();
      isLoadingCourseTutorToday = false;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }
}
