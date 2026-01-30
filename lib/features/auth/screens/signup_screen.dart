import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final success = await context.read<AuthProvider>().signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<AuthProvider>().error ?? AppStrings.generalError,
              ),
            ),
          );
        } else {
          // Show Verification Sent Dialog or Snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Verification email sent! Please check your inbox.',
              ),
            ),
          );
          // Navigation to login or home (Router handles it if user is created, but if email not verified, router might block home access)
          // Router will redirect to Login or Home based on state.
          // If Router detects !emailVerified, it might redirect.
        }
      }
    }
  }

  void _handleGoogleSignup() async {
    setState(() => _isLoading = true);
    // ignore: use_build_context_synchronously
    final success = await context.read<AuthProvider>().signInWithGoogle();

    if (mounted) {
      _processAuthResult(success);
    }
  }

  void _processAuthResult(bool success) async {
    if (success) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<AuthProvider>().error ?? AppStrings.generalError,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.signupTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Join the Campus Community',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.verifyEmail, // "Verify your college email..."
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: AppStrings.emailHint,
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: AppStrings.passwordHint,
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) return 'Min 6 chars';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(AppStrings.signupButton),
              ),
              const SizedBox(height: 16),
              SignInButton(
                Buttons.google,
                text: "Sign up with Google",
                onPressed: _isLoading ? () {} : _handleGoogleSignup,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  context.pop();
                },
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
