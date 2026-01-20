import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ResumeTextExtractor {
  ResumeTextExtractor._();

  static Future<String> extractText({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return _extractPdfText(bytes);
    }
    if (lower.endsWith('.docx')) {
      return _extractDocxText(bytes);
    }
    return '';
  }

  static Future<String> _extractPdfText(Uint8List bytes) async {
    final document = PdfDocument(inputBytes: bytes);
    final text = PdfTextExtractor(document).extractText();
    document.dispose();
    return text.trim();
  }

  static Future<String> _extractDocxText(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final file = archive.files.firstWhere(
      (f) => f.name == 'word/document.xml',
      orElse: () => ArchiveFile('', 0, []),
    );
    if (file.name.isEmpty) {
      return '';
    }
    final xml = utf8.decode(file.content as List<int>);
    final buffer = StringBuffer();
    final matches = RegExp(r'<w:t[^>]*>(.*?)</w:t>').allMatches(xml);
    for (final match in matches) {
      buffer.writeln(match.group(1));
    }
    return buffer.toString().trim();
  }
}
