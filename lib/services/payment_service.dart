import 'package:cloud_functions/cloud_functions.dart';

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
      final callable =
          FirebaseFunctions.instance.httpsCallable('createPaymentOrder');
      final result = await callable.call({
        'requestId': requestId,
        'amount': amount,
        'currency': currency,
      });
      return result.data as Map<String, dynamic>?;
    } on FirebaseFunctionsException {
    } catch (error) {
    }
    return null;
  }

  Future<bool> verifyPayment({
    required String requestId,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    await AuthService.instance.ensureAuthenticated();
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('verifyPayment');
      final result = await callable.call({
        'requestId': requestId,
        'orderId': orderId,
        'paymentId': paymentId,
        'signature': signature,
      });
      final data = result.data as Map<String, dynamic>?;
      return data?['verified'] == true;
    } catch (error) {
    }
    return false;
  }
}
