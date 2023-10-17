import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';
import 'package:solve_tutor/constants/theme.dart';
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
        child: Container(
          width: Sizer(context).w,
          height: Sizer(context).h,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: Responsive.isMobile(context) ? 200 : 230,
                        margin: const EdgeInsets.fromLTRB(30, 30, 15, 0),
                        padding: Responsive.isMobile(context)
                            ? const EdgeInsets.all(15)
                            : const EdgeInsets.all(30),
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
                                builder: (context) => const MaintenancePage(),
                              ),
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  child: Image.asset(
                                    "assets/images/add-income.png",
                                    fit: BoxFit.contain,
                                  ),
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
                                            "ภาพรวม",
                                            style: TextStyle(
                                              color: appTextPrimaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize:
                                                  Responsive.isMobile(context)
                                                      ? 14
                                                      : 16,
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
                                            "ดูคอร์สขายดี, รายได้ของคุณ, จำนวนนักเรียนในคอร์ส, รีวิว, และคะแนนของคุณ",
                                            style: TextStyle(
                                              color: appTextSecondaryColor,
                                              fontSize:
                                                  Responsive.isMobile(context)
                                                      ? 13
                                                      : 14,
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
                    ),
                    Expanded(
                      child: Container(
                        height: Responsive.isMobile(context) ? 200 : 230,
                        margin: const EdgeInsets.fromLTRB(15, 30, 30, 0),
                        padding: Responsive.isMobile(context)
                            ? const EdgeInsets.all(15)
                            : const EdgeInsets.all(30),
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
                                builder: (context) => const MaintenancePage(),
                              ),
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  child: Image.asset(
                                    "assets/images/withdraw-money.png",
                                    fit: BoxFit.contain,
                                  ),
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
                                            "ถอนเงิน",
                                            style: TextStyle(
                                              color: appTextPrimaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize:
                                                  Responsive.isMobile(context)
                                                      ? 14
                                                      : 16,
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
                                            "จัดการ Credits รายได้และยอดเงินเตรียมโอนของคุณ",
                                            style: TextStyle(
                                              color: appTextSecondaryColor,
                                              fontSize:
                                                  Responsive.isMobile(context)
                                                      ? 13
                                                      : 16,
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
                    ),
                  ],
                ),
                if (!Responsive.isMobile(context))
                  GridView.count(
                    shrinkWrap: true,
                    primary: false,
                    padding: const EdgeInsets.all(30),
                    crossAxisSpacing: 30,
                    mainAxisSpacing: 30,
                    crossAxisCount: Sizer(context).w <= 600 ? 1 : 3,
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
                              builder: (context) => const MaintenancePage(),
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
                if (Responsive.isMobile(context))
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: Responsive.isMobile(context) ? 200 : 230,
                          margin: const EdgeInsets.fromLTRB(30, 30, 15, 0),
                          padding: Responsive.isMobile(context)
                              ? const EdgeInsets.all(15)
                              : const EdgeInsets.all(30),
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
                                  builder: (context) => MyCourseVDOPage(
                                    tutorId: auth?.uid ?? "",
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    child: Image.asset(
                                      "assets/images/menu_my_course.png",
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "สร้างคอร์สด้วย Solvepad",
                                              style: TextStyle(
                                                color: appTextPrimaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    Responsive.isMobile(context)
                                                        ? 14
                                                        : 16,
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
                                              "สร้างคอร์สเพื่อลงขายใน Marketplace",
                                              style: TextStyle(
                                                color: appTextSecondaryColor,
                                                fontSize:
                                                    Responsive.isMobile(context)
                                                        ? 13
                                                        : 16,
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
                      ),
                      Expanded(
                        child: Container(
                          height: Responsive.isMobile(context) ? 200 : 230,
                          margin: const EdgeInsets.fromLTRB(15, 30, 30, 0),
                          padding: Responsive.isMobile(context)
                              ? const EdgeInsets.all(15)
                              : const EdgeInsets.all(30),
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
                              var route = MaterialPageRoute(
                                builder: (context) => MyDocumentPage(
                                  tutorId: auth?.uid ?? "",
                                ),
                              );
                              Navigator.push(context, route);
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    child: Image.asset(
                                      "assets/images/menu_create_sheet.png",
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "สร้างชีท",
                                              style: TextStyle(
                                                color: appTextPrimaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    Responsive.isMobile(context)
                                                        ? 14
                                                        : 16,
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
                                              "อัปโหลดเอกสารประกอบการสอน",
                                              style: TextStyle(
                                                color: appTextSecondaryColor,
                                                fontSize:
                                                    Responsive.isMobile(context)
                                                        ? 13
                                                        : 16,
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
                      ),
                    ],
                  ),
                if (Responsive.isMobile(context))
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: Responsive.isMobile(context) ? 200 : 230,
                          margin: const EdgeInsets.fromLTRB(30, 30, 15, 0),
                          padding: Responsive.isMobile(context)
                              ? const EdgeInsets.all(15)
                              : const EdgeInsets.all(30),
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
                                  builder: (context) => const MaintenancePage(),
                                ),
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    child: Image.asset(
                                      "assets/images/menu_qa.png",
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "ตอบคำถามนักเรียน",
                                              style: TextStyle(
                                                color: appTextPrimaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    Responsive.isMobile(context)
                                                        ? 14
                                                        : 16,
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
                                              "อธิบายนักเรียนด้วยนวัตกรรม virtual one-on-one tutoring",
                                              style: TextStyle(
                                                color: appTextSecondaryColor,
                                                fontSize:
                                                    Responsive.isMobile(context)
                                                        ? 13
                                                        : 16,
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
                      ),
                    ],
                  ),
                const SizedBox(height: 70),
              ],
            ),
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
        padding: const EdgeInsets.all(30),
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
            Expanded(
              child: SizedBox(
                child: Image.asset(
                  image,
                  fit: BoxFit.contain,
                ),
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
                            fontSize: 16,
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
