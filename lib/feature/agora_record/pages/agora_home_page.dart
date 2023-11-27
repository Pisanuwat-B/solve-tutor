import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

import 'package:solve_tutor/feature/agora_record/pages/agora_record_page.dart';
import 'package:solve_tutor/feature/agora_record/pages/agora_room_page.dart';

class AgoraHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<AgoraHomePage> {
  String? channel;
  String? uid;
  String? token;

  setRoom() async {
    channel = "channel32";
    uid = "0";
    token =
        "007eJxSYDjEbd14NtZkYZBTn761kcp5qcNyxyxXBzz4/+PR2zhhrmQFhpQko+Q0c4PkZFNTE5MkQ6NEs6RkI3PLxKTEVCMTyySj2EkpqQJ8DAx1WU1MjAyMDCwMjAwgPhOYZAaTLGCSkyE5IzEvLzXH2IiBARAAAP//fCsfQw==";
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Agora Group Video Calling'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            physics: BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(padding: EdgeInsets.symmetric(vertical: 30)),
                Container(
                  width: 200,
                  child: MaterialButton(
                    onPressed: onJoin,
                    height: 40,
                    color: Colors.blueAccent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Join',
                          style: TextStyle(color: Colors.white),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  width: 200,
                  child: MaterialButton(
                    onPressed: onRecord,
                    height: 40,
                    color: Colors.blueAccent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Test only record',
                          style: TextStyle(color: Colors.white),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> onJoin() async {
    // await _handleCameraAndMic(Permission.camera);
    await _handleCameraAndMic(Permission.microphone);
    await setRoom();
    log("token : $token");
    var route = MaterialPageRoute(
      builder: (context) => AgoraRoomPage(
        token: token!,
        channel: channel!,
        uid: uid!,
      ),
    );
    Navigator.push(context, route);
  }

  Future<void> onRecord() async {
    // await _handleCameraAndMic(Permission.camera);
    await _handleCameraAndMic(Permission.microphone);
    await setRoom();
    log("token : $token");
    var route = MaterialPageRoute(
      builder: (context) => AgoraRecordPage(
        token: token!,
        channel: channel!,
        uid: uid!,
      ),
    );
    Navigator.push(context, route);
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }
}
