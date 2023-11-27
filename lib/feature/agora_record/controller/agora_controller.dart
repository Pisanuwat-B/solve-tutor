import 'dart:convert';
import 'dart:developer';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:solve_tutor/feature/agora_record/models/acquire_reponse.dart';
import 'package:solve_tutor/feature/agora_record/models/start_record_response.dart';
import 'package:solve_tutor/feature/agora_record/models/stop_record_response.dart';
import 'package:solve_tutor/feature/agora_record/service/agora_api.dart';
import 'package:solve_tutor/feature/agora_record/until.dart';

class AgoraController extends ChangeNotifier {
  AgoraController(
    this.context, {
    required this.token,
    required this.channel,
    required this.uid,
  });
  BuildContext context;
  String token;
  String channel;
  String uid;

  List<int> usersIn = [];
  List<String> _infoStrings = [];
  bool muted = false;
  RtcEngine? rtcEngine;

  StartRecordResponse? startRecordResponse;
  StopRecordResponse? stopRecordResponse;
  bool recordStart = false;
  init() async {
    initAgora();
    notifyListeners();
  }

  dis() {
    // clear users
    usersIn.clear();
    // destroy sdk
    rtcEngine!.leaveChannel();
    rtcEngine!.release();
  }

  Future<void> initAgora() async {
    try {
      // retrieve permissions
      await [Permission.microphone].request();
      //create the engine
      rtcEngine = createAgoraRtcEngine();
      await rtcEngine!.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));
      rtcEngine!.registerEventHandler(
        RtcEngineEventHandler(
          onError: (err, msg) {
            debugPrint("error $msg");
          },
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("local user ${connection.localUid} joined");
            final info = 'onJoinChannel: $channel, uid: ${connection.localUid}';
            _infoStrings.add(info);
            notifyListeners();
          },
          onLeaveChannel: (connection, stats) {},
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint("remote user $remoteUid joined");
            final info = 'userJoined: $remoteUid';
            _infoStrings.add(info);
            usersIn.add(remoteUid);
            notifyListeners();
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            debugPrint("remote user $remoteUid left channel");
            final info = 'userOffline: $remoteUid , reason: $reason';
            _infoStrings.add(info);
            usersIn.remove(remoteUid);
            notifyListeners();
          },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
            debugPrint(
                '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
          },
          onFirstRemoteVideoFrame:
              (connection, remoteUid, width, height, elapsed) {
            final info = 'firstRemoteVideoFrame: $remoteUid';
            _infoStrings.add(info);
            notifyListeners();
          },
        ),
      );

      await rtcEngine!
          .setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      // await rtcEngine!.enableVideo();
      await rtcEngine!.startPreview();
      await rtcEngine!.joinChannel(
        token: token,
        channelId: channel,
        uid: int.parse(uid),
        options: const ChannelMediaOptions(),
      );
      notifyListeners();
    } catch (e) {
      log("error : $e");
    }
  }

  startRecord() async {
    AcquireResponse? acquireResponse = await callRecordAcquire(channel);
    if (acquireResponse != null) {
      startRecordResponse =
          await callRecordStart(acquire: acquireResponse, channelToken: token);
      recordStart = true;
      notifyListeners();
    }
  }

  stopRecord() async {
    stopRecordResponse = await callRecordStop(
      start: startRecordResponse!,
      channelToken: channel,
    );
    recordStart = false;
    notifyListeners();
  }

  Future<AcquireResponse?> callRecordAcquire(String channelName) async {
    try {
      var source = await AgoraAPI().recordAcquire(cname: channelName);
      if (source.statusCode == 200) {
        var rs = json.decode(source.body);
        log("rs : $rs");
        AcquireResponse res = AcquireResponse.fromJson(rs);
        return res;
      } else {
        var rs = json.decode(source.body);
        log("rs : $rs");
        throw "Connection error :${source.statusCode}";
      }
    } catch (e) {
      log("Acquire err : $e");
      return null;
    }
  }

  Future<StartRecordResponse?> callRecordStart({
    required AcquireResponse acquire,
    required String channelToken,
  }) async {
    try {
      log("in callRecordStart");
      var source = await AgoraAPI().recordStart(
        resourceId: acquire.resourceId ?? "",
        cname: acquire.cname ?? "",
        token: channelToken,
      );
      log("in callRecordStart 2");
      if (source.statusCode == 200) {
        var rs = json.decode(source.body);
        log("rs : $rs");
        StartRecordResponse res = StartRecordResponse.fromJson(rs);
        return res;
      } else {
        var rs = json.decode(source.body);
        log("rs : $rs");
        throw "Connection error :${source.statusCode}";
      }
    } catch (e) {
      log("Start err : $e");
      return null;
    }
  }

  Future<StopRecordResponse?> callRecordStop({
    required StartRecordResponse start,
    required String channelToken,
  }) async {
    try {
      var source = await AgoraAPI().recordStop(
        sid: start.sid ?? "",
        resourceId: start.resourceId ?? "",
        cname: start.cname ?? "",
      );
      if (source.statusCode == 200) {
        var rs = json.decode(source.body);
        log("rs : $rs");
        StopRecordResponse res = StopRecordResponse.fromJson(rs);
        return res;
      } else {
        var rs = json.decode(source.body);
        log("rs : $rs");
        throw "Connection error :${source.statusCode}";
      }
    } catch (e) {
      log("Stop err : $e");
      return null;
    }
  }

  void onToggleMute() {
    muted = !muted;
    notifyListeners();
    rtcEngine!.muteLocalAudioStream(muted);
  }

  void onCallEnd(BuildContext context) {
    Navigator.pop(context);
  }
}
