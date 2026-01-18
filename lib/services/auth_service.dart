import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  Future<void> signInAnonymously() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      try {
        await auth.signInAnonymously();
      } on FirebaseAuthException {
      } catch (_) {
      }
    }
  }
}
