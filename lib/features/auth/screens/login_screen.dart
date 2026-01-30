import 'package:flutter/material.dart';
import '../../../../core/utils/validators.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../../core/constants/app_strings.dart';
import 'package:sign_in_button/sign_in_button.dart';
import '../../../../core/constants/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      _processAuthResult(success, authProvider);
    }
  }

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();
    _processAuthResult(success, authProvider);
  }

  void _processAuthResult(bool success, AuthProvider authProvider) async {
    if (mounted) {
      if (!success) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? AppStrings.generalError),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Login Success, Check Profile
        final user = authProvider.user;
        if (user != null) {
          final profileProvider = context.read<ProfileProvider>();
          await profileProvider.loadProfile(user.uid);

          if (mounted) {
            setState(() => _isLoading = false);
            if (profileProvider.profile == null) {
              context.go('/profile-setup');
            } else {
              context.go('/');
            }
          }
        } else {
          setState(() => _isLoading = false); // Should not happen
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.directions_bike,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.appName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.loginTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 48),
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
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(AppStrings.loginButton),
                ),
                const SizedBox(height: 16),
                SignInButton(
                  Buttons.google,
                  text: "Sign in with Google",
                  onPressed: _isLoading ? () {} : _handleGoogleLogin,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Navigate to Sign Up
                    context.push('/signup');
                  },
                  child: const Text('Don\'t have an account? Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
