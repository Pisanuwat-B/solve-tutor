import 'dart:developer';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:solve_tutor/feature/audio/until.dart';

class GroupCallPage extends StatefulWidget {
  const GroupCallPage({super.key});

  @override
  State<GroupCallPage> createState() => _GroupCallPageState();
}

class _GroupCallPageState extends State<GroupCallPage> {
  static final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted = false;
  RtcEngine? _engine;

  // Future<void> initialize() async {
  //   try {
  //     if (appId.isEmpty) {
  //       setState(() {
  //         _infoStrings.add(
  //           'APP_ID missing, please provide your APP_ID in settings.dart',
  //         );
  //         _infoStrings.add('Agora Engine is not starting');
  //       });
  //       return;
  //     }
  //     await _initAgoraRtcEngine();
  //     _addAgoraEventHandlers();
  //     await _engine!.joinChannel(
  //       token: token,
  //       channelId: channel,
  //       uid: 0,
  //       options: const ChannelMediaOptions(),
  //     );
  //     log("message1");
  //   } catch (e) {
  //     log("message : $e");
  //   }
  // }

  // Future<void> _initAgoraRtcEngine() async {
  //   _engine = createAgoraRtcEngine();
  //   await _engine!.enableVideo();
  // }

  // void _addAgoraEventHandlers() {
  //   _engine!.registerEventHandler(
  //     RtcEngineEventHandler(
  //       onError: (err, msg) {
  //         debugPrint("error $msg");
  //       },
  //       onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
  //         debugPrint("local user ${connection.localUid} joined");
  //         setState(() {
  //           final info = 'onJoinChannel: $channel, uid: ${connection.localUid}';
  //           _infoStrings.add(info);
  //         });
  //       },
  //       onLeaveChannel: (connection, stats) {},
  //       onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
  //         debugPrint("remote user $remoteUid joined");
  //         setState(() {
  //           final info = 'userJoined: ${remoteUid}';
  //           _infoStrings.add(info);
  //           _users.add(remoteUid);
  //         });
  //       },
  //       onUserOffline: (RtcConnection connection, int remoteUid,
  //           UserOfflineReasonType reason) {
  //         debugPrint("remote user $remoteUid left channel");
  //         setState(() {
  //           final info = 'userOffline: $remoteUid , reason: $reason';
  //           _infoStrings.add(info);
  //           _users.remove(remoteUid);
  //         });
  //       },
  //       onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
  //         debugPrint(
  //             '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
  //       },
  //       onFirstRemoteVideoFrame:
  //           (connection, remoteUid, width, height, elapsed) {
  //         setState(() {
  //           final info = 'firstRemoteVideoFrame: ${remoteUid}';
  //           _infoStrings.add(info);
  //         });
  //       },
  //     ),
  //   );
  //   // _engine.setEventHandler(RtcEngineEventHandler(
  //   //   error: (code) {
  //   //     setState(() {
  //   //       final info = 'onError: $code';
  //   //       _infoStrings.add(info);
  //   //     });
  //   //   },
  //   //   joinChannelSuccess: (channel, uid, elapsed) {
  //   //     setState(() {
  //   //       final info = 'onJoinChannel: $channel, uid: $uid';
  //   //       _infoStrings.add(info);
  //   //     });
  //   //   },
  //   //   leaveChannel: (stats) {
  //   //     setState(() {
  //   //       _infoStrings.add('onLeaveChannel');
  //   //       _users.clear();
  //   //     });
  //   //   },
  //   //   userJoined: (uid, elapsed) {
  //   //     setState(() {
  //   //       final info = 'userJoined: $uid';
  //   //       _infoStrings.add(info);
  //   //       _users.add(uid);
  //   //     });
  //   //   },
  //   //   userOffline: (uid, reason) {
  //   //     setState(() {
  //   //       final info = 'userOffline: $uid , reason: $reason';
  //   //       _infoStrings.add(info);
  //   //       _users.remove(uid);
  //   //     });
  //   //   },
  //   //   firstRemoteVideoFrame: (uid, width, height, elapsed) {
  //   //     setState(() {
  //   //       final info = 'firstRemoteVideoFrame: $uid';
  //   //       _infoStrings.add(info);
  //   //     });
  //   //   },
  //   // ));
  // }

