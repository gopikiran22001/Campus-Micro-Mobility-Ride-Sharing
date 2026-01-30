import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isChecking = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Auto-check every 3 seconds for convenience
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkVerification(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    // Reload user to get fresh emailVerified status
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) return;

    await authProvider.user!.reload();
    // The provider listens to auth state changes, but reload might not trigger stream immediately
    // or if the object reference doesn't change.
    // However, we can check the current object after reload.

    if (authProvider.user?.emailVerified == true) {
      _timer?.cancel();
      if (mounted) {
        context.go('/'); // Router will redirect to ProfileSetup if needed
      }
    }
  }

  Future<void> _handleResend() async {
    setState(() => _isChecking = true);
    await context.read<AuthProvider>().sendVerificationEmail();
    setState(() => _isChecking = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email resent!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.read<AuthProvider>().user?.email ?? 'your email';

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'Check your Inbox',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'We have sent a verification link to:\n$email',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'You must verify your college email to access the app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isChecking ? null : _checkVerification,
              child: const Text('I have Verified'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isChecking ? null : _handleResend,
              child: const Text('Resend Email'),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.read<AuthProvider>().signOut(),
              child: const Text(
                'Sign Out / Change Email',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
