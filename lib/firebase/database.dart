import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class FirebaseService {
  final db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getUserById(userId) async {
    final collectionRef = db.collection('users');
    try {
      final snapshot = await collectionRef.doc(userId).get();
      if (snapshot.exists) {
        final user = snapshot.data()!;
        return user;
      } else {
        log('Document does not exist');
        return {};
      }
    } catch (e) {
      log('Error getting course: $e');
      return {};
    }
  }

  Future<String> writeSolvepadData(String texUrl, String audioUrl) async {
    final collectionRef = db.collection('solvepad');
    DocumentReference documentReference = await collectionRef.add({
      'solvepad': texUrl,
      'voice': audioUrl,
    });
    return documentReference.id;
  }

  Future<List<String>> uploadMarketSolvepad(String fileName) async {
    final storageRef = FirebaseStorage.instance.ref();
    final tempDirectory = await getTemporaryDirectory();

    final solvepadRef = storageRef.child("marketplace/$fileName.txt");
    String localSolvepadPath = '${tempDirectory.path}/solvepad.txt';
    File solvepadFile = File(localSolvepadPath);

    final voiceRef = storageRef.child("marketplace/$fileName.mp4");
    String localVoicePath = '${tempDirectory.path}/tau_file.mp4';
    File voiceFile = File(localVoicePath);

    log('file status :${await solvepadFile.exists()},${await voiceFile.exists()}');
    // check record next.
    if (!(await solvepadFile.exists() || await voiceFile.exists())) {
      throw Exception("File does not exist");
    } else {
      log('file exist');
    }
    final voiceFileSize = await voiceFile.length();
    if (voiceFileSize == 0) {
      throw Exception("File is empty");
    } else {
      log('fileSize $voiceFileSize');
    }

    TaskSnapshot solvepadSnapshot = await solvepadRef.putFile(solvepadFile);
    final String solvepadUrl = await solvepadSnapshot.ref.getDownloadURL();
    TaskSnapshot voiceSnapshot = await voiceRef.putFile(voiceFile);
    final String voiceUrl = await voiceSnapshot.ref.getDownloadURL();

    return [solvepadUrl, voiceUrl];
  }

  Future<dynamic> getMarketCourseSolvepadData(String solvepadId) async {
    final collectionRef = db.collection('solvepad');
    String voiceUrl = '';
    Map<String, dynamic> solvepadData;

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/downloadedSolvepad.txt');

    final event = await collectionRef.doc(solvepadId).get();
    voiceUrl = (event.data() as Map)['voice'];
    var solvepadUrl = (event.data() as Map)['solvepad'];
    final url = Uri.parse(solvepadUrl);
    final response = await http.get(url);
    await file.writeAsBytes(response.bodyBytes);
    var fileContent = await file.readAsString();
    solvepadData = json.decode(fileContent);

    return [solvepadData, voiceUrl];
  }

  Future<String> getMarketCourseAudioFile(fileURL) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/solve_voice.mp4');
    final url = Uri.parse(fileURL);
    final response = await http.get(url);
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  }

  Future<String> uploadLiveSolvepad(String fileName) async {
    final storageRef = FirebaseStorage.instance.ref();
    final tempDirectory = await getTemporaryDirectory();

    final solvepadRef = storageRef.child("solve_live/$fileName.txt");
    String localSolvepadPath = '${tempDirectory.path}/solvepad.txt';
    File solvepadFile = File(localSolvepadPath);

    TaskSnapshot solvepadSnapshot = await solvepadRef.putFile(solvepadFile);
    final String solvepadUrl = await solvepadSnapshot.ref.getDownloadURL();

    return solvepadUrl;
  }

  Future<String> getRecordCourseTutorialUrl() async {
    try {
      DocumentReference<Object?> docRef = FirebaseFirestore.instance
          .collection('external_info')
          .doc('solveExternalUrl');
      DocumentSnapshot<Object?> docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        Map<String, dynamic>? data =
            docSnapshot.data() as Map<String, dynamic>?;
        return data?['tut_record_course'] as String;
      } else {
        log("Document does not exist");
        return '';
      }
    } catch (e) {
      log("Error fetching data from Firestore: $e");
      return '';
    }
  }
}
