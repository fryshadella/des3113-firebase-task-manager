import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current logged in user
  User? get currentUser => _auth.currentUser;

  // Register with email and password
  Future<String?> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null; // null means success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'Password is too weak (minimum 6 characters).';
      } else if (e.code == 'email-already-in-use') {
        return 'This email is already registered.';
      } else {
        return 'Registration failed: ${e.message}';
      }
    }
  }

  // Login with email and password
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null; // null means success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No account found with this email.';
      } else if (e.code == 'wrong-password') {
        return 'Incorrect password.';
      } else {
        return 'Login failed: ${e.message}';
      }
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}