import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:solve_tutor/constants/app_constants.dart';
import 'package:solve_tutor/constants/state_index.dart';
import 'package:solve_tutor/constants/theme.dart';
import 'package:solve_tutor/splash_page.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'authentication/service/fcm.dart';


//global context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // initializeDateFormatting();

  initializeDateFormatting();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  //initial push notification
  final FCMServices fcmService = FCMServices();
  await fcmService.firebaseMessaging.setAutoInitEnabled(true);
  await fcmService.initializeService();
  //firebase background service
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, deviceType) {
      return MultiProvider(
        providers: stateIndex,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: AppConstants.appTitle,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: primaryColor,
            primarySwatch: getMaterialColor(primaryColor),
            scaffoldBackgroundColor: Colors.grey.shade100,
            fontFamily: 'NotoSans',
          ),
          home: SplashPage(),
        ),
      );
    });
  }
}

// must handle in main methods
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage? message) async {
  await Firebase.initializeApp();
  if (message != null) {
    //handle background notification
    print("message: ${message.notification?.title}");
  }
}
