import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to listen for auth changes
  Stream<User?> get user => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log(
        'Sign-in failed',
        name: 'com.example.myapp.auth',
        error: 'Code: ${e.code}\nMessage: ${e.message}',
      );
      return null;
    }
  }

  // Register with email and password and create a user document
  Future<UserCredential?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create a new document for the user with the uid
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'displayName': '',
        'createdAt': Timestamp.now(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log(
        'Registration failed',
        name: 'com.example.myapp.auth',
        error: 'Code: ${e.code}\nMessage: ${e.message}',
      );
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
