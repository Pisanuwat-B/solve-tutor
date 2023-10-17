import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/auth.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';
import 'package:solve_tutor/constants/theme.dart';
import 'package:solve_tutor/feature/payment/pages/solve_fund.dart';
import 'package:solve_tutor/widgets/confirm_action_widget.dart';
import 'package:solve_tutor/widgets/dialogs.dart';
import 'package:solve_tutor/widgets/sizer.dart';
import '../../live_classroom/page/live_classroom.dart';
import '../components/webview.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String? _image;

  String roleSelected = 'student';
  String classSelected = 'ประถม 1';
  TextEditingController nameCtl = TextEditingController();
  TextEditingController aboutCtl = TextEditingController();
  TextEditingController roleCtl = TextEditingController();
  TextEditingController classCtl = TextEditingController();
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  Future<void> updateUserInfo() async {
    authProvider.getSelfInfo();
    await firestore.collection('users').doc(authProvider.user!.id).update({
      'name': nameCtl.text,
      'about': aboutCtl.text,
      'role': roleCtl.text,
      'class_level': classCtl.text,
    });
  }

  late AuthProvider authProvider;
  init() {
    nameCtl = TextEditingController(text: authProvider.user?.name);
    aboutCtl = TextEditingController(text: authProvider.user?.about);
    roleCtl = TextEditingController(text: authProvider.user?.role);
    classCtl = TextEditingController(text: authProvider.user?.classLevel);
    if (roleCtl.text.isNotEmpty) {
      roleSelected = roleCtl.text;
    }
    if (classCtl.text.isNotEmpty) {
      classSelected = classCtl.text;
    }
  }

  @override
  void initState() {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'ตั้งค่า',
            style: TextStyle(
              color: appTextPrimaryColor,
            ),
          ),
          leadingWidth: Navigator.canPop(context) ? 50 : 0,
          leading: Builder(builder: (context) {
            if (Navigator.canPop(context)) {
              return IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.chevron_left,
                  color: Colors.black,
                ),
              );
            }
            return const SizedBox();
          }),
          backgroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey,
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                            width: Sizer(context).w,
                            height: Sizer(context).h * .03),
                        Stack(
                          children: [
                            _image != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        Sizer(context).h * .1),
                                    child: Image.asset(
                                        'assets/images/profile2.png',
                                        width: Sizer(context).h * .15,
                                        height: Sizer(context).h * .15,
                                        fit: BoxFit.cover))
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        Sizer(context).h * .1),
                                    child: CachedNetworkImage(
                                      width: Sizer(context).h * .15,
                                      height: Sizer(context).h * .15,
                                      fit: BoxFit.cover,
                                      imageUrl: authProvider.user?.image ?? "",
                                      errorWidget: (context, url, error) =>
                                          const CircleAvatar(
                                              child:
                                                  Icon(CupertinoIcons.person)),
                                    ),
                                  ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              authProvider.user?.name ?? "",
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            // const SizedBox(width: 5),
                            // IconButton(
                            //   onPressed: () {},
                            //   icon: const Icon(
                            //     Icons.edit,
                            //     color: Colors.grey,
                            //   ),
                            // ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                          decoration: BoxDecoration(
                            color: greyColor2,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text("${authProvider.user?.role ?? ""} "),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                          child: const Text(
                            "ID ของฉัน",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 50,
                          margin: const EdgeInsets.fromLTRB(30, 0, 30, 30),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 5, 10, 5),
                                  decoration: BoxDecoration(
                                    color:
                                        getMaterialColor(primaryColor).shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: primaryColor,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "${authProvider.uid ?? ""} ",
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(
                                            text: authProvider.uid ?? "",
                                          ));
                                          Dialogs.showSnackbar(
                                              context, "คัดลอกสำเร็จ");
                                        },
                                        icon: const Icon(
                                          Icons.copy_sharp,
                                          color: primaryColor,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              // const SizedBox(width: 20),
                              // Container(
                              //   padding:
                              //       const EdgeInsets.fromLTRB(10, 5, 10, 5),
                              //   decoration: BoxDecoration(
                              //     color: Colors.transparent,
                              //     borderRadius: BorderRadius.circular(10),
                              //     border: Border.all(
                              //       color: greyColor,
                              //     ),
                              //   ),
                              //   child: IconButton(
                              //     onPressed: () {},
                              //     icon: const Icon(
                              //       Icons.ios_share,
                              //       color: Colors.grey,
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // const SizedBox(height: 20),
                  // settingCard(title: 'ตั้งค่าบัญชี', icon: Icons.settings),
                  // const Divider(thickness: 2),
                  // const SizedBox(height: 10),
                  // settingCard(
                  //     title: 'ค่าบริการสมาชิก (เวอร์ชั่น ฟรี)',
                  //     icon: Icons.list),
                  // const Divider(thickness: 2),
                  // const SizedBox(height: 10),
                  // settingCard(
                  //     title: 'ตั้งค่าการแจ้งเตือน',
                  //     icon: Icons.notifications_active),
                  // const Divider(thickness: 2),
                  // const SizedBox(height: 30),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Text(
                      "เกี่ยวกับ Solve",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SolveFundPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 15, 20, 5),
                      child: const Row(
                        children: [
                          SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              'ซื้อเหรียญ',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(thickness: 2),
                  settingCard(
                      title: 'เงื่อนไขข้อตกลงการใช้บริการ',
                      url: 'https://solve.in.th/terms-of-service/'),
                  const Divider(thickness: 2),
                  const SizedBox(height: 10),
                  settingCard(
                      title: 'นโยบายความเป็นส่วนตัว',
                      url: 'https://solve.in.th/privacy-policy/'),
                  const Divider(thickness: 2),
                  GestureDetector(
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        barrierDismissible: true,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            content: const SizedBox(
                              width: 300,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      "เราเสียใจที่คุณจะไม่ได้ใช้งานบริการของเราอีก หากคุณได้ทำการลบบัญชีผู้ใช้แล้ว จะไม่สามารถทำการกู้กลับข้อมูลเดินมาได้ และไม่สามารถสมัครสมาชิกใหม่ด้วยบัญชีเดิมได้อีก",
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            actionsAlignment: MainAxisAlignment.center,
                            actions: <Widget>[
                              SizedBox(
                                width: double.infinity,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextButton(
                                        child: const Text(
                                          'ยกเลิก',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: TextButton(
                                        child: const Text(
                                          'ตกลง',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        onPressed: () async {
                                          Navigator.of(context).pop();
                                          await authProvider.deleteAccount();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDoubleTap: () {},
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 15, 20, 5),
                      child: const Row(
                        children: [
                          SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              'คำขอลบบัญชี',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(thickness: 2),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        // ElevatedButton(
                        //   onPressed: () {
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(
                        //         builder: (context) => const TutorLiveClassroom(
                        //           meetingId: 'test',
                        //           userId: 'test',
                        //           token: 'test',
                        //           displayName: 'TEST TEST',
                        //           isHost: true,
                        //           courseId: 'test',
                        //           startTime: 0,
                        //           isMock: true,
                        //         ),
                        //       ),
                        //     );
                        //   },
                        //   child: const Text('TEST'),
                        // ),
                        TextButton(
                          onPressed: () async {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return ConfirmActionWidget(
                                  title: 'ออกจากระบบ',
                                  content: 'ออกจากระบบบัญชีของคุณใช่หรือไม่',
                                  confirmText: 'ออกจากระบบ',
                                  confirmColor: Colors.red,
                                  onPressed: () async {
                                    await authProvider.signOut().then((value) {
                                      Navigator.of(context)
                                          .popUntil((route) => route.isFirst);
                                      var route = MaterialPageRoute(
                                          builder: (context) =>
                                              const Authenticate());
                                      Navigator.pushReplacement(context, route);
                                    });
                                  },
                                );
                              },
                            );
                          },
                          child: const Text("ออกจากระบบ"),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          authProvider.user?.email ?? "",
                          style: const TextStyle(
                            color: greyColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'SOLVE Instructor v 0.2.01',
                          style: TextStyle(
                            color: greyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget settingCard({
    required String title,
    IconData? icon,
    String? url,
  }) {
    return InkWell(
      onTap: () {
        if (url != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PrivacyPolicyScreen(url: url),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
        child: Row(
          children: [
            icon == null
                ? const SizedBox()
                : Icon(
                    icon,
                    color: primaryColor,
                  ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
