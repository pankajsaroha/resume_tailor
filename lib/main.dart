import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'routes.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AuthService.instance.ensureAuthenticated();
  final user = FirebaseAuth.instance.currentUser;
  final token = await user?.getIdToken();
  // One-time token check for debugging auth propagation
  // ignore: avoid_print
  print('Auth token available: ${token != null}');
  runApp(const ResumeTailorApp());
}

class ResumeTailorApp extends StatelessWidget {
  const ResumeTailorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resume Tailor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF001F3F), // Deep navy
          brightness: Brightness.light,
        ),
      ),
      initialRoute: AppRoutes.home,
      routes: AppRoutes.getRoutes(),
    );
  }
}
