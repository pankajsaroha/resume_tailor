import 'dart:math';
import 'package:flutter/material.dart';
import '../models/resume_preview.dart';
import '../routes.dart';
import '../services/firestore_service.dart';

class JobDescriptionScreen extends StatefulWidget {
  const JobDescriptionScreen({super.key});

  @override
  State<JobDescriptionScreen> createState() => _JobDescriptionScreenState();
}

class _JobDescriptionScreenState extends State<JobDescriptionScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isNavigating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Description'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: 'Paste job description here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_controller.text.length} characters',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 80), // Space for fixed button
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isNavigating
                      ? null
                      : () async {
                          setState(() {
                            _isNavigating = true;
                          });
                          final preview = ResumePreview.mock();
                          final requestId = _generateRequestId();
                          final saved =
                              await FirestoreService.instance.saveJobRequest(
                            preview: preview,
                            jobDescription: _controller.text.trim(),
                            requestId: requestId,
                          );
                          if (!saved && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Network error. Try again.'),
                              ),
                            );
                          }
                          await Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.processing,
                            arguments: {
                              'preview': preview,
                              'requestId': requestId,
                              'jobDescription': _controller.text.trim(),
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
                      : const Text(
                          'Tailor Resume',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _generateRequestId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(1000000).toString().padLeft(6, '0');
    return 'req_$now$rand';
  }
}
