import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:solve_tutor/auth.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/constants/theme.dart';
import 'package:solve_tutor/widgets/dialogs.dart';
import 'package:solve_tutor/widgets/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

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
        if (await authprovider!.userExists(user.user!)) {
        } else {
          await authprovider!.createUser(user.user!);
        }
        authprovider!.getSelfInfo();
        // var route =
        //     MaterialPageRoute(builder: (context) => const Authenticate());
        // Navigator.pushReplacement(context, route);
      }
    });
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      await InternetAddress.lookup('google.com');
      log('\nhere');
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      log('\nhere1');
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;
      log('\nhere2');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      return await authprovider!.firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      log('\n_signInWithGoogle: $e');
      Dialogs.showSnackbar(context, 'Something Went Wrong (Check Internet!)');
      return null;
    }
  }

  AuthProvider? authprovider;
  @override
  Widget build(BuildContext context) {
    authprovider = Provider.of<AuthProvider>(context);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Container(
          margin: const EdgeInsets.fromLTRB(20, 5, 20, 5),
          child: Column(
            children: <Widget>[
              SizedBox(height: Sizer(context).h * 0.2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(
                    "Welcome in Tutor Application",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // _buildFormWidget(),
              // _buildRememberWidget(),
              // const SizedBox(height: 20),
              Row(
                children: const [
                  Expanded(
                    child: Divider(
                      thickness: 1,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: Text("Or Continue With"),
                  ),
                  Expanded(
                    child: Divider(
                      thickness: 1,
                      height: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  _handleGoogleBtnClick();
                },
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      // GoogleLogoWidget(size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Sign in with Google',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Loading
              // Positioned(
              //   child: authProvider.status == Status.authenticating
              //       ? LoadingView()
              //       : SizedBox.shrink(),
              // ),
            ],
          ),
        ),
      ),
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
