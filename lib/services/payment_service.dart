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
    return null;
  }

  Future<bool> verifyPayment({
    required String requestId,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    await AuthService.instance.ensureAuthenticated();
    return false;
  }
}
