import 'dart:html' as html;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/resume_preview.dart';

class PdfService {
  PdfService._();

  static Future<String> generateAndSave({
    required ResumePreview preview,
    required String requestId,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
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
            ),
          );
        },
      ),
    );

    final bytes = await doc.save();
    final safeName = _sanitize(preview.name);
    final safeRole = _sanitize(preview.role);
    final date = DateTime.now();
    final dateStamp =
        '${date.year}${_pad2(date.month)}${_pad2(date.day)}';
    final fileName =
        'ResumeTailor_${safeName}_${safeRole}_${requestId}_$dateStamp.pdf';
    final blob = html.Blob(<Uint8List>[bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..click();
    html.Url.revokeObjectUrl(url);

    return 'Download started';
  }

  static String _sanitize(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'\s+'), '_');
    return cleaned.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
  }

  static String _pad2(int value) {
    return value.toString().padLeft(2, '0');
  }
}
