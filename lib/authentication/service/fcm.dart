import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FCM {
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  final dataCtrl = StreamController.broadcast();
  final tittleCtrl = StreamController.broadcast();
  final bodyCtrl = StreamController.broadcast();

  setNotification(BuildContext context) async {
    NotificationSettings settings = await firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (context.mounted) {
        foregroundNotification(context);
        backgroundNotification(context);
        terminateNotification(context);
      }
    }
    final token =
        firebaseMessaging.getToken().then((value) => log("FCM Token : $value"));
  }

  //ระหว่างเปิดแอป
  foregroundNotification(BuildContext context) {
    FirebaseMessaging.onMessage.listen((message) {
      log("Foreground-Noti: ${message.notification?.body}");
      if (Platform.isIOS) {
        log("IOS-noti");
      } else {
        log("Android-noti");
      }
    });
  }

  //ปิดแอป แต่ไม่เคลียร์แอป
  backgroundNotification(BuildContext context) {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      log("Background-Noti: ${message.notification?.body}");
    });
  }

  //ปิดแอปแล้วเปิดมาใหม่
  terminateNotification(BuildContext context) async {
    log("Terminate-Noti:");
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      log("Terminate-Noti: $initialMessage");
    }
  }

  /// TODO: check this dispose
  @override
  void dispose() {
    dataCtrl.close();
    tittleCtrl.close();
    bodyCtrl.close();
  }
}
