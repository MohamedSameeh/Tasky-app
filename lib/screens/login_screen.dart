import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../data/demo/demo_auth_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'register_screen.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController(
    text: kDemoMode ? DemoAuthRepository.demoEmail : '',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: kDemoMode ? DemoAuthRepository.demoPassword : '',
  );
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    final result = await AppScope.auth.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result != null) {
      showAppSnack(context, result, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.xl,
              vertical: AppSpace.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: AppLogoMark(size: 60),
                    ),
                    const SizedBox(height: AppSpace.xl),
                    Text('Welcome back', style: context.text.headlineLarge),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      'Sign in to see what needs doing today.',
                      style: context.text.bodyLarge?.copyWith(
                        color: context.palette.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xxl),
                    CustomTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      hintText: 'you@business.com',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Enter your email'
                                  : null,
                    ),
                    const SizedBox(height: AppSpace.lg + 4),
                    CustomTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      hintText: 'Your password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _login(),
                      validator:
                          (v) =>
                              (v == null || v.isEmpty)
                                  ? 'Enter your password'
                                  : null,
                    ),
                    const SizedBox(height: AppSpace.xxl),
                    CustomButton(
                      text: 'Sign in',
                      loading: _isLoading,
                      onPressed: _login,
                    ),
                    const SizedBox(height: AppSpace.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: context.text.bodyMedium?.copyWith(
                            color: context.palette.muted,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text('Create one'),
                        ),
                      ],
                    ),
                    if (kDemoMode) ...[
                      const SizedBox(height: AppSpace.lg),
                      const DemoNotice(
                        'Demo mode. The sign-in details are filled in for you '
                        'and the data is sample data kept on this device.',
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small honest banner shown only in demo builds.
class DemoNotice extends StatelessWidget {
  final String text;
  const DemoNotice(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: context.colors.primary),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              text,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
