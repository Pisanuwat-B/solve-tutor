import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("Background-Noti: ${message.notification?.body}");
}
