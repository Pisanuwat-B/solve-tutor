import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

import 'package:solve_tutor/feature/audio/group_call_page.dart';

class HomeAudioPage extends StatefulWidget {
  @override
  _HomeAudioPageState createState() => _HomeAudioPageState();
}

class _HomeAudioPageState extends State<HomeAudioPage> {
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
                  width: MediaQuery.of(context).size.width * 0.25,
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
                )
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

    // var route = MaterialPageRoute(
    //   builder: (context) => CallPage(channelName: ''),
    // );
    var route = MaterialPageRoute(
      builder: (context) => GroupCallPage(),
    );
    // var route = MaterialPageRoute(
    //   builder: (context) => JoinChannelAudio(),
    // );
    Navigator.push(context, route);
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }
}
