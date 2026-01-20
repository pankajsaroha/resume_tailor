import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';

class PaymentService {
  PaymentService._();

  static final PaymentService instance = PaymentService._();

  Future<Map<String, dynamic>?> createPaymentOrder({
    required String requestId,
    required int amount,
    required String currency,
  }) async {
    await AuthService.instance.ensureAuthenticated();
    try {
      final callable = FirebaseFunctions.instanceFor(
        app: Firebase.app(),
        region: 'us-central1',
      ).httpsCallable('createPaymentOrder');
      final result = await callable.call({
        'requestId': requestId,
        'amount': amount,
        'currency': currency,
      });
      final data = result.data as Map<String, dynamic>?;
      debugPrint('createPaymentOrder response: $data');
      return data;
    } on FirebaseFunctionsException catch (error) {
      debugPrint('createPaymentOrder error: ${error.code} ${error.message}');
      debugPrint('createPaymentOrder details: ${error.details}');
    } catch (error) {
      debugPrint('createPaymentOrder error: $error');
    }
    return null;
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String requestId,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    await AuthService.instance.ensureAuthenticated();
    try {
      final callable = FirebaseFunctions.instanceFor(
        app: Firebase.app(),
        region: 'us-central1',
      ).httpsCallable('verifyPayment');
      final result = await callable.call({
        'requestId': requestId,
        'orderId': orderId,
        'paymentId': paymentId,
        'signature': signature,
      });
      final data = result.data as Map<String, dynamic>?;
      debugPrint('verifyPayment response: $data');
      return data ?? {'verified': false, 'message': 'Payment failed'};
    } on FirebaseFunctionsException catch (error) {
      debugPrint('verifyPayment error: ${error.code} ${error.message}');
      debugPrint('verifyPayment details: ${error.details}');
      final details = error.details;
      if (details is Map && details['message'] != null) {
        return {
          'verified': false,
          'message': details['message'],
        };
      }
      return {
        'verified': false,
        'message': error.message ?? 'Payment failed',
      };
    } catch (error) {
      debugPrint('verifyPayment error: $error');
    }
    return {'verified': false, 'message': 'Payment failed'};
  }
}
