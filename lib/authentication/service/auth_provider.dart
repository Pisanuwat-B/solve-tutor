import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:solve_tutor/authentication/models/user_model.dart';
import 'package:solve_tutor/authentication/service/fcm.dart';

class AuthProvider extends ChangeNotifier {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  UserModel? user;
  String? uid;

  getSelfInfo() async {
    // log("getSelfInfo");
    uid = firebaseAuth.currentUser?.uid ?? "";
    await firebaseFirestore
        .collection('users')
        .doc(uid)
        .get()
        .then((userFirebase) async {
      if (userFirebase.exists) {
        user = UserModel.fromJson(userFirebase.data()!);
        // await getFirebaseMessagingToken();
        //for setting user status to active
        // updateActiveStatus(true);
        if (user?.role == null || user?.role == "") {
          await updateRoleFirestore('tutor');
        }
        // log('My Data: ${userFirebase.data()}');
        notifyListeners();
      }
    });
  }

  Future<bool> userExists(User userIn) async {
    return (await firebaseFirestore.collection('users').doc(userIn.uid).get())
        .exists;
  }

  Future<void> updateActiveStatus(bool isOnline) async {
    firebaseFirestore.collection('users').doc(uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': user?.pushToken,
    });
    notifyListeners();
  }

  signOut() async {
    await firebaseAuth.signOut();
    await GoogleSignIn().signOut();
    user = null;
    uid = null;
    notifyListeners();
  }

  createUser({
    required String id,
    required String name,
    required String email,
    String? image,
  }) async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final String deviceToken = await FCMServices().getDeviceToken();
    final chatUser = UserModel(
      id: id,
      name: name,
      email: email,
      about: "Hey, I'm here",
      image: image ?? "",
      createdAt: time,
      isOnline: false,
      lastActive: time,
      pushToken: deviceToken,
      role: '',
    );
    user = chatUser;
    await firebaseFirestore.collection('users').doc(id).set(chatUser.toJson());
    notifyListeners();
  }

  Future<void> updateRoleFirestore(String role) async {
    // log("updateRoleFirestore ${user?.id}");
    final CollectionReference users = firebaseFirestore.collection("users");
    final String uid = firebaseAuth.currentUser?.uid ?? '';
    await users.doc(uid).update({'role': role});
    final result = await users.doc(uid).get();
    await getSelfInfo();
    // log("result $result");
    notifyListeners();
    // return await firebaseFirestore
    //     .collection('users')
    //     .doc(user!.id)
    //     .update({'role': role});
  }

  // --------------more--------------------------
  Future<UserModel?> createAccount(
      String name, String email, String password) async {
    FirebaseAuth _auth = FirebaseAuth.instance;
    FirebaseFirestore _firestore = FirebaseFirestore.instance;
    try {
      UserCredential userCrendetial = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      userCrendetial.user!.updateDisplayName(name);
      final time = DateTime.now().millisecondsSinceEpoch.toString();
      final String deviceToken = await FCMServices().getDeviceToken();

      final chatUser = UserModel(
        id: _auth.currentUser!.uid,
        name: name,
        email: email,
        about: "I'm new.",
        image: "",
        createdAt: time,
        isOnline: false,
        lastActive: time,
        pushToken: deviceToken,
        role: 'tutor',
      );
      user = chatUser;
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .set(user!.toJson());
      if (user?.role == null || user?.role == "") {
        await updateRoleFirestore('tutor');
      }
      notifyListeners();
      return user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<User?> logIn(String email, String password) async {
    FirebaseAuth _auth = FirebaseAuth.instance;
    FirebaseFirestore _firestore = FirebaseFirestore.instance;
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      print("Login Sucessfull");
      _firestore.collection('users').doc(_auth.currentUser!.uid).get().then(
              (value) => {
            print("value: ${value.id}"),
            updateUserToken(value.id),
            userCredential.user!.updateDisplayName(value['name'])
          });
      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  updateUserToken(String userId) async {
    try {
      final String deviceToken = await FCMServices().getDeviceToken();
      FirebaseFirestore _firestore = FirebaseFirestore.instance;
      print("updateUserToken: $deviceToken");
      await _firestore.collection('users').doc(userId).update({
        'push_token': deviceToken,
      });
    } catch (err) {
      print('Error updating field: $err');
    }
  }

  deleteAccount() async {
    try {
      await firebaseFirestore.collection('users').doc(uid).update({
        'is_deleted': true,
      });
      signOut();
    } catch (e) {
      log("e : $e");
    }
  }
}
