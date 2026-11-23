import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_repository.dart';

/// Firebase Auth (email/password) implementation of [AuthRepository].
class AuthService implements AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthService(this._firebaseAuth);

  static AppUser? _map(User? u) =>
      u == null
          ? null
          : AppUser(
            uid: u.uid,
            email: u.email ?? '',
            displayName: u.displayName,
          );

  @override
  Stream<AppUser?> get authStateChanges =>
      _firebaseAuth.authStateChanges().map(_map);

  @override
  AppUser? get currentUser => _map(_firebaseAuth.currentUser);

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Could not sign in. Please try again.';
    }
  }

  @override
  Future<String?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Could not create the account. Please try again.';
    }
  }
}
