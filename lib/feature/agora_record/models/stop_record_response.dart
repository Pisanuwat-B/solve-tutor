// To parse this JSON data, do
//
//     final stopRecordResponse = stopRecordResponseFromJson(jsonString);

import 'dart:convert';

StopRecordResponse stopRecordResponseFromJson(String str) =>
    StopRecordResponse.fromJson(json.decode(str));

String stopRecordResponseToJson(StopRecordResponse data) =>
    json.encode(data.toJson());

class StopRecordResponse {
  String? cname;
  String? uid;
  String? resourceId;
  String? sid;
  ServerResponse? serverResponse;

  StopRecordResponse({
    this.cname,
    this.uid,
    this.resourceId,
    this.sid,
    this.serverResponse,
  });

  factory StopRecordResponse.fromJson(Map<String, dynamic> json) =>
      StopRecordResponse(
        cname: json["cname"],
        uid: json["uid"],
        resourceId: json["resourceId"],
        sid: json["sid"],
        serverResponse: json["serverResponse"] == null
            ? null
            : ServerResponse.fromJson(json["serverResponse"]),
      );

  Map<String, dynamic> toJson() => {
        "cname": cname,
        "uid": uid,
        "resourceId": resourceId,
        "sid": sid,
        "serverResponse": serverResponse?.toJson(),
      };
}

class ServerResponse {
  String? fileListMode;
  List<FileList>? fileList;
  String? uploadingStatus;

  ServerResponse({
    this.fileListMode,
    this.fileList,
    this.uploadingStatus,
  });

  factory ServerResponse.fromJson(Map<String, dynamic> json) => ServerResponse(
        fileListMode: json["fileListMode"],
        fileList: json["fileList"] == null
            ? []
            : List<FileList>.from(
                json["fileList"]!.map((x) => FileList.fromJson(x))),
        uploadingStatus: json["uploadingStatus"],
      );

  Map<String, dynamic> toJson() => {
        "fileListMode": fileListMode,
        "fileList": fileList == null
            ? []
            : List<dynamic>.from(fileList!.map((x) => x.toJson())),
        "uploadingStatus": uploadingStatus,
      };
}

class FileList {
  String? fileName;
  bool? isPlayable;
  bool? mixedAllUser;
  int? sliceStartTime;
  String? trackType;
  String? uid;

  FileList({
    this.fileName,
    this.isPlayable,
    this.mixedAllUser,
    this.sliceStartTime,
    this.trackType,
    this.uid,
  });

  factory FileList.fromJson(Map<String, dynamic> json) => FileList(
        fileName: json["fileName"],
        isPlayable: json["isPlayable"],
        mixedAllUser: json["mixedAllUser"],
        sliceStartTime: json["sliceStartTime"],
        trackType: json["trackType"],
        uid: json["uid"],
      );

  Map<String, dynamic> toJson() => {
        "fileName": fileName,
        "isPlayable": isPlayable,
        "mixedAllUser": mixedAllUser,
        "sliceStartTime": sliceStartTime,
        "trackType": trackType,
        "uid": uid,
      };
}
