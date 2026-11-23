import 'package:flutter/material.dart';
import 'package:tasky_app/screens/tasky_app_homescreen.dart';
import '../app_scope.dart';
import '../data/auth_repository.dart';
import 'login_screen.dart';

/// Shows the app when someone is signed in, the sign-in screen otherwise.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AppUser?> _stream = AppScope.auth.authStateChanges;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _stream,
      builder: (context, snapshot) {
        final Widget child;
        if (snapshot.connectionState == ConnectionState.waiting) {
          child = const Scaffold(
            key: ValueKey('waiting'),
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.data != null) {
          AppScope.tasks.bind(snapshot.data!.uid);
          child = HomeScreen(key: const ValueKey('home'), user: snapshot.data!);
        } else {
          AppScope.tasks.unbind();
          child = const LoginScreen(key: ValueKey('login'));
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: child,
        );
      },
    );
  }
}
