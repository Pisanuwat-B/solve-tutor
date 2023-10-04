// To parse this JSON data, do
//
//     final orderMockModel = orderMockModelFromJson(jsonString);

import 'dart:convert';

OrderCourseModel orderMockModelFromJson(String str) =>
    OrderCourseModel.fromJson(json.decode(str));

String orderMockModelToJson(OrderCourseModel data) =>
    json.encode(data.toJson());

class OrderCourseModel {
  String? id;
  String? tutorId;
  String? studentId;
  String? classId;
  String? refId;
  String? title;
  String? content;
  int? type;
  String? chatId;
  String? path;
  String? image;
  num? rate;
  bool paymentOn;
  String? paymentStatus;
  String? paymentBy;
  DateTime? paymentTime;
  DateTime? createdTime;
  bool fromMarketPlace;
  bool fromAnnounce;

  OrderCourseModel({
    this.id,
    this.tutorId,
    this.studentId,
    this.classId,
    this.refId,
    this.title,
    this.content,
    this.type,
    this.chatId,
    this.path,
    this.image,
    this.rate,
    this.paymentOn = false,
    this.paymentStatus,
    this.paymentBy,
    this.paymentTime,
    this.createdTime,
    this.fromMarketPlace = false,
    this.fromAnnounce = false,
  });

  factory OrderCourseModel.fromJson(Map<String, dynamic> json) =>
      OrderCourseModel(
        id: json["id"],
        tutorId: json["tutorId"],
        studentId: json["studentId"],
        classId: json["classId"],
        refId: json["refId"],
        title: json["title"],
        content: json["content"],
        type: json["type"],
        chatId: json["chatId"],
        path: json["path"],
        image: json["image"],
        rate: json["rate"],
        paymentOn: json["paymentOn"] ?? false,
        paymentStatus: json["paymentStatus"],
        paymentBy: json["paymentBy"],
        paymentTime: json["payment_time"] == null
            ? null
            : DateTime.fromMicrosecondsSinceEpoch(json["payment_time"]),
        createdTime: json["created_time"] == null
            ? null
            : DateTime.fromMicrosecondsSinceEpoch(json["created_time"]),
        fromMarketPlace: json["fromMarketPlace"] ?? false,
        fromAnnounce: json["fromAnnounce"] ?? false,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "tutorId": tutorId,
        "studentId": studentId,
        "classId": classId,
        "refId": refId,
        "title": title,
        "content": content,
        "type": type,
        "chatId": chatId,
        "path": path,
        "image": image,
        "rate": rate,
        "paymentOn": paymentOn,
        "paymentStatus": paymentStatus,
        'paymentBy': paymentBy,
        'payment_time': paymentTime?.millisecondsSinceEpoch,
        'created_time': createdTime?.millisecondsSinceEpoch,
        "fromMarketPlace": fromMarketPlace,
        "fromAnnounce": fromAnnounce,
      };
}
