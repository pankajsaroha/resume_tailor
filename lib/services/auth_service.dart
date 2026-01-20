import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  Future<User?> ensureAuthenticated() async {
    final auth = FirebaseAuth.instance;
    if (kIsWeb) {
      await auth.setPersistence(Persistence.LOCAL);
    }
    if (auth.currentUser != null) {
      await auth.currentUser?.getIdToken(true);
      await auth.idTokenChanges().firstWhere((user) => user != null);
      return auth.currentUser;
    }
    try {
      final credential = await auth.signInAnonymously();
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'auth-unavailable',
          message: 'Anonymous auth failed',
        );
      }
      await user.getIdToken(true);
      await auth.idTokenChanges().firstWhere((u) => u != null);
      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }
}
