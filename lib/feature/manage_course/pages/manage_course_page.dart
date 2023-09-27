import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';
import 'package:solve_tutor/constants/theme.dart';
import 'package:solve_tutor/feature/calendar/pages/create_course_live.dart';
import 'package:solve_tutor/feature/calendar/pages/my_course_live.dart';
import 'package:solve_tutor/feature/cheet/pages/my_document.dart';
import 'package:solve_tutor/feature/class/pages/class_list_page.dart';
import 'package:solve_tutor/feature/market_place/pages/my_course_vdo.dart';
import 'package:solve_tutor/feature/order_manage/pages/my_order_page.dart';
import 'package:solve_tutor/widgets/sizer.dart';

class ManageCoursePage extends StatefulWidget {
  const ManageCoursePage({super.key});

  @override
  State<ManageCoursePage> createState() => _ManageCoursePageState();
}

class _ManageCoursePageState extends State<ManageCoursePage> {
  AuthProvider? auth;
  @override
  Widget build(BuildContext context) {
    auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'จัดการคอร์สเรียน',
          style: TextStyle(
            color: appTextPrimaryColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          width: Sizer(context).w,
          height: Sizer(context).h,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 20),
                Container(
                    width: 110,
                    height: 50,
                    child: Image.asset('assets/images/big_solve_logo.png')),
                const Text(
                  "ประสบการณ์ใหม่ของการสอนออนไลน์",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // const Text(
                //   "เปลี่ยนวิธีการสอนแบบเดิม\nให้นักเรียนของคุณสามารถเรียนได้จากทุกที่ผ่านมือถือ หรือ Tablet",
                //   style: TextStyle(
                //     fontSize: 14,
                //     color: appTextSecondaryColor,
                //   ),
                //   textAlign: TextAlign.center,
                // ),
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
                      title: "คอร์ส Live",
                      // content:
                      //     "สร้างคอร์สสอนพิเศษของคุณ เพื่อลงขายใน Market Place ของเรา",
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
                      // content:
                      //     "สร้างคลังเอกสารประกอบการเรียน เพื่อให้คุณสามารถแชร์เอกสารกับคอร์สอื่นๆได้",
                    ),
                    // gridCard(
                    //   context,
                    //   onTap: () {},
                    //   image: 'assets/images/menu_qa.png',
                    //   title: "ตอบคำถามนักเรียน",
                    //   // content:
                    //   //     "คำถามระหว่างเรียนของนักเรียนของคุณ ที่ต้องการให้คุณช่วยตอบ",
                    // ),
                    gridCard(
                      context,
                      onTap: () {
                        var route = MaterialPageRoute(
                            builder: (context) => const ClassListPage());
                        Navigator.push(context, route);
                      },
                      image: 'assets/images/menu_find_job.png',
                      title: "ค้นหางานสอน",
                      // content:
                      //     "ประกาศของนักเรียนที่กำลังมองหาติวเตอร์ คุณสามารถเข้า ไปเสนอราคาเพื่อรับงานได้",
                    ),
                    gridCard(
                      context,
                      onTap: () {
                        var route = MaterialPageRoute(
                            builder: (context) => const MyOrderPage());
                        Navigator.push(context, route);
                      },
                      image: 'assets/images/menu_find_job.png',
                      title: "รายการคำสั่งซื้อ",
                      // content:
                      //     "ประกาศของนักเรียนที่กำลังมองหาติวเตอร์ คุณสามารถเข้า ไปเสนอราคาเพื่อรับงานได้",
                    ),
                  ],
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// TODO: FIX THIS UGLY THING
  Widget gridCard(
    BuildContext context, {
    required Function()? onTap,
    required String image,
    required String title,
    // required String content,
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
          crossAxisAlignment: CrossAxisAlignment.center,
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: appTextPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  // Text(
                  //   content,
                  //   style: const TextStyle(
                  //     color: appTextSecondaryColor,
                  //     fontSize: 14,
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
