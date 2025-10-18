import 'package:flutter/material.dart';
import 'package:solve_tutor/feature/calendar/constants/constants.dart';
import 'package:solve_tutor/feature/calendar/helper/utility_helper.dart';

import 'sizebox.dart';

void showSnackBar(BuildContext context, String msg,
    [String color = 'green']) async {
  Color snackColor = CustomColors.greenPrimary;
  final util = UtilityHelper();
  if (color == 'green') {
    snackColor = CustomColors.greenPrimary;
  } else if (color == 'red') {
    snackColor = CustomColors.redB71C1C;
  }
  final snackBar = SnackBar(
    content: Row(
      children: [
        Icon(
          Icons.check_circle,
          color: CustomColors.white,
          size: util.isTablet() ? 20.0 : 16,
        ),
        S.w(10.0),
        Flexible(
          child: Text(
            msg,
            style: CustomStyles.med14White,
          ),
        )
      ],
    ),
    duration: const Duration(seconds: 2),
    behavior: SnackBarBehavior.floating,
    backgroundColor: snackColor,
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    margin: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 32),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
