import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signUp(String email, String password) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Implements strict Google Sign In Flow
  // 1. Get Google Token
  // 2. Send to Firebase (Backend)
  // 3. Backend verifies domain (Blocking Function)
  // 4. Return result or throw error
  Future<UserCredential> signInWithGoogle() async {
    try {
      // 1. Trigger Google Sign In Flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'aborted',
          message: 'Sign in aborted by user',
        );
      }

      // 2. Get Auth Details (ID Token)
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Create Credential (Payload)
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Authenticate with Firebase (Pass to Backend)
      // If Blocking Function fails (bad domain), this will throw an exception
      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      // Ensure specific errors bubble up
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  Future<void> sendEmailVerification() async {
    await _firebaseAuth.currentUser?.sendEmailVerification();
  }

  bool isEmailVerified() {
    return _firebaseAuth.currentUser?.emailVerified ?? false;
  }
}
