import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../calendar/constants/custom_colors.dart';
import '../../calendar/constants/custom_styles.dart';
import '../../calendar/widgets/sizebox.dart';
import '../utils/responsive.dart';

Future<void> showCloseDialog(
  BuildContext context,
  Function onConfirm, {
  String title = 'ต้องการจบการสอน?',
  String detail = 'นักเรียนในห้องของคุณทั้งหมดจะถูกบังคับให้ออกจากห้อง',
  String confirm = 'ปิดห้องเรียน',
  String cancel = 'กลับไปที่ห้องเรียน',
  Function? onCancel = _defaultOnCancel,
}) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 0,
        backgroundColor: CustomColors.whitePrimary,
        child: SizedBox(
          width: Responsive.isDesktop(context)
              ? MediaQuery.of(context).size.width * 0.5
              : MediaQuery.of(context).size.width * 0.65,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(title, style: CustomStyles.bold22Black363636),
                S.h(32),
                Text(detail,
                    style: CustomStyles.med14Gray878787,
                    textAlign: TextAlign.center),
                S.h(32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: Responsive.isMobileLandscape(context) ? 100 : 185,
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CustomColors.redF44336,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onConfirm(); // Execute the confirmation function
                        },
                        child: Text(confirm, style: CustomStyles.bold14White),
                      ),
                    ),
                    SizedBox(
                      width: Responsive.isMobile(context) ? 100 : 185,
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CustomColors.whitePrimary,
                          elevation: 0,
                          side: const BorderSide(
                              width: 1, color: CustomColors.grayE5E6E9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              8.0,
                            ),
                          ),
                        ),
                        onPressed: () {
                          onCancel?.call();
                          Navigator.of(context).pop();
                        },
                        child:
                            Text(cancel, style: CustomStyles.bold14Gray878787),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void _defaultOnCancel() {}

Future<void> showAlertRecordingDialog(BuildContext context,
    {String title = 'ระบบกำลังทำการบันทึกการสอน',
    String detail =
        'ท่านไม่สามารถปิดห้องเรียนระหว่างบันทึกการสอนได้ กรุณาสิ้นสุดการบันทึก',
    String confirm = 'ตกลง'}) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 0,
        backgroundColor: CustomColors.whitePrimary,
        child: SizedBox(
          width: Responsive.isMobile(context)
              ? MediaQuery.of(context).size.width * 0.65
              : MediaQuery.of(context).size.width * 0.5,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(title, style: CustomStyles.bold22Black363636),
                S.h(32),
                Text(detail,
                    style: CustomStyles.med14Gray878787,
                    textAlign: TextAlign.center),
                S.h(32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 185,
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CustomColors.redF44336,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(8.0), // <-- Radius
                          ), // NEW
                        ),
                        onPressed: () {
                          // SystemChrome.setPreferredOrientations([
                          //   DeviceOrientation.portraitUp,
                          //   DeviceOrientation.portraitDown,
                          // ]);
                          Navigator.of(context).pop();
                        },
                        child: Text(confirm, style: CustomStyles.bold14White),
                      ),
                    ),
                    // SizedBox(
                    //   width: 185,
                    //   height: 40,
                    //   child: ElevatedButton(
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: CustomColors.whitePrimary,
                    //       elevation: 0,
                    //       side: const BorderSide(
                    //           width: 1, color: CustomColors.grayE5E6E9),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(
                    //           8.0,
                    //         ),
                    //       ),
                    //     ),
                    //     onPressed: () {
                    //       Navigator.of(context).pop();
                    //     },
                    //     child:
                    //     Text(cancel, style: CustomStyles.bold14Gray878787),
                    //   ),
                    // ),
                  ],
                )
              ],
            ),
          ),
        ),
      );
    },
  );
}
