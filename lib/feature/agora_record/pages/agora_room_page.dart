import 'dart:developer';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_rtc_engine/src/audio_device_manager.dart' as audio;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/feature/agora_record/controller/agora_controller.dart';
import 'package:solve_tutor/feature/agora_record/until.dart';

class AgoraRoomPage extends StatefulWidget {
  AgoraRoomPage(
      {super.key,
      required this.token,
      required this.channel,
      required this.uid});
  String token;
  String channel;
  String uid;
  @override
  State<AgoraRoomPage> createState() => _AgoraRoomPageState();
}

class _AgoraRoomPageState extends State<AgoraRoomPage> {
  AgoraController? controller;

  @override
  void initState() {
    super.initState();
    controller = AgoraController(
      context,
      token: widget.token,
      channel: widget.channel,
      uid: widget.uid,
    );
    controller!.init();
  }

  @override
  void dispose() {
    super.dispose();
    controller!.dis();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Consumer<AgoraController>(builder: (context, con, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('channel : ${widget.channel}'),
          ),
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              _userList(con),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${widget.channel}\n",
                      style: TextStyle(color: Colors.green),
                    ),
                    Text(
                      "${widget.uid}\n",
                      style: TextStyle(color: Colors.green),
                    ),
                    Text(
                      "${widget.token}\n",
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomSheet: _toolbar(con),
        );
      }),
    );
  }

  /// Helper function to get list of native views
  List<Widget> _getRenderViews(AgoraController con) {
    final List<StatefulWidget> list = [];
    list.add(AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: con.rtcEngine!,
        canvas: const VideoCanvas(uid: 0),
      ),
    ));
    con.usersIn.forEach((int uid) => list.add(AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: con.rtcEngine!,
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

  Widget _userList(AgoraController con) {
    if (con.rtcEngine != null) {
      final views = _getRenderViews(con);
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

  Widget _viewRows(AgoraController con) {
    final views = _getRenderViews(con);
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

  Widget _toolbar(AgoraController con) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RawMaterialButton(
                onPressed: con.onToggleMute,
                child: Icon(
                  con.muted ? Icons.mic_off : Icons.mic,
                  color: con.muted ? Colors.white : Colors.blueAccent,
                  size: 20.0,
                ),
                shape: CircleBorder(),
                elevation: 2.0,
                fillColor: con.muted ? Colors.blueAccent : Colors.white,
                padding: const EdgeInsets.all(12.0),
              ),
              RawMaterialButton(
                onPressed: () => con.onCallEnd(context),
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
            ],
          ),
        ],
      ),
    );
  }
}
