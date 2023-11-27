// To parse this JSON data, do
//
//     final acquireResponse = acquireResponseFromJson(jsonString);

import 'dart:convert';

AcquireResponse acquireResponseFromJson(String str) =>
    AcquireResponse.fromJson(json.decode(str));

String acquireResponseToJson(AcquireResponse data) =>
    json.encode(data.toJson());

class AcquireResponse {
  String? cname;
  String? uid;
  String? resourceId;

  AcquireResponse({
    this.cname,
    this.uid,
    this.resourceId,
  });

  factory AcquireResponse.fromJson(Map<String, dynamic> json) =>
      AcquireResponse(
        cname: json["cname"],
        uid: json["uid"],
        resourceId: json["resourceId"],
      );

  Map<String, dynamic> toJson() => {
        "cname": cname,
        "uid": uid,
        "resourceId": resourceId,
      };
}
