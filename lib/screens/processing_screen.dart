import 'dart:async';
import 'package:flutter/material.dart';
import '../models/resume_preview.dart';
import '../routes.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  static const _genericErrorMessage =
      'We could not generate your tailored resume. Please try again.';

  final List<String> _messages = [
    'Analyzing resume',
    'Matching keywords',
    'Optimizing for ATS',
  ];
  int _currentIndex = 0;
  Timer? _messageTimer;
  ResumePreview? _preview;
  late String _requestId;
  late String _jobDescription;
  late String _resumeText;
  bool _initialized = false;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _requestId = (args?['requestId'] as String?) ?? '';
    _jobDescription = (args?['jobDescription'] as String?) ?? '';
    _resumeText = (args?['resumeText'] as String?) ?? '';
    _triggerBackendTasks();
    _startTimers();
    _initialized = true;
  }

  void _retry() {
    if (_isProcessing) {
      return;
    }
    setState(() {
      _errorMessage = null;
    });
    _triggerBackendTasks();
  }

  void _triggerBackendTasks() async {
    if (_requestId.isEmpty || _resumeText.isEmpty || _jobDescription.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = _genericErrorMessage;
        });
      }
      return;
    }
    if (_isProcessing) {
      return;
    }
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    debugPrint('AI request start');
    try {
      await AuthService.instance.ensureAuthenticated();
      final tailored =
          await FirestoreService.instance.callTailorResumeFunction(
        resumeText: _resumeText,
        jobDescription: _jobDescription,
        requestId: _requestId,
      ).timeout(const Duration(seconds: 30));
      debugPrint('AI response received');
      if (!mounted || tailored == null) {
        if (mounted) {
          setState(() {
            _errorMessage = _genericErrorMessage;
          });
        }
        return;
      }
      final nextPreview = ResumePreview.fromMap(tailored);
      setState(() {
        _preview = nextPreview;
      });
      FirestoreService.instance.saveResumePreview(
        preview: nextPreview,
        requestId: _requestId,
      );
      if (!mounted) {
        return;
      }
      debugPrint('Navigation to Preview triggered');
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.preview,
        arguments: {
          'preview': nextPreview,
          'requestId': _requestId,
        },
      );
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _errorMessage = 'The request timed out. Please try again.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = _formatError(error).isNotEmpty
              ? _formatError(error)
              : _genericErrorMessage;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _startTimers() {
    _messageTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _messages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: _errorMessage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF001F3F),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _messages[_currentIndex],
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _retry,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF001F3F),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.jobDescription,
                            arguments: {
                              'requestId': _requestId,
                              'resumeText': _resumeText,
                            },
                          );
                        },
                        child: const Text(
                          'Go Back',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF001F3F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  String _formatError(Object error) {
    final message = error.toString();
    return message.replaceFirst('Exception: ', '');
  }
}
