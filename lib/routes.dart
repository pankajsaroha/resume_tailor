import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/upload_resume_screen.dart';
import 'screens/job_description_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/preview_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/success_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String upload = '/upload';
  static const String jobDescription = '/job-description';
  static const String processing = '/processing';
  static const String preview = '/preview';
  static const String payment = '/payment';
  static const String success = '/success';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) => const HomeScreen(),
      upload: (context) => const UploadResumeScreen(),
      jobDescription: (context) => const JobDescriptionScreen(),
      processing: (context) => const ProcessingScreen(),
      preview: (context) => const PreviewScreen(),
      payment: (context) => const PaymentScreen(),
      success: (context) => const SuccessScreen(),
    };
  }
}
