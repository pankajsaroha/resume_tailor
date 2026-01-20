import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/resume_preview.dart';
import '../routes.dart';
import '../services/firestore_service.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final preview = args?['preview'] as ResumePreview?;
    final requestId = args?['requestId'] as String?;
    if (preview == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Preview'),
          automaticallyImplyLeading: false,
        ),
        body: const SizedBox.shrink(),
      );
    }

    debugPrint(
      'Preview keywordMatch=${preview.keywordMatch} sections=${preview.sections.length}',
    );

    final sections = preview.sections;
    final ResumeSection? firstSection =
        sections.isNotEmpty ? sections.first : null;
    final List<ResumeSection> blurredSections =
        sections.length > 1 ? sections.sublist(1) : const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Keyword Match: ${preview.keywordMatch}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF001F3F),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'High Match',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Stack(
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: StreamBuilder<bool>(
                        stream: requestId == null
                            ? null
                            : FirestoreService.instance.paidStream(requestId),
                        builder: (context, snapshot) {
                          final paid = snapshot.data == true;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preview.name,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF001F3F),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                preview.role,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 24),
                              if (firstSection != null) ...[
                                _sectionTitle(firstSection.title),
                                const SizedBox(height: 12),
                                _sectionContent(firstSection.content),
                              ],
                              const SizedBox(height: 32),
                              if (paid)
                                for (final section in blurredSections) ...[
                                  _sectionTitle(section.title),
                                  const SizedBox(height: 12),
                                  _sectionContent(section.content),
                                  const SizedBox(height: 32),
                                ]
                              else
                                ClipRect(
                                  child: ImageFiltered(
                                    imageFilter:
                                        ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        for (final section in blurredSections) ...[
                                          _sectionTitle(section.title),
                                          const SizedBox(height: 12),
                                          _sectionContent(section.content),
                                          const SizedBox(height: 32),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
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
                        await Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.payment,
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
                    : const Text(
                        'Download ₹9',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF001F3F),
      ),
    );
  }

  Widget _sectionContent(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        height: 1.5,
        color: Colors.black87,
      ),
    );
  }
}
