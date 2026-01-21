import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/resume_preview.dart';

class PdfService {
  PdfService._();

  static Future<String> generateAndSave({
    required ResumePreview preview,
    required String requestId,
  }) async {
    final doc = pw.Document();
    final originalText = await _loadOriginalResumeText(requestId);
    final mergedText = _mergeResumeText(originalText, preview);
    doc.addPage(
      pw.MultiPage(
        build: (context) {
          return [
            pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: mergedText.trim().isEmpty
                  ? _buildFromPreview(preview)
                  : pw.Text(
                      mergedText,
                      style: const pw.TextStyle(fontSize: 11),
                    ),
            ),
          ];
        },
      ),
    );

    final bytes = await doc.save();
    if (Platform.isAndroid) {
      final fileName = 'resume_$requestId';
      final result = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (result == null || result.isEmpty) {
        return 'Download cancelled';
      }
      return 'Saved $fileName.pdf';
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/resume_$requestId.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Your tailored resume PDF',
    );
    return 'Share sheet opened';
  }

  static pw.Widget _buildFromPreview(ResumePreview preview) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          preview.name,
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          preview.role,
          style: pw.TextStyle(
            fontSize: 16,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Divider(),
        pw.SizedBox(height: 16),
        for (final section in preview.sections) ...[
          pw.Text(
            section.title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            section.content,
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 16),
        ],
      ],
    );
  }

  static Future<String> _loadOriginalResumeText(String requestId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('resumeRequests')
          .doc(requestId)
          .get();
      return doc.data()?['resumeText'] as String? ?? '';
    } catch (error) {
      return '';
    }
  }

  static String _mergeResumeText(String original, ResumePreview preview) {
    if (original.trim().isEmpty || preview.sections.isEmpty) {
      return original;
    }
    final sectionsByTitle = <String, ResumeSection>{};
    for (final section in preview.sections) {
      final key = section.title.trim().toLowerCase();
      if (key.isNotEmpty && !sectionsByTitle.containsKey(key)) {
        sectionsByTitle[key] = section;
      }
    }
    if (sectionsByTitle.isEmpty) {
      return original;
    }
    final lines = original.split('\n');
    final titleIndices = <int>[];
    for (var i = 0; i < lines.length; i++) {
      final key = lines[i].trim().toLowerCase();
      if (sectionsByTitle.containsKey(key)) {
        titleIndices.add(i);
      }
    }
    if (titleIndices.isEmpty) {
      return original;
    }
    final output = <String>[];
    var i = 0;
    while (i < lines.length) {
      final key = lines[i].trim().toLowerCase();
      if (sectionsByTitle.containsKey(key)) {
        output.add(lines[i]);
        final section = sectionsByTitle[key];
        if (section != null && section.content.trim().isNotEmpty) {
          output.addAll(section.content.split('\n'));
        }
        final nextIndex = titleIndices
            .firstWhere((idx) => idx > i, orElse: () => lines.length);
        if (nextIndex >= lines.length) {
          break;
        }
        i = nextIndex;
        continue;
      }
      output.add(lines[i]);
      i++;
    }
    return output.join('\n');
  }
}
