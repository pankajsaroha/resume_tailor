import '../models/resume_preview.dart';

class PdfService {
  PdfService._();

  static Future<String> generateAndSave({
    required ResumePreview preview,
    required String requestId,
  }) {
    throw UnsupportedError('PDF generation is not supported on this platform.');
  }
}
