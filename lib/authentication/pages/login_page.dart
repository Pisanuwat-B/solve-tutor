import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:solve_tutor/auth.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/constants/theme.dart';
import 'package:solve_tutor/widgets/sizer.dart';

import '../../feature/calendar/constants/assets_manager.dart';
import '../../feature/calendar/constants/custom_colors.dart';
import '../../feature/calendar/constants/custom_styles.dart';
import '../../feature/calendar/widgets/sizebox.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  _handleGoogleBtnClick() {
    // Dialogs.showProgressBar(context);
    _signInWithGoogle().then((user) async {
      if (user != null) {
        log('\nUser: ${user.user}');
        log('\nUserAdditionalInfo: ${user.additionalUserInfo}');
        if (await authProvider!.userExists(user.user!)) {
        } else {
          await authProvider!.createUser(user.user!);
        }
        authProvider!.getSelfInfo();
        // var route =
        //     MaterialPageRoute(builder: (context) => const Authenticate());
        // Navigator.pushReplacement(context, route);
      }
    });
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      await InternetAddress.lookup('google.com');
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      return await authProvider!.firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      log('\n_signInWithGoogle: $e');
      // Dialogs.showSnackbar(context, 'Something Went Wrong (Check Internet!)');
      return null;
    }
  }

  AuthProvider? authProvider;
  @override
  Widget build(BuildContext context) {
    authProvider = Provider.of<AuthProvider>(context);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
          backgroundColor: const Color(0xffFFFFFF),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 67.0, left: 24, right: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('เข้าสู่ระบบ', style: CustomStyles.bold22Black363636),
                  S.h(8.00),
                  Text("เสริมสร้างทักษะ และความรู้ผ่านคอร์สเรียนคุณภาพของเรา",
                      style: CustomStyles.med14Black363636),
                  Text("เข้าถึงเนื้อหาบทเรียนและเทคนิคต่าง ๆ จากติวเตอร์",
                      style: CustomStyles.med14Black363636),
                  S.h(45.0),
                  Image.asset(
                    'assets/images/touch_video.png',
                    width: 165,
                    height: 165,
                  ),
                  S.h(46.0),
                  Text('เข้าสู่ระบบด้วยบัญชี',
                      style: CustomStyles.med18Black363636),
                  S.h(36.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Login with Google
                      InkWell(
                        onTap: () {
                          _handleGoogleBtnClick();
                        },
                        child: Container(
                          width: 200.0,
                          height: 50.0,
                          decoration: BoxDecoration(
                            color: CustomColors.grayF3F3F3,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/ic_google.png',
                                width: 23.4,
                                height: 24,
                              ),
                              S.w(16.0),
                              Text("Google",
                                  style: CustomStyles.med14Black363636)
                            ],
                          ),
                        ),
                      ),
                      S.w(16.0),
                      // Login with Apple ID
                      Platform.isIOS
                          ? InkWell(
                              onTap: () {},
                              child: Container(
                                width: 176.0,
                                height: 40.0,
                                decoration: BoxDecoration(
                                  color: CustomColors.grayF3F3F3,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      ImageAssets.icApple,
                                      width: 19.56,
                                      height: 24,
                                    ),
                                    S.w(16.0),
                                    Text("Apple ID",
                                        style: CustomStyles.med14Black363636)
                                  ],
                                ),
                              ),
                            )
                          : Container(),
                    ],
                  ),
                  S.h(32.0),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     Container(
                  //       height: 1,
                  //       width: _util.isTablet() ? 161 : 132,
                  //       color: CustomColors.grayF3F3F3,
                  //     ),
                  // S.w(8.0),
                  // Text("หรือ", style: CustomStyles.med18Black363636),
                  // S.w(8.0),
                  // Container(
                  //   height: 1,
                  //   width: _util.isTablet() ? 161 : 132,
                  //   color: CustomColors.grayF3F3F3,
                  // )
                  //   ],
                  // ),
                  // S.h(32.0),
                  //
                  // /// Form For Email
                  // SizedBox(
                  //   height: 40,
                  //   width: 368,
                  //   child: TextFormField(
                  //     controller: email,
                  //     style: CustomStyles.med14Black363636,
                  //     decoration: InputDecoration(
                  //         labelText: 'อีเมล',
                  //         labelStyle: CustomStyles.med14Black363636,
                  //         prefixIcon: const Icon(Icons.mail),
                  //         enabledBorder: const OutlineInputBorder(
                  //           // width: 0.0 produces a thin "hairline" border
                  //           borderSide: BorderSide(
                  //               color: CustomColors.grayE5E6E9, width: 1),
                  //         ),
                  //         border: const OutlineInputBorder()),
                  //   ),
                  // ),
                  // S.h(16.0),
                  //
                  // /// Form For Password
                  // SizedBox(
                  //   height: 40,
                  //   width: 368,
                  //   child: TextFormField(
                  //     style: CustomStyles.med14Black363636,
                  //     obscureText: _obscured,
                  //     focusNode: textFieldFocusNode,
                  //     keyboardType: TextInputType.visiblePassword,
                  //     controller: password,
                  //     decoration: InputDecoration(
                  //       labelText: 'รหัสผ่าน',
                  //       labelStyle: CustomStyles.med14Black363636,
                  //       prefixIcon: const Icon(Icons.lock),
                  //       enabledBorder: const OutlineInputBorder(
                  //         // width: 0.0 produces a thin "hairline" border
                  //         borderSide: BorderSide(
                  //             color: CustomColors.grayE5E6E9, width: 1),
                  //       ),
                  //       border: const OutlineInputBorder(),
                  //       suffixIcon: Padding(
                  //         padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                  //         child: GestureDetector(
                  //           onTap: _toggleObscured,
                  //           child: Icon(
                  //             _obscured
                  //                 ? Icons.visibility_rounded
                  //                 : Icons.visibility_off_rounded,
                  //             size: 24,
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // S.h(32.0),
                  // GestureDetector(
                  //   // onTap: () => Navigator.push(
                  //   //   context,
                  //   //   MaterialPageRoute(
                  //   //       builder: (context) => const ForgotPasswordPage()),
                  //   // ),
                  //   child: Text("ลืมรหัสผ่าน",
                  //       style: CustomStyles.med16GreenUnderline),
                  // ),
                  // S.h(32.0),
                  // InkWell(
                  //   onTap: () {
                  //     // if (email.text == 'tutor') {
                  //     //   Navigator.push(
                  //     //     context,
                  //     //     MaterialPageRoute(
                  //     //         builder: (context) => const MainTabPage()),
                  //     //   );
                  //     // } else {
                  //     //   Navigator.push(
                  //     //     context,
                  //     //     MaterialPageRoute(
                  //     //         builder: (context) =>
                  //     //             const OnBoardingSettingPage()),
                  //     //   );
                  //     // }
                  //   },
                  //   child: Container(
                  //     width: 174.0,
                  //     height: 40.0,
                  //     decoration: BoxDecoration(
                  //       color: CustomColors.greenPrimary,
                  //       borderRadius: BorderRadius.circular(8.0),
                  //     ),
                  //     child: Center(
                  //       child: Text('ลงชื่อเข้าใช้',
                  //           style: CustomStyles.med14White),
                  //     ),
                  //   ),
                  // ),
                  // S.h(32.0),
                  // Container(
                  //   height: 1,
                  //   width: 368,
                  //   color: CustomColors.grayF3F3F3,
                  // ),
                  // S.h(40.0),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     Text("หากคุณเข้าใช้  Solve ครั้งแรก?",
                  //         style: CustomStyles.bold16Black363636),
                  //     S.w(16.0),
                  //     GestureDetector(
                  //       // onTap: () => Navigator.push(
                  //       //   context,
                  //       //   MaterialPageRoute(
                  //       //       builder: (context) =>
                  //       //           const CreateAccountPage()),
                  //       // ),
                  //       child: Text("สร้างบัญชี",
                  //           style: CustomStyles.med16GreenUnderline),
                  //     ),
                  //   ],
                  // ),
                  // S.h(24.0),
                ],
              ),
            ),
          )),
    );
  }

  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  // Widget _buildFormWidget() {
  //   return AutofillGroup(
  //     child: Column(
  //       children: [
  //         AppTextField(
  //           textFieldType: TextFieldType.EMAIL,
  //           controller: _email,
  //           // focus: emailFocus,
  //           // nextFocus: passwordFocus,
  //           // errorThisFieldRequired: language.requiredText,
  //           decoration: inputDecoration(context, labelText: "Email"),
  //           // suffix: ic_message.iconImage(size: 10).paddingAll(14),
  //           autoFillHints: [AutofillHints.email],
  //         ),
  //         16.height,
  //         AppTextField(
  //           textFieldType: TextFieldType.PASSWORD,
  //           controller: _password,
  //           // focus: passwordFocus,
  //           // suffixPasswordVisibleWidget:
  //           //     ic_show.iconImage(size: 10).paddingAll(14),
  //           // suffixPasswordInvisibleWidget:
  //           //     ic_hide.iconImage(size: 10).paddingAll(14),
  //           decoration: inputDecoration(context, labelText: "Password"),
  //           autoFillHints: [AutofillHints.password],
  //           onFieldSubmitted: (s) {
  //             // loginUsers();
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildRememberWidget() {
  //   return Column(
  //     children: [
  //       8.height,
  //       // Row(
  //       //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       //   children: [
  //       //     RoundedCheckBox(
  //       //       borderColor: context.primaryColor,
  //       //       checkedColor: context.primaryColor,
  //       //       // isChecked: isRemember,
  //       //       text: "Remember Me",
  //       //       textStyle: secondaryTextStyle(),
  //       //       size: 20,
  //       //       onTap: (value) async {
  //       //         // await setValue(IS_REMEMBERED, isRemember);
  //       //         // isRemember = !isRemember;
  //       //         // setState(() {});
  //       //       },
  //       //     ),
  //       //     TextButton(
  //       //       onPressed: () {
  //       //         // showInDialog(
  //       //         //   context,
  //       //         //   contentPadding: EdgeInsets.zero,
  //       //         //   dialogAnimation: DialogAnimation.SLIDE_TOP_BOTTOM,
  //       //         //   builder: (_) => ForgotPasswordScreen(),
  //       //         // );
  //       //       },
  //       //       child: Text(
  //       //         "Forgot Password",
  //       //         style: boldTextStyle(
  //       //             color: ColorConstants.primaryColor,
  //       //             fontStyle: FontStyle.italic),
  //       //         textAlign: TextAlign.right,
  //       //       ),
  //       //     ).flexible(),
  //       //   ],
  //       // ),
  //       24.height,
  //       AppButton(
  //         text: "Sign In",
  //         color: ColorConstants.primaryColor,
  //         textColor: Colors.white,
  //         width: context.width() - context.navigationBarHeight,
  //         onTap: () {
  //           // loginUsers();
  //           authprovider!.logIn(_email.text, _password.text).then(
  //             (user) {
  //               if (user != null) {
  //                 Navigator.pushReplacement(context,
  //                     MaterialPageRoute(builder: (context) => Authenticate()));
  //                 print("Account Created Sucessfull");
  //               } else {
  //                 print("Login Failed");
  //               }
  //             },
  //           );
  //         },
  //       ),
  //       16.height,
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Text("Don't have an account?", style: secondaryTextStyle()),
  //           TextButton(
  //             onPressed: () {
  //               // hideKeyboard(context);
  //               // SignUpScreen().launch(context);
  //               var route =
  //                   MaterialPageRoute(builder: (context) => RegisterPage());
  //               Navigator.push(context, route);
  //             },
  //             child: Text(
  //               "Sign Up",
  //               style: boldTextStyle(
  //                 color: ColorConstants.primaryColor,
  //                 decoration: TextDecoration.underline,
  //                 fontStyle: FontStyle.italic,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }
}
