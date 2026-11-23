import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      showAppSnack(context, 'Passwords do not match', error: true);
      return;
    }

    setState(() => _isLoading = true);
    final result = await AppScope.auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == null) {
      Navigator.pop(context);
    } else {
      showAppSnack(context, result, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xl,
            AppSpace.sm,
            AppSpace.xl,
            AppSpace.xl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Create your account', style: context.text.headlineLarge),
                const SizedBox(height: AppSpace.sm),
                Text(
                  'Your tasks sync to your account and follow you across devices.',
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
                  validator:
                      (v) =>
                          (v == null || !v.contains('@'))
                              ? 'Enter a valid email'
                              : null,
                ),
                const SizedBox(height: AppSpace.lg + 4),
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  hintText: 'At least 6 characters',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator:
                      (v) =>
                          (v == null || v.length < 6)
                              ? 'Use at least 6 characters'
                              : null,
                ),
                const SizedBox(height: AppSpace.lg + 4),
                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm password',
                  hintText: 'Repeat your password',
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: AppSpace.xxl),
                CustomButton(
                  text: 'Create account',
                  loading: _isLoading,
                  onPressed: _register,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
