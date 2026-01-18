import 'package:flutter/material.dart';
import '../routes.dart';

class UploadResumeScreen extends StatefulWidget {
  const UploadResumeScreen({super.key});

  @override
  State<UploadResumeScreen> createState() => _UploadResumeScreenState();
}

class _UploadResumeScreenState extends State<UploadResumeScreen> {
  bool _isUploaded = false;
  String _fileName = 'resume.pdf';
  bool _isNavigating = false;

  void _handleUpload() {
    setState(() {
      _isUploaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Resume'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _isUploaded ? Colors.green : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: InkWell(
                  onTap: _isUploaded ? null : _handleUpload,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    width: double.infinity,
                    child: Column(
                      children: [
                        Icon(
                          Icons.description,
                          size: 64,
                          color: _isUploaded
                              ? Colors.green
                              : const Color(0xFF001F3F),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isUploaded ? _fileName : 'Upload Resume (PDF or DOCX)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _isUploaded ? Colors.black87 : Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_isUploaded) ...[
                          const SizedBox(height: 12),
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 32,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isUploaded && !_isNavigating
                      ? () async {
                          setState(() {
                            _isNavigating = true;
                          });
                          await Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.jobDescription,
                          );
                          if (mounted) {
                            setState(() {
                              _isNavigating = false;
                            });
                          }
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF001F3F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
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
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
