import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/resume_preview.dart';

class PdfService {
  PdfService._();

  static const MethodChannel _safChannel =
      MethodChannel('resume_tailor/saf');

  static Future<String> generateAndSave({
    required ResumePreview preview,
    required String requestId,
  }) async {
    try {
      print('PDF build started');
      final doc = pw.Document();
      final notoFont = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
      );
      final baseTextStyle = pw.TextStyle(
        font: notoFont,
        fontFallback: [notoFont],
        fontSize: 14,
      );
      final originalText = await _loadOriginalResumeText(requestId);
      final mergedText = _mergeResumeText(originalText, preview);
      doc.addPage(
        pw.MultiPage(
          build: (context) {
            return [
              pw.Padding(
                padding: const pw.EdgeInsets.all(24),
                child: mergedText.trim().isEmpty
                    ? _buildFromPreview(preview, notoFont)
                    : pw.Text(
                        mergedText,
                        style: baseTextStyle,
                      ),
              ),
            ];
          },
        ),
      );
      print('PDF page added');

      final bytes = await doc.save();
      final fileName = 'resume_$requestId.pdf';
      if (kIsWeb) {
        await Printing.layoutPdf(
          onLayout: (format) async => bytes,
          name: fileName,
        );
        print('PDF saved to path: web');
        return 'Download started';
      }

      if (Platform.isAndroid) {
        final result = await _safChannel.invokeMethod<String>(
          'savePdf',
          {
            'name': fileName,
            'bytes': bytes,
          },
        );
        if (result == null || result.isEmpty) {
          return 'Download cancelled';
        }
        print('PDF saved to path: $result');
        return 'Saved $fileName';
      }

      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
      print('PDF saved to path: share');
      return 'Share sheet opened';
    } catch (error, stackTrace) {
      print(error);
      print(stackTrace);
      rethrow;
    }
  }

  static pw.Widget _buildFromPreview(ResumePreview preview, pw.Font font) {
    pw.TextStyle styled(pw.TextStyle style) {
      return style.copyWith(
        font: font,
        fontFallback: [font],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          preview.name,
          style: styled(
            pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
          ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          preview.role,
          style: styled(
            pw.TextStyle(
            fontSize: 16,
            color: PdfColors.grey700,
          ),
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Divider(),
        pw.SizedBox(height: 16),
        for (final section in preview.sections) ...[
          pw.Text(
            section.title,
            style: styled(
              pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            section.content,
            style: styled(
              const pw.TextStyle(fontSize: 12),
            ),
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
