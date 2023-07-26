import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/auth.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';
import 'package:solve_tutor/constants/school_subject_constants.dart';
import 'package:solve_tutor/constants/theme.dart';
import 'package:solve_tutor/widgets/confirm_action_widget.dart';
import 'package:solve_tutor/widgets/dialogs.dart';
import 'package:solve_tutor/widgets/sizer.dart';

import '../../../db_test.dart';

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
    authprovider.getSelfInfo();
    await firestore.collection('users').doc(authprovider.user!.id).update({
      'name': nameCtl.text,
      'about': aboutCtl.text,
      'role': roleCtl.text,
      'class_level': classCtl.text,
    });
  }

  late AuthProvider authprovider;
  init() {
    nameCtl = TextEditingController(text: authprovider.user?.name);
    aboutCtl = TextEditingController(text: authprovider.user?.about);
    roleCtl = TextEditingController(text: authprovider.user?.role);
    classCtl = TextEditingController(text: authprovider.user?.classLevel);
    if (roleCtl.text.isNotEmpty) {
      roleSelected = roleCtl.text;
    }
    if (classCtl.text.isNotEmpty) {
      classSelected = classCtl.text;
    }
  }

  @override
  void initState() {
    authprovider = Provider.of<AuthProvider>(context, listen: false);
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
        body: Form(
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
                                    imageUrl: authprovider.user?.image ?? "",
                                    errorWidget: (context, url, error) =>
                                        const CircleAvatar(
                                            child: Icon(CupertinoIcons.person)),
                                  ),
                                ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            authprovider.user?.name ?? "",
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(width: 5),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                        decoration: BoxDecoration(
                          color: greyColor2,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text("${authprovider.user?.role ?? ""} "),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                        child: const Text(
                          "รหัสของฉัน",
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
                                  color: getMaterialColor(primaryColor).shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: primaryColor,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "${authprovider.uid ?? ""} ",
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(
                                          text: authprovider.uid ?? "",
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
                            const SizedBox(width: 20),
                            Container(
                              padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: greyColor,
                                ),
                              ),
                              child: IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.ios_share,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                settingCard(title: 'ตั้งค่าบัญชี', icon: Icons.settings),
                Divider(thickness: 2),
                const SizedBox(height: 10),
                settingCard(title: 'ค่าบริการสมาชิก', icon: Icons.list),
                Divider(thickness: 2),
                const SizedBox(height: 10),
                settingCard(
                    title: 'ตั้งค่าการแจ้งเตือน',
                    icon: Icons.notifications_active),
                Divider(thickness: 2),
                const SizedBox(height: 30),
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
                settingCard(title: 'เงื่อนไขข้อตกลงการใช้บริการ'),
                Divider(thickness: 2),
                const SizedBox(height: 10),
                settingCard(title: 'นโยบายความเป็นส่วนตัว'),
                Divider(thickness: 2),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const DbTest()),
                          );
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //       builder: (context) => const JoinScreen()),
                          // );
                        },
                        child: const Text('DB Test'),
                      ),
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
                                  await authprovider.signOut().then((value) {
                                    Navigator.of(context)
                                        .popUntil((route) => route.isFirst);
                                    var route = MaterialPageRoute(
                                        builder: (context) => Authenticate());
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
                        authprovider.user?.email ?? "",
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
    );
  }

  Container settingCard({
    required String title,
    IconData? icon,
  }) {
    return Container(
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
    );
  }
}
