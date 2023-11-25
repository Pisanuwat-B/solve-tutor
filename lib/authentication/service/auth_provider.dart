import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:solve_tutor/authentication/models/user_model.dart';
import 'package:solve_tutor/authentication/models/wallet.model.dart';
import 'package:solve_tutor/firebase/firestore.dart';

class AuthProvider extends ChangeNotifier {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  WalletModel? wallet;
  UserModel? user;
  String? uid;
  bool isLoading = true;
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
        await getWallet();
        // log('My Data: ${userFirebase.data()}');
      }
    });
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    isLoading = false;
    notifyListeners();
  }

  getWallet() async {
    uid = firebaseAuth.currentUser?.uid ?? "";
    await firebaseFirestore
        .collection('wallet')
        .doc(uid)
        .get()
        .then((walletFirebase) async {
      if (walletFirebase.exists) {
        wallet = WalletModel.fromJson(walletFirebase.data()!);
        notifyListeners();
      }else{
        await updateWallet();
      }
    });
  }

  Future<void> updateLiveDuration(
    int duration,
  ) async {
    try {
      uid = firebaseAuth.currentUser?.uid ?? "";
      final users = FirestoreService('users');
      Map<String, dynamic> body = {
        "id": uid,
        "tutor_id": uid,
        "update_data": {"live_duration": duration}
      };
      await users.updateDocumentById(
          body['id'], body['update_data'], body['tutor_id']);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateWalletBalance(
    int value,
    int duration,
  ) async {
    try {
      uid = firebaseAuth.currentUser?.uid ?? "";
      final wallet = FirestoreService('wallet');
      Map<String, dynamic> body = {
        "id": uid,
        "tutor_id": uid,
        "update_data": {"balance": value, 'live_duration': duration}
      };
      await wallet.updateDocumentById(
          body['id'], body['update_data'], body['tutor_id']);
    } catch (error) {
      rethrow;
    }
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
    final chatUser = UserModel(
      id: id,
      name: name,
      email: email,
      about: "Hey, I'm here",
      image: image ?? "",
      createdAt: time,
      isOnline: false,
      lastActive: time,
      pushToken: '',
      role: '',
    );
    user = chatUser;
    await firebaseFirestore.collection('users').doc(id).set(chatUser.toJson());
    await updateWallet();
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

  Future<void> updateWallet() async {
    final CollectionReference users = firebaseFirestore.collection("wallet");
    final String uid = firebaseAuth.currentUser?.uid ?? '';
    WalletModel only = WalletModel(uid: uid, balance: 400, liveDuration: 0);
    users.doc(uid).set(only.toJson());
    notifyListeners();
  }

  // --------------more--------------------------
  // Future<UserModel?> createAccount(
  //     String name, String email, String password) async {
  //   FirebaseAuth _auth = FirebaseAuth.instance;
  //   FirebaseFirestore _firestore = FirebaseFirestore.instance;
  //   try {
  //     UserCredential userCrendetial = await _auth
  //         .createUserWithEmailAndPassword(email: email, password: password);
  //     userCrendetial.user!.updateDisplayName(name);
  //     final time = DateTime.now().millisecondsSinceEpoch.toString();
  //     final chatUser = UserModel(
  //       id: _auth.currentUser!.uid,
  //       name: name,
  //       email: email,
  //       about: "I'm new.",
  //       image: "",
  //       createdAt: time,
  //       isOnline: false,
  //       lastActive: time,
  //       pushToken: '',
  //       role: 'tutor',
  //     );
  //     user = chatUser;
  //     await _firestore
  //         .collection('users')
  //         .doc(_auth.currentUser!.uid)
  //         .set(user!.toJson());
  //     if (user?.role == null || user?.role == "") {
  //       await updateRoleFirestore('tutor');
  //     }
  //     updateWallet();
  //     notifyListeners();
  //     return user;
  //   } catch (e) {
  //     print(e);
  //     return null;
  //   }
  // }

  Future<User?> logIn(String email, String password) async {
    FirebaseAuth _auth = FirebaseAuth.instance;
    FirebaseFirestore _firestore = FirebaseFirestore.instance;
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      print("Login Sucessfull");
      _firestore.collection('users').doc(_auth.currentUser!.uid).get().then(
          (value) => userCredential.user!.updateDisplayName(value['name']));
      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
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
