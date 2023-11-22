import 'package:solve_tutor/feature/calendar/model/document_model.dart';
import 'package:solve_tutor/feature/calendar/model/student_model.dart';

class CourseModel {
  String? id;
  String? courseName;
  String? levelId;
  String? subjectId;
  String? thumbnailUrl;
  String? recommendText;
  String? detailsText;
  String? tutorId;
  String? documentId;
  int? documentCount;
  DocumentModel? document;
  List<Lessons>? lessons = [];
  DateTime? createTime;
  DateTime? updateTime;
  List<CalendarDate>? calendars = [];
  List<String>? studentIds;
  List<StudentModel>? studentDetails;
  DateTime? firstDay;
  DateTime? lastDay;
  bool? publishing;
  String? courseType;
  double? price;

  CourseModel({
    this.courseName,
    this.levelId,
    this.subjectId,
    this.thumbnailUrl,
    this.recommendText,
    this.detailsText,
    this.tutorId,
    this.documentId,
    this.documentCount,
    this.document,
    this.lessons,
    this.createTime,
    this.updateTime,
    this.calendars,
    this.studentDetails,
    this.firstDay,
    this.lastDay,
    this.publishing,
    this.courseType,
    this.price,
  });

  CourseModel.fromJson(Map<String, dynamic> json) {
    var data = json['data'];
    id = json['id'] ?? '';
    courseName = data['course_name'] ?? '';
    levelId = data['level_id'] ?? '';
    subjectId = data['subject_id'] ?? '';
    thumbnailUrl = data['thumbnail_url'] ?? '';
    recommendText = data['recommend_text'] ?? '';
    detailsText = data['details_text'] ?? '';
    tutorId = data['tutor_id'] ?? '';
    if (data['document'] != null) {
      document = DocumentModel(
          id: data['document_id'], data: Data.fromJson(data['document']));
    }
    documentId = data['document_id'] ?? '';
    documentCount = data['document_count'] ?? 0;
    if (data['lessons'] != null) {
      lessons = <Lessons>[];
      data['lessons'].forEach((v) {
        lessons?.add(Lessons.fromJson(v));
      });
    }
    createTime = DateTime.fromMillisecondsSinceEpoch(data['create_time']);
    updateTime = DateTime.fromMillisecondsSinceEpoch(data['update_time']);
    if (data['calendar'] != null) {
      calendars = <CalendarDate>[];
      data['calendar'].forEach((v) {
        calendars?.add(CalendarDate.fromJson(v));
      });
    }
    if (data['student_list'] != null) {
      studentIds = <String>[];
      data['student_list'].forEach((v) {
        studentIds?.add(v);
      });
    }
    if (data['student_details'] != null) {
      studentDetails = <StudentModel>[];
      data['student_details'].forEach((v) {
        studentDetails?.add(StudentModel.fromJson(v));
      });
    }

    if (data['first_day'] != null) {
      firstDay = DateTime.fromMillisecondsSinceEpoch(
          data['first_day'] ?? DateTime.now());
    } else {
      firstDay = DateTime.now();
    }

    if (data['last_day'] != null) {
      lastDay = DateTime.fromMillisecondsSinceEpoch(data['last_day']);
    } else {
      lastDay = DateTime.now();
    }
    publishing = data['publishing'] ?? false;
    courseType = data['course_type'] ?? '';
    price = data['price'] ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['course_name'] = courseName;
    data['level_id'] = levelId;
    data['subject_id'] = subjectId;
    data['thumbnail_url'] = thumbnailUrl;
    data['recommend_text'] = recommendText;
    data['details_text'] = detailsText;
    data['tutor_id'] = tutorId;
    data['document_id'] = documentId;
    if (lessons != null) {
      data['lessons'] = lessons!.map((v) => v.toJson()).toList();
    }
    if (studentIds != null) {
      data['student_list'] = studentIds!.map((v) => v).toList();
    }
    if (studentDetails != null) {
      data['student_details'] = studentDetails!.map((v) => v.toJson()).toList();
    }
    if (calendars != null) {
      data['calendar'] = calendars!.map((v) => v.toJson()).toList();
    }
    data['first_day'] = firstDay?.toUtc().millisecondsSinceEpoch;
    data['last_day'] = lastDay?.toUtc().millisecondsSinceEpoch;
    data['publishing'] = false;
    data['course_type'] = courseType;
    data['price'] = price;
    return data;
  }
}

class Lessons {
  int? lessonId;
  String? lessonName;
  String? media;
  bool? isExpanded = false;
  Lessons({
    this.lessonId,
    this.lessonName,
    this.media,
    this.isExpanded,
  });

  Lessons.fromJson(Map<String, dynamic> json) {
    lessonId = json['lesson_id'] ?? '';
    lessonName = json['lesson_name'] ?? '';
    media = json['media'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['lesson_id'] = lessonId;
    data['lesson_name'] = lessonName;
    data['media'] = media;

    return data;
  }
}

class CalendarDate {
  DateTime? start;
  DateTime? end;
  String? courseName;
  String? courseId;
  String? reviewFile;
  List<dynamic>? audioFile;
  DateTime? actualStart;
  DateTime? actualEnd;
  int? liveDuration;
  String? meetingId;

  CalendarDate(
      {this.start, this.end, this.courseName, this.courseId, this.reviewFile, this.audioFile, this.actualStart, this.actualEnd, this.liveDuration, this.meetingId});

  CalendarDate.fromJson(Map<String, dynamic> json) {
    start = DateTime.fromMillisecondsSinceEpoch(json['start']);
    end = DateTime.fromMillisecondsSinceEpoch(json['end']);
    courseName = json['course_name'] ?? '';
    courseId = json['course_id'] ?? '';
    reviewFile = json['review_file'] ?? '';
    if (json['audio_file'] != null) {
      audioFile = <String>[];
      json['audio_file'].forEach((v) {
        audioFile?.add(v);
      });
    }
    actualStart =
        DateTime.fromMillisecondsSinceEpoch(json['actual_start'] ?? 0);
    actualEnd = DateTime.fromMillisecondsSinceEpoch(json['actual_end'] ?? 0);
    liveDuration = json['live_duration'] ?? 0;
    meetingId = json['meeting_id'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['start'] = start?.toUtc().millisecondsSinceEpoch;
    data['end'] = end?.toUtc().millisecondsSinceEpoch;
    data['course_name'] = courseName;
    data['course_id'] = courseId;
    data['review_file'] = reviewFile;
    if (audioFile != null) {
      data['audio_file'] = audioFile!.map((v) => v).toList();
    }
    data['actual_start'] = actualStart?.toUtc().millisecondsSinceEpoch;
    data['actual_end'] = actualEnd?.toUtc().millisecondsSinceEpoch;
    data['live_duration'] = liveDuration;
    data['meeting_id'] = meetingId;
    return data;
  }
}
