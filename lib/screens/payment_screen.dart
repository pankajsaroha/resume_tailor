import 'package:flutter/material.dart';
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
                '₹99',
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
                          final marked = await PaymentService.instance.markPaid(
                            requestId: requestId,
                          );
                          if (!marked && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Payment failed. Try again.'),
                              ),
                            );
                          }
                          await Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.success,
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

}
