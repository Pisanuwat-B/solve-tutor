import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:solve_tutor/authentication/models/user_model.dart';
import 'package:solve_tutor/authentication/service/auth_provider.dart';
import 'package:solve_tutor/feature/chat/models/chat_model.dart';
import 'package:solve_tutor/feature/chat/models/message.dart' as messageModel;
import 'package:uuid/uuid.dart';

class ChatProvider extends ChangeNotifier {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  AuthProvider? auth;

  init({AuthProvider? auth}) {
    this.auth = auth;
  }

  // chats (collection) --> conversation_id (doc) --> messages (collection) --> message (doc)
  // useful for getting conversation id
  // String getConversationID(String id) {
  //   return auth!.uid.hashCode <= id.hashCode
  //       ? '${auth?.uid}_$id'
  //       : '${id}_${auth?.uid}';
  // }

  // Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(UserModel user) {
  //   return firebaseFirestore
  //       .collection('chats/${getConversationID(user.id ?? "")}/messages/')
  //       .orderBy('sent', descending: true)
  //       .snapshots();
  // }
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(String chatId) {
    return firebaseFirestore
        .collection('chats/$chatId/messages/')
        .orderBy('sent', descending: true)
        .snapshots();
  }

  Future<void> setMyChat(ChatModel? chatModel) async {
    await firebaseFirestore
        .collection('users')
        .doc(auth?.uid ?? "")
        .collection('my_order_chat')
        .doc(chatModel?.chatId)
        .set({});
  }

  Future<void> sendFirstMessage(
    String chatId,
    String userId,
    String message,
    messageModel.MessageType type,
  ) async {
    await firebaseFirestore
        .collection('users')
        .doc(userId)
        .collection('my_order_chat')
        .doc(chatId)
        .set({}).then((value) => sendMessage(chatId, userId, message, type));
  }

  Future<void> sendMessage(
    String chatId,
    String userId,
    String msg,
    messageModel.MessageType type,
  ) async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final messageModel.Message message = messageModel.Message(
        toId: userId,
        msg: msg,
        read: '',
        type: type,
        fromId: auth?.uid ?? "",
        sent: time);
    final ref = firebaseFirestore.collection('chats/$chatId/messages/');
    await ref.doc(time).set(message.toJson());
    await updateRoomTime(chatId);
  }

  updateRoomTime(String chatId) async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    await firebaseFirestore
        .collection('chats')
        .doc(chatId)
        .update({'updated_at': time});
    notifyListeners();
  }

  Future<void> updateMessageReadStatus(
      String chatId, messageModel.Message message) async {
    firebaseFirestore
        .collection('chats/$chatId/messages/')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(String chatId) {
    return firebaseFirestore
        .collection('chats/$chatId/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  Future<void> sendChatImage(String chatId, String userId, File file) async {
    final ext = file.path.split('.').last;
    final ref = storage
        .ref()
        .child('images/$chatId/${DateTime.now().millisecondsSinceEpoch}.$ext');
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });
    final imageUrl = await ref.getDownloadURL();
    await sendMessage(chatId, userId, imageUrl, messageModel.MessageType.image);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMyChat(String userId) {
    // log("getMyOrderChat : $userId");
    // calChatStack();
    return firebaseFirestore
        .collection('chats')
        .where('tutor_id', isEqualTo: userId)
        .orderBy('updated_at', descending: true)
        .limit(30)
        .snapshots();
  }

  Future<ChatModel?> getChatInfoV2(String chatIds) async {
    try {
      // log('\nchatIds: $chatIds');
      ChatModel? only;
      var data = await firebaseFirestore.collection('chats').doc(chatIds).get();
      // log("message112 ${json.encode(data.data())}");
      var source = data.data();
      only = ChatModel.fromJson(source!);
      log('success');
      return only;
    } catch (e) {
      log("e : $e");
      return null;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getChatInfo(String chatId) {
    return firebaseFirestore
        .collection('chats')
        .where('id', isEqualTo: chatId)
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getOrderInfo(String id) async {
    return await firebaseFirestore.collection('orders').doc(id).get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getTutorInfo(String id) async {
    // log("getTutorInfo : $id");
    return await firebaseFirestore.collection('users').doc(id).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(String id) {
    log("getUserInfo : $id");
    return firebaseFirestore
        .collection('users')
        .where('id', isEqualTo: id)
        .snapshots();
  }

  // Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
  //     List<String> userIds) {
  //   log('\nUserIds: $userIds');
  //   return firebaseFirestore
  //       .collection('users')
  //       .where('id',
  //           whereIn: userIds.isEmpty
  //               ? ['']
  //               : userIds) //because empty list throws an error
  //       // .where('id', isNotEqualTo: user.uid)
  //       .snapshots();
  // }

  Future<bool> addChatUser(String email) async {
    final data = await firebaseFirestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    log('data: ${data.docs}');
    if (data.docs.isNotEmpty && data.docs.first.id != auth?.uid) {
      log('user exists: ${data.docs.first.data()}');
      firebaseFirestore
          .collection('users')
          .doc(auth?.uid)
          .collection('my_users')
          .doc(data.docs.first.id)
          .set({});
      return true;
    } else {
      return false;
    }
  }

  // num stackChat = 0;
  // calChatStack() async {
  //   stackChat = 0;
  //   var chatPath = firebaseFirestore.collection('chats');
  //   var data1 = await chatPath.get();
  //   final List<DocumentSnapshot> doc1 = data1.docs;
  //   for (var i = 0; i < doc1.length; i++) {
  //     log("auth ------ ${auth?.user?.id ?? ""}");
  //     var element1 = doc1[i];
  //     var messagePath = chatPath.doc(element1.id).collection('messages');
  //     var data3Read = await messagePath.where('read', isEqualTo: '').get();
  //     var data3NoteME = await messagePath
  //         .where('fromId', isNotEqualTo: auth?.user?.id ?? "")
  //         .get();
  //     data3Read.docs.addAll(data3NoteME.docs);
  //     log("message id : ${element1.id}, read size : ${data3Read.size}");
  //     stackChat += data3Read.size;
  //   }
  //   log("stackChat : $stackChat");
  // }

  Stream<QuerySnapshot<Map<String, dynamic>>> getStackChat(String chatId) {
    // log('\nchatIds: $chatId');
    return firebaseFirestore
        .collection('chats/$chatId/messages/')
        .where('read', isEqualTo: '')
        .snapshots();
  }
}
