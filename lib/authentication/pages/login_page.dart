import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:solve_tutor/widgets/dialogs.dart';

import '../../feature/calendar/constants/custom_colors.dart';
import '../../feature/calendar/constants/custom_styles.dart';
import '../../feature/calendar/widgets/sizebox.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  _handleGoogleBtnClick() async {
    try {
      // Dialogs.showProgressBar(context);
      var user = await _signInWithGoogle();
      if (user != null) {
        // log('\nUser: ${user.user}');
        // log('\nUserAdditionalInfo: ${user.additionalUserInfo}');
        authProvider!.updateUserToken(user.user!.uid);
        if (await authProvider!.userExists(user.user!)) {
        } else {
          await authProvider!.createUser(
            id: user.user?.uid ?? "",
            name: user.user?.displayName ?? "",
            email: user.user?.email ?? "",
            image: user.user?.photoURL ?? "",
          );
        }
        authProvider!.getSelfInfo();
        // var route =
        //     MaterialPageRoute(builder: (context) => const Authenticate());
        // Navigator.pushReplacement(context, route);
      }
    } catch (e) {
      Dialogs.showSnackbar(context, 'Login failed');
    }
  }

  Future<UserCredential?> _signInWithGoogle() async {
    await InternetAddress.lookup('google.com');
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    return await authProvider!.firebaseAuth.signInWithCredential(credential);
  }

  _handleAppleBtnClick() async {
    try {
      var auth = await _signInWithApple();
      if (auth!.user != null) {
        // log('\nUser: ${auth!.user}');
        if (await authProvider!.userExists(auth.user!)) {
        } else {
          await authProvider!.createUser(
            id: auth.user!.uid,
            name: auth.user!.displayName ?? "",
            email: auth.user!.email ?? "",
          );
        }
        authProvider!.getSelfInfo();
      }
    } catch (e) {
      log("catch _handleAppleBtnClick : $e");
      Dialogs.showSnackbar(context, 'Login failed');
    }
  }

  Future<UserCredential?> _signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName
      ],
    );
    // Create an `OAuthCredential` from the credential returned by Apple.
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
    );
    final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    return userCredential;
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
                  Column(
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
                      S.h(16.0),
                      // Login with Apple ID
                      Platform.isIOS
                          ? InkWell(
                              onTap: () {
                                _handleAppleBtnClick();
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
                                      'assets/images/ic_apple.png',
                                      width: 19.56,
                                      height: 24,
                                    ),
                                    S.w(16.0),
                                    Text("Apple",
                                        style: CustomStyles.med14Black363636)
                                  ],
                                ),
                              ),
                            )
                          : Container(),
                    ],
                  ),
                  S.h(32.0),
                ],
              ),
            ),
          )),
    );
  }
}
