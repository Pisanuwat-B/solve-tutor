import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/authentication/pages/login_page.dart';
import 'package:solve_tutor/authentication/pages/role_incorrect_page.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';
import 'package:solve_tutor/nav.dart';

class Authenticate extends StatefulWidget {
  const Authenticate({super.key});

  @override
  State<Authenticate> createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  String role = 'tutor';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.firebaseAuth.currentUser != null) {
        auth.getSelfInfo();
        // await auth.updateRoleFirestore(role);
        await Future.delayed(const Duration(milliseconds: 500));
      }
    });
  }

  late AuthProvider auth;
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, con, child) {
        if (con.firebaseAuth.currentUser != null) {
          if (con.user?.role != role || con.user?.isDeleted == true) {
            return const NoPermissionPage();
          } else {
            return Nav();
          }
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
