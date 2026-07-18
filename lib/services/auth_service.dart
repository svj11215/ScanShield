import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Helper to map Firebase Auth exceptions to user-friendly messages
  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'email-already-in-use':
          return 'An account already exists for this email.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'user-not-found':
          return 'No user found with this email.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many login attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return e.message ?? 'An unknown authentication error occurred.';
      }
    }
    if (e is PlatformException) {
      switch (e.code) {
        case 'network_error':
          return 'Network error. Please check your internet connection.';
        case 'sign_in_failed':
          return 'Google Sign-In failed. Please try again.';
        case 'sign_in_canceled':
          return 'Sign-In was canceled by the user.';
        default:
          return e.message ?? 'A system error occurred during sign-in.';
      }
    }
    return e.toString();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Sign up
  Future<User> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;
      if (user == null) {
        throw 'Failed to retrieve user details after registration.';
      }

      // Save user details to Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'name': name,
        'created_at': FieldValue.serverTimestamp(),
        'last_login': FieldValue.serverTimestamp(),
        'total_scans': 0,
      });

      return user;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;
      if (user == null) {
        throw 'Failed to retrieve user details after login.';
      }

      // Update last_login timestamp
      await _firestore.collection('users').doc(user.uid).update({
        'last_login': FieldValue.serverTimestamp(),
      });

      return user;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential credentialResult = await _auth.signInWithCredential(credential);
      final User? user = credentialResult.user;

      if (user == null) {
        throw 'Failed to retrieve user details after Google Sign-In.';
      }

      // Check if user document exists in Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        // Create user details in Firestore (compatibility with email/password schema)
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email ?? '',
          'name': user.displayName ?? 'Google User',
          'created_at': FieldValue.serverTimestamp(),
          'last_login': FieldValue.serverTimestamp(),
          'total_scans': 0,
        });
      } else {
        // Update last_login timestamp
        await _firestore.collection('users').doc(user.uid).update({
          'last_login': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (_) {
      // Ignore errors during Google Sign-out
    }
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }
}
