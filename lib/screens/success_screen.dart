import 'package:flutter/material.dart';
import '../models/resume_preview.dart';
import '../routes.dart';
import '../services/pdf_service.dart';
import '../services/firestore_service.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final preview = args?['preview'] as ResumePreview?;
    final __ = args?['requestId'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Success'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: StreamBuilder<bool>(
            stream: __ == null
                ? null
                : FirestoreService.instance.paidStream(__),
            builder: (context, snapshot) {
              final paid = snapshot.data == true;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              const Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              const Text(
                'Your resume is ready',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF001F3F),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isDownloading || !paid || preview == null || __ == null
                      ? null
                      : () async {
                          setState(() {
                            _isDownloading = true;
                          });
                          final message = await PdfService.generateAndSave(
                            preview: preview,
                            requestId: __,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message),
                              ),
                            );
                          }
                          if (mounted) {
                            setState(() {
                              _isDownloading = false;
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
                  child: _isDownloading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          paid ? 'Download PDF' : 'Payment Pending',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.home,
                    (route) => false,
                  );
                },
                child: const Text(
                  'Tailor another resume',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF001F3F),
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
