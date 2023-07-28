import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/auth.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';
import 'package:solve_tutor/constants/theme.dart';

class SplashPage extends StatefulWidget {
  SplashPage({super.key});

  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    auth = Provider.of<AuthProvider>(context, listen: false);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      log("message at ");
      if (auth.firebaseAuth.currentUser != null) {
        log("message in ");
        auth.getSelfInfo();
        await Future.delayed(const Duration(seconds: 2));
      }
      goToMidleware();
    });
  }

  void goToMidleware() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Authenticate()),
    );
  }

  late AuthProvider auth;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FlutterLogo(size: 100),
            const SizedBox(height: 20),
            Container(
              width: 20,
              height: 20,
              child: const CircularProgressIndicator(color: primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
