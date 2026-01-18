import 'package:flutter/material.dart';
import '../routes.dart';
import '../widgets/bullet_point_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Resume Tailor',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF001F3F),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Get interview-ready in 30 seconds',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              const BulletPointRow(text: 'ATS Optimized'),
              const SizedBox(height: 16),
              const BulletPointRow(text: 'Job Specific'),
              const SizedBox(height: 16),
              const BulletPointRow(text: 'Recruiter Friendly'),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isNavigating
                      ? null
                      : () async {
                          setState(() {
                            _isNavigating = true;
                          });
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.upload,
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
                          'Tailor My Resume',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
