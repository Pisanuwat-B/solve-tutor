import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
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
      var user = await signInWithGoogle();
      if (user != null) {
        dev.log('\nUser: ${user.user}');
        // log('\nUserAdditionalInfo: ${user.additionalUserInfo}');
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

  // Future<UserCredential?> _signInWithGoogle() async {
  //   await InternetAddress.lookup('google.com');
  //   final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
  //   final GoogleSignInAuthentication? googleAuth =
  //       await googleUser?.authentication;
  //   final credential = GoogleAuthProvider.credential(
  //     accessToken: googleAuth?.accessToken,
  //     idToken: googleAuth?.idToken,
  //   );
  //   return await authProvider!.firebaseAuth.signInWithCredential(credential);
  //   // return null;
  // }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await InternetAddress.lookup('google.com');
    } catch (_) {
      dev.log('fail lookup');
      return null;
    }

    final GoogleSignIn g = GoogleSignIn.instance;

    try {
      // 1️⃣ Show the Google-account picker (new 7.x API).
      //    authenticate() throws if the user taps “Cancel”.
      final GoogleSignInAccount account = await g.authenticate(scopeHint: const ['email']);

      // 2️⃣ Tokens are now synchronous.
      final GoogleSignInAuthentication authData = account.authentication;

      // 3️⃣ Build a Firebase credential *with the ID token only*.
      final credential = GoogleAuthProvider.credential(
        idToken: authData.idToken,
      );

      // 4️⃣ Sign in to Firebase & return the result.
      return FirebaseAuth.instance.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      // User cancelled or another G-Sign-In error.
      dev.log('Google sign-in error: ${e.code.name} – ${e.description}');
      return null;
    } catch (e) {
      // Anything else (network, Firebase).
      dev.log('Unexpected sign-in error: $e');
      return null;
    }
  }

  _handleAppleBtnClick() async {
    try {
      var auth = await _signInWithApple();
      if (auth!.user != null) {
        if (await authProvider!.userExists(auth.user!)) {
        } else {
          await authProvider!.createUser(
            id: auth.user!.uid,
            name: auth.user!.displayName ?? "Apple User",
            email: auth.user!.email ?? "",
          );
        }
        authProvider!.getSelfInfo();
      }
    // } catch (e) {
    //   // log('login failed $e');
    //   Dialogs.showSnackbar(context, 'Login failed');
    // }
    } on FirebaseAuthException catch (e) {
      dev.log('FirebaseAuthException: ${e.code} – ${e.message}');
      Dialogs.showSnackbar(context, 'Login failed');
    } on SignInWithAppleAuthorizationException catch (e) {
      dev.log('Apple auth error: ${e.code} – ${e.message}');
      Dialogs.showSnackbar(context, 'Login failed');
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final rand = Random.secure();
    return List.generate(length, (_) => charset[rand.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Map<String, dynamic> _decodeJwt(String jwt) {
    final parts = jwt.split('.');
    String _decode(String str) {
      str = str.replaceAll('-', '+').replaceAll('_', '/');
      switch (str.length % 4) {
        case 2: str += '=='; break;
        case 3: str += '='; break;
      }
      return utf8.decode(base64.decode(str));
    }
    return json.decode(_decode(parts[1])) as Map<String, dynamic>;
  }

  Future<UserCredential?> _signInWithApple() async {
    final app = Firebase.app();
    final o = app.options;
    dev.log('FB projectId=${o.projectId} appId=${o.appId} iosBundleId=${o.iosBundleId}');

    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      nonce: hashedNonce,
    );
    dev.log('Apple idToken present? ${appleCredential.identityToken != null}');
    final payload = _decodeJwt(appleCredential.identityToken!);
    dev.log('Apple JWT aud=${payload["aud"]} iss=${payload["iss"]}');
    dev.log('Apple JWT nonce claim=${payload["nonce"]}');
    dev.log('Hashed we sent     =$hashedNonce');
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
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
