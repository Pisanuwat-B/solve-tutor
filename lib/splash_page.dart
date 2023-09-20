import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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
      if (auth.firebaseAuth.currentUser != null) {
        auth.getSelfInfo();
        await Future.delayed(const Duration(milliseconds: 500));
      }
      goToMiddleware();
    });
  }

  void goToMiddleware() async {
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
        child: Lottie.asset("assets/images/logo.json", width: 100),
      ),
    );
  }
}
