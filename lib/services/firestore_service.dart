import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/resume_preview.dart';
import 'auth_service.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  Future<bool> createRequestWithResumeText({
    required String resumeText,
    required String requestId,
  }) async {
    await AuthService.instance.ensureAuthenticated();
    try {
      await FirebaseFirestore.instance
          .collection('resumeRequests')
          .doc(requestId)
          .set({
        'resumeText': resumeText,
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

  Future<bool> verifyResumeTextStored({
    required String requestId,
    required String resumeText,
  }) async {
    await AuthService.instance.ensureAuthenticated();
    try {
      final doc = await FirebaseFirestore.instance
          .collection('resumeRequests')
          .doc(requestId)
          .get();
      final stored = doc.data()?['resumeText'] as String?;
      return stored != null && stored.trim() == resumeText.trim();
    } catch (error) {
    }
    return false;
  }

  Future<bool> updateJobDescription({
    required String jobDescription,
    required String requestId,
  }) async {
    await AuthService.instance.ensureAuthenticated();
    try {
      await FirebaseFirestore.instance
          .collection('resumeRequests')
          .doc(requestId)
          .set(
        {
          'jobDescription': jobDescription,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return true;
    } catch (error) {
    }
    return false;
  }

  Future<bool> saveResumePreview({
    required ResumePreview preview,
    required String requestId,
  }) async {
    await AuthService.instance.ensureAuthenticated();
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
    await AuthService.instance.ensureAuthenticated();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Auth required');
    }
    await user.getIdToken(true);
    await user.reload();
    await FirebaseAuth.instance.idTokenChanges().firstWhere(
      (u) => u?.uid == user.uid,
    );
    debugPrint('AI request start (uid=${user.uid})');
    final callable = FirebaseFunctions.instanceFor(
      app: Firebase.app(),
      region: 'us-central1',
    ).httpsCallable('generateTailoredResumeAI');
    Future<Map<String, dynamic>?> _invoke() async {
      final result = await callable.call({
        'resumeText': resumeText,
        'jobDescription': jobDescription,
        'requestId': requestId,
      });
      final data = result.data as Map<String, dynamic>;
      debugPrint('AI response received');
      if (data['status'] == 'error') {
        throw Exception(data['message'] ?? 'AI failed');
      }
      if (!data.containsKey('tailoredResume')) {
        throw Exception('AI response missing tailoredResume');
      }
      return {
        'keywordMatch': data['keywordMatch'],
        ...((data['tailoredResume'] as Map).cast<String, dynamic>()),
      };
    }
    try {
      return await _invoke();
    } on FirebaseFunctionsException catch (error) {
      debugPrint('Callable error code: ${error.code}');
      debugPrint('Callable error message: ${error.message}');
      debugPrint('Callable error details: ${error.details}');
      if (error.code == 'unauthenticated') {
        await FirebaseAuth.instance.signOut();
        await AuthService.instance.ensureAuthenticated();
        await FirebaseAuth.instance.currentUser?.getIdToken(true);
        return await _invoke();
      }
      final details = error.details;
      if (details is Map && details['message'] != null) {
        throw Exception(details['message']);
      }
      throw Exception(error.message ?? 'AI request failed');
    }
  }
}
