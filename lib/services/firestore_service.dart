import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/resume_preview.dart';
import 'auth_service.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  Future<bool> saveJobRequest({
    required ResumePreview preview,
    required String jobDescription,
    required String requestId,
  }) async {
    await AuthService.instance.signInAnonymously();
    try {
      await FirebaseFirestore.instance
          .collection('resumeRequests')
          .doc(requestId)
          .set({
        ...preview.toMap(),
        'jobDescription': jobDescription,
        'keywordMatch': preview.keywordMatch,
        'requestId': requestId,
        'paid': false,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
      });
      return true;
    } catch (error) {
    }
    return false;
  }

  Future<bool> saveResumePreview({
    required ResumePreview preview,
    required String requestId,
  }) async {
    await AuthService.instance.signInAnonymously();
    try {
      await FirebaseFirestore.instance.collection('resumePreviews').add({
        'keywordMatch': preview.keywordMatch,
        'requestId': requestId,
        ...preview.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
      });
      return true;
    } catch (error) {
    }
    return false;
  }

  Stream<bool> paidStream(String requestId) {
    return FirebaseFirestore.instance
        .collection('resumeRequests')
        .doc(requestId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['paid'] == true);
  }

  Future<Map<String, dynamic>?> callTailorResumeFunction({
    required String resumeText,
    required String jobDescription,
    required String requestId,
  }) async {
    await AuthService.instance.signInAnonymously();
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('tailorResume');
      final result = await callable.call({
        'resumeText': resumeText,
        'jobDescription': jobDescription,
        'requestId': requestId,
      });
      final data = result.data as Map<String, dynamic>?;
      final tailored = data?['tailoredResume'] as Map<String, dynamic>?;
      final keywordMatch = data?['keywordMatch'];
      if (tailored == null) {
        return null;
      }
      return {
        ...tailored,
        'keywordMatch': keywordMatch,
      };
    } on FirebaseFunctionsException catch (error) {
    } catch (error) {
    }
    return null;
  }
}
