import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';
import 'package:solve_tutor/constants/theme.dart';
import 'package:solve_tutor/feature/audio/home_audio_page.dart';
import 'package:solve_tutor/feature/calendar/pages/my_course_live.dart';
import 'package:solve_tutor/feature/cheet/pages/my_document.dart';
import 'package:solve_tutor/feature/class/pages/class_list_page.dart';
import 'package:solve_tutor/feature/market_place/pages/my_course_vdo.dart';
import 'package:solve_tutor/widgets/sizer.dart';

import '../../live_classroom/utils/responsive.dart';
import '../../maintenance/maintenance.dart';

class ManageMarketCoursePage extends StatefulWidget {
  const ManageMarketCoursePage({super.key});

  @override
  State<ManageMarketCoursePage> createState() => _ManageMarketCoursePageState();
}

class _ManageMarketCoursePageState extends State<ManageMarketCoursePage> {
  AuthProvider? auth;
  @override
  Widget build(BuildContext context) {
    auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: Sizer(context).w,
          height: Sizer(context).h,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (!Responsive.isMobileLandscape(context)) ...[
                  Row(
                    children: [
                      mobileCard(
                        'assets/images/add-income.png',
                        'ภาพรวม',
                        'ดูคอร์สขายดี, รายได้ของคุณ, จำนวนนักเรียนในคอร์ส, รีวิว, และคะแนนของคุณ',
                        'left',
                        const MaintenancePage(),
                      ),
                      mobileCard(
                        'assets/images/withdraw-money.png',
                        'ถอนเงิน',
                        'จัดการ Credits รายได้และยอดเงินเตรียมโอนของคุณ',
                        'right',
                        const MaintenancePage(),
                      ),
                    ],
                  ),
                ],
                if (Responsive.isMobileLandscape(context)) ...[
                  Row(
                    children: [
                      mobileCard(
                        'assets/images/add-income.png',
                        'ภาพรวม',
                        'ดูคอร์ส, รายได้, รีวิว, และอื่นๆ',
                        'tightLeft',
                        const MaintenancePage(),
                      ),
                      mobileCard(
                        'assets/images/withdraw-money.png',
                        'ถอนเงิน',
                        'จัดการ Credits รายได้, ยอดเงิน',
                        'tight',
                        const MaintenancePage(),
                      ),
                      mobileCard(
                        'assets/images/menu_my_course.png',
                        'Solve course',
                        'สร้างคอร์สใน Marketplace',
                        'tight',
                        MyCourseVDOPage(
                          tutorId: auth?.uid ?? "",
                        ),
                      ),
                      mobileCard(
                        'assets/images/menu_create_sheet.png',
                        'สร้างชีท',
                        'อัปโหลดเอกสารประกอบการสอน',
                        'tight',
                        MyDocumentPage(
                          tutorId: auth?.uid ?? "",
                        ),
                      ),
                      mobileCard(
                        'assets/images/menu_qa.png',
                        'ตอบคำถาม',
                        'อธิบายนักเรียน',
                        'tightRight',
                        const MaintenancePage(),
                      ),
                    ],
                  ),
                ],
                if (Responsive.isMobile(context)) ...[
                  Row(
                    children: [
                      mobileCard(
                        'assets/images/menu_my_course.png',
                        'คอร์ส Solvepad',
                        'สร้างคอร์สเพื่อลงขายใน Marketplace',
                        'left',
                        MyCourseVDOPage(
                          tutorId: auth?.uid ?? "",
                        ),
                      ),
                      mobileCard(
                        'assets/images/menu_create_sheet.png',
                        'สร้างชีท',
                        'อัปโหลดเอกสารประกอบการสอน',
                        'right',
                        MyDocumentPage(
                          tutorId: auth?.uid ?? "",
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      mobileCard(
                        'assets/images/menu_qa.png',
                        'ตอบคำถามนักเรียน',
                        'อธิบายนักเรียนด้วยนวัตกรรม virtual one-on-one tutoring',
                        'left',
                        const MaintenancePage(),
                      ),
                    ],
                  ),
                ],
                if (Responsive.isTablet(context)) ...[
                  GridView.count(
                    shrinkWrap: true,
                    primary: false,
                    padding: const EdgeInsets.all(30),
                    crossAxisSpacing: 30,
                    mainAxisSpacing: 30,
                    crossAxisCount: 3,
                    children: <Widget>[
                      gridCard(
                        context,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyCourseVDOPage(
                                tutorId: auth?.uid ?? "",
                              ),
                            ),
                          );
                        },
                        image: 'assets/images/menu_my_course.png',
                        title: "สร้างคอร์สด้วย SOLVE Pad",
                        content: "สร้างคอร์สเพื่อลงขายใน Marketplace",
                      ),
                      gridCard(
                        context,
                        onTap: () async {
                          var route = MaterialPageRoute(
                            builder: (context) => MyDocumentPage(
                              tutorId: auth?.uid ?? "",
                            ),
                          );
                          await Navigator.push(context, route);
                        },
                        image: 'assets/images/menu_create_sheet.png',
                        title: "สร้างชีท",
                        content: "อัปโหลดเอกสารประกอบการสอน",
                      ),
                      gridCard(
                        context,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeAudioPage(),
                            ),
                          );
                        },
                        image: 'assets/images/menu_qa.png',
                        title: "ตอบคำถามนักเรียน",
                        content:
                            "อธิบายนักเรียนด้วยนวัตกรรม virtual one-on-one tutoring",
                      ),
                    ],
                  ),
                ],
                if (Responsive.isDesktop(context)) ...[
                  Row(
                    children: [
                      mobileCard(
                        'assets/images/menu_my_course.png',
                        'สร้างคอร์สด้วย Solvepad',
                        'สร้างคอร์สเพื่อลงขายใน Marketplace',
                        'left',
                        MyCourseVDOPage(
                          tutorId: auth?.uid ?? "",
                        ),
                      ),
                      mobileCard(
                        'assets/images/menu_create_sheet.png',
                        'สร้างชีท',
                        'อัปโหลดเอกสารประกอบการสอน',
                        'mid',
                        MyDocumentPage(
                          tutorId: auth?.uid ?? "",
                        ),
                      ),
                      mobileCard(
                        'assets/images/menu_qa.png',
                        'ตอบคำถามนักเรียน',
                        'อธิบายนักเรียนด้วยนวัตกรรม virtual one-on-one tutoring',
                        'right',
                        const MaintenancePage(),
                      ),
                    ],
                  ),
                ],
                if (!Responsive.isMobileLandscape(context) &&
                    !Responsive.isDesktop(context))
                  const SizedBox(height: 70),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget mobileCard(
      String img, String title, String desc, String position, Widget link) {
    EdgeInsets cardPosition;
    if (position == 'left') {
      cardPosition = const EdgeInsets.fromLTRB(30, 25, 15, 0);
    } else if (position == 'right') {
      cardPosition = const EdgeInsets.fromLTRB(15, 25, 30, 0);
    } else if (position == 'mid') {
      cardPosition = const EdgeInsets.fromLTRB(15, 25, 15, 0);
    } else if (position == 'tight') {
      cardPosition = const EdgeInsets.fromLTRB(7, 20, 7, 0);
    } else if (position == 'tightLeft') {
      cardPosition = const EdgeInsets.fromLTRB(14, 20, 7, 0);
    } else if (position == 'tightRight') {
      cardPosition = const EdgeInsets.fromLTRB(7, 20, 14, 0);
    } else {
      cardPosition = const EdgeInsets.fromLTRB(15, 25, 15, 0);
    }
    return Expanded(
      child: Container(
        height: Responsive.isTablet(context) ? 230 : 185,
        margin: cardPosition,
        padding: Responsive.isTablet(context)
            ? const EdgeInsets.all(30)
            : const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 3,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => link,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 60,
                child: Image.asset(
                  img,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: appTextPrimaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: Responsive.isMobile(context) ? 14 : 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            desc,
                            style: TextStyle(
                              color: appTextSecondaryColor,
                              fontSize: Responsive.isMobile(context) ? 13 : 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget gridCard(
    BuildContext context, {
    required Function()? onTap,
    required String image,
    required String title,
    String? content,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 60,
              child: Image.asset(
                image,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: appTextPrimaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          content ?? "",
                          style: const TextStyle(
                            color: appTextSecondaryColor,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
