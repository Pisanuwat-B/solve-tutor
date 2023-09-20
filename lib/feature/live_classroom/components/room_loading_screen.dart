import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:solve_tutor/feature/calendar/constants/constants.dart';
import '../utils/spacer.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffeff0f2),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset("assets/images/logo.json", width: 100),
            const VerticalSpacer(20),
            const Text(
              "Loading SOLVE Live room",
              style: TextStyle(
                  fontSize: 20,
                  color: CustomColors.greenPrimary,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
