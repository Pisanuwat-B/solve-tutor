import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/feature/calendar/pages/course_live_calendar.dart';
import 'package:solve_tutor/feature/chat/pages/chat_list_page.dart';
import 'package:solve_tutor/feature/class/pages/class_list_page.dart';
import 'package:solve_tutor/feature/manage_course/pages/manage_course_page.dart';
import 'package:solve_tutor/feature/notification/notification_page.dart';
import 'package:solve_tutor/feature/profile/pages/profile_page.dart';

import 'authentication/service/auth_provider.dart';
import 'feature/notification/notification_provider.dart';

class Nav extends StatefulWidget {
  const Nav({super.key, this.index = 0});
  final int index;
  @override
  State<Nav> createState() => _NavState();
}

class _NavState extends State<Nav> with TickerProviderStateMixin {
  TabController? tabController;
  // double sizeCenterButton = 30;
  bool bigCenterButton = true;
  int currentIndex = 0;
  List<Widget> pages = [
    // const CourseLiveCalendar(),
    const ManageCoursePage(),
    // const ClassListPage(),
    // const ChatListPage(),
    const NotificationPage(),
    const ProfilePage(),
  ];

  late AuthProvider authProvider;

  tab(int value) {
    currentIndex = value;
    tabController!.animateTo(value);
    bigCenterButton = true;
    if (value == 0 || value == 1) {
      bigCenterButton = false;
    }
    setState(() {});
  }

  // FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  // final notifications = FlutterLocalNotificationsPlugin();
  // FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  // init() {
  //   firebaseMessaging.getToken().then((String? token) async {
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     log("device token = $token");
  //     await prefs.setString('device_token', token!);
  //   });
  //   final FirebaseMessaging = FCM();
  // }

  @override
  void initState() {
    super.initState();
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    Provider.of<NotificationProvider>(context, listen: false).listenForNewQuestions(authProvider.uid!);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    tabController =
        TabController(length: pages.length, vsync: this); // initialise it here
    currentIndex = widget.index;
    tabController!.animateTo(currentIndex);
  }


  @override
  void dispose() {
    tabController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasNotification = context.watch<NotificationProvider>().hasNewNotification;
    return Scaffold(
      body: SafeArea(
        child: TabBarView(
          controller: tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: pages,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: tab,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle:
          GoogleFonts.kanit(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
          GoogleFonts.kanit(fontSize: 12, fontWeight: FontWeight.w400),
          unselectedItemColor: Colors.grey,
          items: [
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.calendar_month_outlined),
            //   activeIcon: Icon(Icons.calendar_month),
            //   label: 'ตารางสอน',
            // ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.copy_outlined),
              activeIcon: Icon(Icons.copy),
              label: 'คอร์ส',
            ),
            // BottomNavigationBarItem(
            //   icon: Icon(CupertinoIcons.chat_bubble_2),
            //   activeIcon: Icon(CupertinoIcons.chat_bubble_2),
            //   label: 'แชท',
            // ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_outlined),
                  if (hasNotification)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: Stack(
                children: [
                  const Icon(Icons.notifications),
                  if (hasNotification)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'แจ้งเตือน',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              activeIcon: Icon(Icons.account_circle),
              label: 'ตั้งค่า',
            ),
          ],
        ),
      ),
    );
  }
}
