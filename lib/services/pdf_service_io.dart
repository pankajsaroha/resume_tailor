import 'dart:io';

import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:path_provider/path_provider.dart';
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
                    color: pw.PdfColors.grey700,
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
    if (Platform.isAndroid) {
      final downloadsDir = await DownloadsPathProvider.downloadsDirectory;
      final dir = downloadsDir ?? await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/resume_$requestId.pdf');
      await file.writeAsBytes(bytes);
      return 'Saved to ${file.path}';
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
}
