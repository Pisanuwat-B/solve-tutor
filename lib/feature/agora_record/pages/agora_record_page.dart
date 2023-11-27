import 'dart:developer';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_rtc_engine/src/audio_device_manager.dart' as audio;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/feature/agora_record/controller/agora_controller.dart';
import 'package:solve_tutor/feature/agora_record/until.dart';

class AgoraRecordPage extends StatefulWidget {
  AgoraRecordPage(
      {super.key,
      required this.token,
      required this.channel,
      required this.uid});
  String token;
  String channel;
  String uid;
  @override
  State<AgoraRecordPage> createState() => _AgoraRoomPageState();
}

class _AgoraRoomPageState extends State<AgoraRecordPage> {
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
  }

  @override
  void dispose() {
    super.dispose();
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
          bottomSheet: _toolbar(con),
        );
      }),
    );
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
                onPressed: () {
                  if (!con.recordStart) {
                    con.startRecord();
                  } else {
                    log("recorded");
                  }
                },
                shape: const CircleBorder(),
                elevation: 2.0,
                fillColor: con.recordStart ? Colors.white : Colors.blueAccent,
                padding: const EdgeInsets.all(12.0),
                child: Icon(
                  Icons.record_voice_over,
                  color: con.recordStart ? Colors.grey : Colors.white,
                ),
              ),
              RawMaterialButton(
                onPressed: () {
                  if (con.recordStart) {
                    con.stopRecord();
                  } else {
                    log("no record");
                  }
                },
                shape: const CircleBorder(),
                elevation: 2.0,
                fillColor: !con.recordStart ? Colors.white : Colors.red,
                padding: const EdgeInsets.all(12.0),
                child: Icon(
                  Icons.record_voice_over,
                  color: !con.recordStart ? Colors.grey : Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
