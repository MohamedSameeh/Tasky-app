import 'dart:async';
import '../auth_repository.dart';

/// In-memory stand-in for Firebase Auth, used when the app is built with
/// `--dart-define=DEMO=true`. Nothing leaves the device.
class DemoAuthRepository implements AuthRepository {
  static const demoEmail = 'maya@tasky.demo';
  static const demoPassword = 'demo1234';
  static const _demoUser = AppUser(
    uid: 'demo-user',
    email: demoEmail,
    displayName: 'Maya Hart',
  );

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> get authStateChanges async* {
    yield _user;
    yield* _controller.stream;
  }

  void _set(AppUser? u) {
    _user = u;
    _controller.add(u);
  }

  String? _validate(String email, String password) {
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email address.';
    }
    if (password.length < 6) {
      return 'Password should be at least 6 characters.';
    }
    return null;
  }

  @override
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final problem = _validate(email, password);
    if (problem != null) return problem;
    _set(
      email == demoEmail ? _demoUser : AppUser(uid: 'demo-user', email: email),
    );
    return null;
  }

  @override
  Future<String?> signUp({
    required String email,
    required String password,
  }) => signIn(email: email, password: password);

  @override
  Future<void> signOut() async => _set(null);
}
