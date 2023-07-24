import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';
import 'package:solve_tutor/feature/class/models/class_model.dart';
import 'package:solve_tutor/feature/class/pages/create_class_page.dart';
import 'package:solve_tutor/feature/class/services/class_provider.dart';
import 'package:solve_tutor/feature/class/widgets/build_card_class_body_widget.dart';
import 'package:solve_tutor/widgets/sizer.dart';

class MyClassPage extends StatefulWidget {
  const MyClassPage({super.key});

  @override
  State<MyClassPage> createState() => _MyClassPageState();
}

class _MyClassPageState extends State<MyClassPage> {
  AuthProvider? authProvider;
  ClassProvider? classProvider;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      authProvider = Provider.of<AuthProvider>(context, listen: false);
      classProvider = Provider.of<ClassProvider>(context, listen: false);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            StreamBuilder(
                stream: classProvider?.getAllClassById(
                    authProvider!.user!.id!, true),
                builder: (context, snapshot) {
                  final List<ClassModel> list = [];

                  if (snapshot.hasData) {
                    try {
                      final data = snapshot.data?.docs;
                      for (var i in data!) {
                        ClassModel model = ClassModel.fromJson(i.data());
                        list.add(model);
                      }
                    } catch (e) {
                      return const Text("ข้อมูลผิดพลาด");
                    }
                  }

                  if (list.isNotEmpty) {
                    list.sort((a, b) {
                      return a.createdAt!
                          .toString()
                          .compareTo(b.createdAt!.toString());
                    });
                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: list.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: Sizer(context).w <= 600 ? 1 : 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 25,
                        // mainAxisExtent: 300
                      ),
                      itemBuilder: (context, index) {
                        ClassModel item = list[index];
                        return BuildCardClassBodyWidget(
                          item,
                          (item) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CreateClassPage(
                                        classModelEdit: item,
                                      )),
                            );
                          },
                        );
                      },
                    );
                  } else if (list.isEmpty) {
                    return const Text("ไม่พบข้อมูล");
                  }
                  return const Text("Loading...");
                }),
            const SizedBox(
              height: 80,
            ),
          ],
        ),
      ),
    );
  }
}
