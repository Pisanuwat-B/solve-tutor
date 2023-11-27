import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:solve_tutor/feature/agora_record/until.dart';

class AgoraAPI {
  String credentials = "$customerID:$customerSecret";
  Codec<String, String> stringToBase64 = utf8.fuse(base64);
  String uid = "0000"; // uid สำหรับ record ห้ามซ้ำกับ uid user
  Future<http.Response> recordAcquire({
    required String cname,
  }) async {
    String url = '$endPointAPI/$appId/cloud_recording/acquire';
    var header = {
      'Content-Type': 'application/json',
      'Authorization': "Basic ${stringToBase64.encode(credentials)}",
    };
    var body = json.encode({
      "cname": cname,
      "uid": uid,
      "clientRequest": {},
    }).toString();
    log("url: $url");
    log("header: $header");
    log("body: $body");
    return http.post(Uri.parse(url), headers: header, body: body);
  }

  Future<http.Response> recordStart({
    required String resourceId,
    required String cname,
    required String token,
    String? region,
    String? vendor,
    String? bucket,
    String? accessKey,
    String? secretKey,
    List<String>? fileNamePrefix,
  }) async {
    String url =
        '$endPointAPI/$appId/cloud_recording/resourceid/$resourceId/mode/$modeType/start';
    var header = {
      'Content-Type': 'application/json',
      'Authorization': "Basic ${stringToBase64.encode(credentials)}",
    };
    var body = json.encode({
      "cname": cname,
      "uid": uid,
      "clientRequest": {
        "token": token,
        "recordingConfig": {
          "channelType": 0,
          "streamTypes": 2,
          "videoStreamType": 0,
          "streamMode":
              "standard", //remove before running or it won't work. Standard mode creates a MPD with WebM, removing steamMode creates M3U8 with TS
          "maxIdleTime": 120,
          "subscribeVideoUids": ["#allstream#"],
          "subscribeAudioUids": ["#allstream#"],
          "subscribeUidGroup": 0
        },
        "storageConfig": {
          "region": region ?? 0,
          "bucket": bucket ?? googleCloudBusket,
          "vendor": vendor ?? 6, // default google
          "accessKey": accessKey ?? googleCloudAccessKey,
          "secretKey": secretKey ?? googleCloudSecretKey,
          "fileNamePrefix": ["agora", cname],
        }
      }
    }).toString();
    log("url: $url");
    log("header: $header");
    log("body: $body");
    return http.post(Uri.parse(url), headers: header, body: body);
  }

  Future<http.Response> recordStop({
    required String sid,
    required String resourceId,
    required String cname,
  }) async {
    String url =
        '$endPointAPI/$appId/cloud_recording/resourceid/$resourceId/sid/$sid/mode/$modeType/stop';
    var header = {
      'Content-Type': 'application/json',
      'Authorization': "Basic ${stringToBase64.encode(credentials)}",
    };
    var body = json.encode({
      "cname": cname,
      "uid": uid,
      "clientRequest": {},
    }).toString();
    log("url: $url");
    log("header: $header");
    log("body: $body");
    return http.post(Uri.parse(url), headers: header, body: body);
  }

  Future<http.Response> genToken({
    required String uid,
    required String cname,
  }) async {
    String url = 'http://127.0.0.1:8080/rtc/$cname/publisher/uid/$uid/';
    var header = {
      'Content-Type': 'application/json',
    };
    log("url: $url");
    log("header: $header");
    return http.get(Uri.parse(url), headers: header);
  }
}
