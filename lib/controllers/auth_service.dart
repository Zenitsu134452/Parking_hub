
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'db_service.dart';

import 'db_service.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Future<UserCredential?> loginWithGoogle(Function(String) loadUserData) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // User canceled the sign-in

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        loadUserData(user.uid); // Reload user data in the provider

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("shop_users")
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          await FirebaseFirestore.instance.collection("shop_users").doc(user.uid).set({
            "name": "User",
            "email": user.email,
            "address": "",
            "phone": "",
          });
        }
      }

      return userCredential;
    } catch (e) {
      print("Error during Google Login: $e");
      return null;
    }
  }

//logout
  Future<void> logout(Function resetUserData) async {
    if (await GoogleSignIn().isSignedIn()) {
      await GoogleSignIn().signOut();
    }
    await _auth.signOut();
    resetUserData(); // Reset provider on logout
  }

  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
  // Create a new account using email and password
  Future<String> createAccountWithEmail(String name,String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await  DbService().saveUserData(name: name, email: email);
      return "Account Created";
    } on FirebaseAuthException catch (e) {
      return e.message.toString();
    }
  }
  Future<bool> isLoggedIn() async{
    var user=FirebaseAuth.instance.currentUser;
    return user!=null;
  }
  // Check if the user's email is verified
  Future<bool> isEmailVerified() async {
    User? user = _auth.currentUser;
    await user?.reload(); // Refresh the user to get the latest emailVerified status
    return user?.emailVerified ?? false;
  }
  // Login with email and password
  Future<String> loginWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = _auth.currentUser;

      // Check for email verification
      if (user != null && !user.emailVerified) {
        return "Verification Required";
      }
      return "Login Successful";
    } on FirebaseAuthException catch (e) {
      return e.message.toString();
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e.code));
    }
  }


  // Reset the password
  Future<String> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return "Mail Sent";
    } on FirebaseAuthException catch (e) {
      return e.message.toString();
    }
  }
}

// Helper function for handling errors
String _handleAuthError(String code) {
  switch (code) {
    case 'user-not-found':
      return "No user found with this email.";
    case 'wrong-password':
      return "Incorrect password.";
    case 'invalid-email':
      return "Email address is invalid.";
    case 'user-disabled':
      return "This user account has been disabled.";
    case 'too-many-requests':
      return "Too many requests. Please try again later.";
    default:
      return "An unknown error occurred.";
  }
}
