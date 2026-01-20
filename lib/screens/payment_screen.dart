import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/resume_preview.dart';
import '../routes.dart';
import '../services/firestore_service.dart';
import '../services/payment_service.dart';
import '../widgets/bullet_point_row.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isNavigating = false;
  late final Razorpay _razorpay;
  String? _currentOrderId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final preview = args?['preview'] as ResumePreview?;
    final requestId = args?['requestId'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: StreamBuilder<bool>(
            stream: requestId == null
                ? null
                : FirestoreService.instance.paidStream(requestId),
            builder: (context, snapshot) {
              final paid = snapshot.data == true;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              const Text(
                '₹9',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF001F3F),
                ),
              ),
              const SizedBox(height: 48),
              const BulletPointRow(text: 'Job specific resume'),
              const SizedBox(height: 16),
              const BulletPointRow(text: 'ATS optimized'),
              const SizedBox(height: 16),
              const BulletPointRow(text: 'Instant download'),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isNavigating || paid
                      ? null
                      : () async {
                          if (kIsWeb) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Payments are not supported on web.',
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _isNavigating = true;
                          });
                          if (requestId == null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Missing request. Try again.'),
                                ),
                              );
                            }
                            if (mounted) {
                              setState(() {
                                _isNavigating = false;
                              });
                            }
                            return;
                          }
                          final order =
                              await PaymentService.instance.createPaymentOrder(
                            requestId: requestId,
                            amount: 900,
                            currency: 'INR',
                          );
                          if (order == null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Payment failed. Try again.'),
                                ),
                              );
                              setState(() {
                                _isNavigating = false;
                              });
                            }
                            return;
                          }
                          debugPrint('Order creation response: $order');
                          _currentOrderId = order['orderId'] as String?;
                          final keyId = order['keyId'] as String?;
                          final amount = order['amount'] as int? ?? 900;
                          final currency =
                              order['currency'] as String? ?? 'INR';
                          if (_currentOrderId == null || keyId == null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Payment failed. Try again.'),
                                ),
                              );
                              setState(() {
                                _isNavigating = false;
                              });
                            }
                            return;
                          }
                          final options = {
                            'key': keyId,
                            'amount': amount,
                            'currency': currency,
                            'name': 'Resume Tailor',
                            'order_id': _currentOrderId,
                          };
                          _razorpay.open(options);
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF001F3F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isNavigating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          paid ? 'Paid' : 'Pay via UPI',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final preview = args?['preview'] as ResumePreview?;
    final requestId = args?['requestId'] as String?;
    if (requestId == null ||
        response.paymentId == null ||
        response.signature == null ||
        _currentOrderId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment verification failed.'),
          ),
        );
        setState(() {
          _isNavigating = false;
        });
      }
      return;
    }
    debugPrint('Razorpay success: '
        'paymentId=${response.paymentId}, '
        'orderId=$_currentOrderId, '
        'signature=${response.signature}');
    final verification = await PaymentService.instance.verifyPayment(
      requestId: requestId,
      orderId: _currentOrderId!,
      paymentId: response.paymentId!,
      signature: response.signature!,
    );
    debugPrint('verifyPayment response: $verification');
    if (verification['verified'] != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              verification['message']?.toString() ??
                  'Payment verification failed.',
            ),
          ),
        );
        setState(() {
          _isNavigating = false;
        });
      }
      return;
    }
    if (!mounted) {
      return;
    }
    await Navigator.pushReplacementNamed(
      context,
      AppRoutes.preview,
      arguments: {
        'preview': preview,
        'requestId': requestId,
      },
    );
    if (mounted) {
      setState(() {
        _isNavigating = false;
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint(
      'Razorpay error: code=${response.code} message=${response.message}',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message?.isNotEmpty == true
                ? response.message!
                : 'Payment failed. Try again.',
          ),
        ),
      );
      setState(() {
        _isNavigating = false;
      });
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

}