  Future<void> initAgora() async {
    try {
      // retrieve permissions
      await [Permission.microphone].request();
      //create the engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onError: (err, msg) {
            debugPrint("error $msg");
          },
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("local user ${connection.localUid} joined");
            setState(() {
              final info =
                  'onJoinChannel: $channel, uid: ${connection.localUid}';
              _infoStrings.add(info);
            });
          },
          onLeaveChannel: (connection, stats) {},
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint("remote user $remoteUid joined");
            setState(() {
              final info = 'userJoined: ${remoteUid}';
              _infoStrings.add(info);
              _users.add(remoteUid);
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            debugPrint("remote user $remoteUid left channel");
            setState(() {
              final info = 'userOffline: $remoteUid , reason: $reason';
              _infoStrings.add(info);
              _users.remove(remoteUid);
            });
          },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
            debugPrint(
                '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
          },
          onFirstRemoteVideoFrame:
              (connection, remoteUid, width, height, elapsed) {
            setState(() {
              final info = 'firstRemoteVideoFrame: ${remoteUid}';
              _infoStrings.add(info);
            });
          },
        ),
      );

      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.enableVideo();
      await _engine!.startPreview();
      await _engine!.joinChannel(
        token: token,
        channelId: channel,
        uid: 0,
        options: const ChannelMediaOptions(),
      );
      await _engine!.startAudioRecording(
        AudioRecordingConfiguration(
          filePath: "class_1",
          encode: false,
          sampleRate: 32000,
          fileRecordingType: AudioFileRecordingType.audioFileRecordingMixed,
          quality: AudioRecordingQualityType.audioRecordingQualityMedium,
          recordingChannel: 1,
        ),
      );
    } catch (e) {
      log("error : $e");
    }
  }

  @override
  void dispose() {
    // clear users
    _users.clear();
    // destroy sdk
    _engine!.stopAudioRecording();
    _engine!.leaveChannel();
    _engine!.release();
    // _engine.destroy();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // initialize agora sdk
    // initialize();
    initAgora();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agora Group Video Calling'),
      ),
      backgroundColor: Colors.black,
      body: _userList(),
      // body: Center(
      //   child: Stack(
      //     children: <Widget>[
      //       _viewRows(),
      //       _toolbar(),
      //     ],
      //   ),
      // ),
    );
  }

  /// Helper function to get list of native views
  List<Widget> _getRenderViews() {
    final List<StatefulWidget> list = [];
    list.add(AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine!,
        canvas: const VideoCanvas(uid: 0),
      ),
    ));
    _users.forEach((int uid) => list.add(AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: _engine!,
            canvas: VideoCanvas(uid: uid),
          ),
        )));
    return list;
  }

  /// Video view wrapper
  Widget _videoView(view) {
    return Expanded(child: Container(child: view));
  }

  /// Video view row wrapper
  Widget _expandedVideoRow(List<Widget> views) {
    final wrappedViews = views.map<Widget>(_videoView).toList();
    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  Widget _userList() {
    if (_engine != null) {
      final views = _getRenderViews();
      return Container(
        height: 100,
        child: ListView.builder(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemCount: views.length,
            itemBuilder: (context, index) {
              return Container(
                height: 70,
                width: 70,
                margin: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_circle,
                  color: Colors.green,
                ),
              );
            }),
      );
    }
    return Container();
  }

  Widget _viewRows() {
    final views = _getRenderViews();
    switch (views.length) {
      case 1:
        return Container(
            child: Column(
          children: <Widget>[_videoView(views[0])],
        ));
      case 2:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow([views[0]]),
            _expandedVideoRow([views[1]])
          ],
        ));
      case 3:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow(views.sublist(0, 2)),
            _expandedVideoRow(views.sublist(2, 3))
          ],
        ));
      case 4:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow(views.sublist(0, 2)),
            _expandedVideoRow(views.sublist(2, 4))
          ],
        ));
      default:
    }
    return Container();
  }

  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: _onToggleMute,
            child: Icon(
              muted ? Icons.mic_off : Icons.mic,
              color: muted ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: muted ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(12.0),
          ),
          RawMaterialButton(
            onPressed: () => _onCallEnd(context),
            child: Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
          ),
          // RawMaterialButton(
          //   onPressed: _onSwitchCamera,
          //   child: Icon(
          //     Icons.switch_camera,
          //     color: Colors.blueAccent,
          //     size: 20.0,
          //   ),
          //   shape: CircleBorder(),
          //   elevation: 2.0,
          //   fillColor: Colors.white,
          //   padding: const EdgeInsets.all(12.0),
          // )
        ],
      ),
    );
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine!.muteLocalAudioStream(muted);
  }

  void _onCallEnd(BuildContext context) {
    Navigator.pop(context);
  }
}
