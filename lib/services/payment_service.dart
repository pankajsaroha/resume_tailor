import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';

class PaymentService {
  PaymentService._();

  static final PaymentService instance = PaymentService._();

  Future<bool> markPaid({required String requestId}) async {
    await AuthService.instance.signInAnonymously();
    try {
      await FirebaseFirestore.instance
          .collection('resumeRequests')
          .doc(requestId)
          .set(
        {
          'paid': true,
          'paidAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return true;
    } catch (error) {
    }
    return false;
  }
}
