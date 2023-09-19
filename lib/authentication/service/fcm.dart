import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../main.dart';

class FCMServices {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AndroidNotificationChannel _androidChannel =
      const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.max,
  );

  final dataCtrl = StreamController.broadcast();
  final tittleCtrl = StreamController.broadcast();
  final bodyCtrl = StreamController.broadcast();

  // initial push notification
  Future<void> initializeService() async {
    const androidInitializationSetting =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInitializationSetting = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
        android: androidInitializationSetting, iOS: iosInitializationSetting);
    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    // receive notification
    foregroundNotification();
    resumeNotification();
    terminateNotification();
  }

  showNotification(RemoteMessage message) {
    print("showNotification: ${message.notification!.title}");
    final randomId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    const iosNotificationDetail = DarwinNotificationDetails();
    NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
          _androidChannel.id, _androidChannel.name,
          importance: Importance.max, priority: Priority.high),
      iOS: iosNotificationDetail,
    );
    _flutterLocalNotificationsPlugin.show(randomId, message.notification!.title,
        message.notification!.body, notificationDetails);
  }

  Future<void> requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
      final bool? granted = await androidImplementation?.requestPermission();
      print("settings noti: ${granted}");
    }
  }
  //ระหว่างเปิดแอป
  foregroundNotification() {
    FirebaseMessaging.onMessage.listen((event) {
      print("foregroundNotification: ${event.notification?.title}");
      showNotification(event);
    });
  }

  //ปิดแอป แต่ไม่เคลียร์แอป
  resumeNotification() {
    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      print("backgroundNotification: ${event.notification!.body}");
      // log("message notification");
    });
  }

  //ปิดแอปแล้วเปิดมาใหม่
  terminateNotification() async {
    print("terminateNotification");
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // log("message notification");
    }
  }

  // get device push notification token
  Future<String> getDeviceToken() async {
    var notifyToken = await firebaseMessaging.isSupported()
        ? await firebaseMessaging.getToken()
        : "";
    return notifyToken ?? "";
  }


  //show alert dialog
  showAlertDialog(BuildContext context, String title, String body) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                child: Text("Ok"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }


  /// TODO: check this dispose
  @override
  void dispose() {
    dataCtrl.close();
    tittleCtrl.close();
    bodyCtrl.close();
  }
}
