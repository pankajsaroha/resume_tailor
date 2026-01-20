import 'package:flutter/material.dart';
import '../routes.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class JobDescriptionScreen extends StatefulWidget {
  const JobDescriptionScreen({super.key});

  @override
  State<JobDescriptionScreen> createState() => _JobDescriptionScreenState();
}

class _JobDescriptionScreenState extends State<JobDescriptionScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isNavigating = false;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateValidity);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateValidity);
    _controller.dispose();
    super.dispose();
  }

  void _updateValidity() {
    final isValid = _controller.text.trim().isNotEmpty;
    if (isValid != _isValid) {
      setState(() {
        _isValid = isValid;
      });
    }
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
                    onChanged: (_) => _updateValidity(),
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
                  onPressed: _isNavigating || !_isValid
                      ? null
                      : () async {
                          try {
                            await AuthService.instance.ensureAuthenticated();
                          } catch (_) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Auth required. Please retry.'),
                                ),
                              );
                            }
                            return;
                          }
                          final args = ModalRoute.of(context)?.settings.arguments
                              as Map<String, dynamic>?;
                          final requestId = args?['requestId'] as String?;
                          final resumeText = args?['resumeText'] as String?;
                          if (requestId == null || resumeText == null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Missing request. Try again.'),
                                ),
                              );
                            }
                            return;
                          }
                          setState(() {
                            _isNavigating = true;
                          });
                          final saved =
                              await FirestoreService.instance.updateJobDescription(
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
                              'requestId': requestId,
                              'jobDescription': _controller.text.trim(),
                              'resumeText': resumeText,
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

}
