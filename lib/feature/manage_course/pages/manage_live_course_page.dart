import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';
import 'package:solve_tutor/constants/theme.dart';
import 'package:solve_tutor/feature/calendar/pages/my_course_live.dart';
import 'package:solve_tutor/feature/cheet/pages/my_document.dart';
import 'package:solve_tutor/feature/class/pages/class_list_page.dart';
import 'package:solve_tutor/feature/market_place/pages/my_course_vdo.dart';
import 'package:solve_tutor/widgets/sizer.dart';

class ManageLiveCoursePage extends StatefulWidget {
  const ManageLiveCoursePage({super.key});

  @override
  State<ManageLiveCoursePage> createState() => _ManageLiveCoursePageState();
}

class _ManageLiveCoursePageState extends State<ManageLiveCoursePage> {
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
                        height: 230,
                        margin: const EdgeInsets.fromLTRB(30, 30, 15, 0),
                        padding: const EdgeInsets.all(30),
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SizedBox(
                                child: Image.asset(
                                  "assets/images/calendar.png",
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "ตารางสอน / เข้าห้องเรียน",
                                          style: TextStyle(
                                            color: appTextPrimaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
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
                                          "ดูตารางสอนของคุณ และกดเข้าห้องเรียน",
                                          style: TextStyle(
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
                    ),
                    Expanded(
                      child: Container(
                        height: 230,
                        margin: const EdgeInsets.fromLTRB(15, 30, 30, 0),
                        padding: const EdgeInsets.all(30),
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SizedBox(
                                child: Image.asset(
                                  "assets/images/graph.png",
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "การใช้งาน",
                                          style: TextStyle(
                                            color: appTextPrimaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
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
                                          "ดูรายการค่าใช้จ่ายคอร์สสอนสด",
                                          style: TextStyle(
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
                    ),
                  ],
                ),
                GridView.count(
                  shrinkWrap: true,
                  primary: false,
                  padding: const EdgeInsets.all(30),
                  crossAxisSpacing: 30,
                  mainAxisSpacing: 30,
                  crossAxisCount: Sizer(context).w <= 600 ? 1 : 3,
                  children: <Widget>[
                    // gridCard(
                    //   context,
                    //   onTap: () {},
                    //   image: 'assets/images/graph1.png',
                    //   title: "ภาพรวม",
                    //   content:
                    //       "ดูคอร์สขายดี, รายได้ของคุณ, จำนวนนักเรียนในคอร์ส, รีวิว, และคะแนนของคุณ",
                    // ),
                    // gridCard(
                    //   context,
                    //   onTap: () async {
                    //     await Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => MyCourseVDOPage(
                    //           tutorId: auth?.uid ?? "",
                    //         ),
                    //       ),
                    //     );
                    //   },
                    //   image: 'assets/images/menu_my_course.png',
                    //   title: "คอร์ส Marketplace",
                    // ),
                    gridCard(
                      context,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyCourseLivePage(
                              tutorId: auth?.uid ?? "",
                            ),
                          ),
                        );
                      },
                      image: 'assets/images/menu_my_course.png',
                      title: "สร้างคอร์สสอนสด",
                      content:
                          "เพิ่มชีท เพิ่มนักเรียน จัดตารางสอน และรอสอนได้เลย",
                    ),
                    // gridCard(
                    //   context,
                    //   onTap: () {},
                    //   image: 'assets/images/student1.png',
                    //   title: "จัดการนักเรียน",
                    //   content:
                    //       "แชร์คอร์ส จัดการรายชื่อ นักเรียนที่ลงทะเบียนในคอร์สของคุณ",
                    // ),

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
                      onTap: () {},
                      image: 'assets/images/menu_qa.png',
                      title: "ตอบคำถามนักเรียน",
                      content:
                          "อธิบายนักเรียนด้วยนวัตกรรม virtual one-on-one tutoring",
                    ),
                    // gridCard(
                    //   context,
                    //   onTap: () {
                    //     var route = MaterialPageRoute(
                    //         builder: (context) => const ClassListPage());
                    //     Navigator.push(context, route);
                    //   },
                    //   image: 'assets/images/menu_find_job.png',
                    //   title: "ค้นหางานสอน",
                    //   content:
                    //       "ประกาศของนักเรียนที่กำลังมองหาติวเตอร์ คุณสามารถเข้า ไปเสนอราคาเพื่อรับงานได้",
                    // ),
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
