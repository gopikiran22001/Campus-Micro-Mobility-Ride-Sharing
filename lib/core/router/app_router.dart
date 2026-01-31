import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/verify_email_screen.dart';
import '../../features/ride/screens/ride_home_screen.dart';
import '../../features/ride/screens/debug_matching_screen.dart';
import '../../features/ride/screens/rider_status_debug_screen.dart';
import '../../features/profile/screens/profile_setup_screen.dart';
import '../../features/profile/screens/view_profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    refreshListenable: authProvider,
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ViewProfileScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/debug-matching',
        builder: (context, state) => const DebugMatchingScreen(),
      ),
      GoRoute(
        path: '/rider-debug',
        builder: (context, state) => const RiderStatusDebugScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const RideHomeScreen()),
    ],
    redirect: (context, state) {
      final loggedIn = authProvider.user != null;
      final loggingIn = state.uri.toString() == '/login';
      final signingUp = state.uri.toString() == '/signup';
      final verifying = state.uri.toString() == '/verify-email';

      // 1. Not Logged In
      if (!loggedIn) {
        if (loggingIn || signingUp) return null; // Stay where we are
        return '/login';
      }

      // 2. Logged In but Not Verified
      if (loggedIn && !authProvider.user!.emailVerified) {
        if (verifying) return null;
        return '/verify-email';
      }

      // 3. Logged In & Verified
      if (loggingIn || signingUp || verifying) {
        return '/';
      }

      return null;
    },
  );
}
