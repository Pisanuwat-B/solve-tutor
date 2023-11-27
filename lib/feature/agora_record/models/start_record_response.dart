// To parse this JSON data, do
//
//     final startRecordResponse = startRecordResponseFromJson(jsonString);

import 'dart:convert';

StartRecordResponse startRecordResponseFromJson(String str) =>
    StartRecordResponse.fromJson(json.decode(str));

String startRecordResponseToJson(StartRecordResponse data) =>
    json.encode(data.toJson());

class StartRecordResponse {
  String? cname;
  String? uid;
  String? resourceId;
  String? sid;

  StartRecordResponse({
    this.cname,
    this.uid,
    this.resourceId,
    this.sid,
  });

  factory StartRecordResponse.fromJson(Map<String, dynamic> json) =>
      StartRecordResponse(
        cname: json["cname"],
        uid: json["uid"],
        resourceId: json["resourceId"],
        sid: json["sid"],
      );

  Map<String, dynamic> toJson() => {
        "cname": cname,
        "uid": uid,
        "resourceId": resourceId,
        "sid": sid,
      };
}
