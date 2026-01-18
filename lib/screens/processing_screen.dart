import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/resume_preview.dart';
import '../routes.dart';
import '../services/firestore_service.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  final List<String> _messages = [
    'Analyzing resume',
    'Matching keywords',
    'Optimizing for ATS',
  ];
  int _currentIndex = 0;
  Timer? _messageTimer;
  Timer? _navigationTimer;
  late ResumePreview _preview;
  late String _requestId;
  late String _jobDescription;
  bool _initialized = false;

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
    _preview = (args?['preview'] as ResumePreview?) ?? ResumePreview.mock();
    _requestId = (args?['requestId'] as String?) ?? _generateRequestId();
    _jobDescription = (args?['jobDescription'] as String?) ?? '';
    _triggerBackendTasks();
    _startTimers();
    _initialized = true;
  }

  String _generateRequestId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(1000000).toString().padLeft(6, '0');
    return 'req_$now$rand';
  }

  void _triggerBackendTasks() async {
    FirestoreService.instance.saveResumePreview(
      preview: _preview,
      requestId: _requestId,
    );
    final tailored = await FirestoreService.instance.callTailorResumeFunction(
      resumeText: _buildResumeText(_preview),
      jobDescription: _jobDescription,
      requestId: _requestId,
    );
    if (!mounted || tailored == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI failed. Using existing resume data.'),
          ),
        );
      }
      return;
    }
    setState(() {
      _preview = ResumePreview.fromMap(tailored);
    });
  }

  String _buildResumeText(ResumePreview preview) {
    final buffer = StringBuffer()
      ..writeln(preview.name)
      ..writeln(preview.role);
    for (final section in preview.sections) {
      buffer.writeln(section.title);
      buffer.writeln(section.content);
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  void _startTimers() {
    _messageTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _messages.length;
        });
      }
    });

    _navigationTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.preview,
          arguments: {
            'preview': _preview,
            'requestId': _requestId,
          },
        );
      }
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _navigationTimer?.cancel();
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
        child: Column(
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
        ),
      ),
    );
  }
}
