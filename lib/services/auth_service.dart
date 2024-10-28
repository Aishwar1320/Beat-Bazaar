import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? gUser = await _googleSignIn.signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication gAuth = await gUser!.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      // Sign in the user with the credential
      await _auth.signInWithCredential(credential);

      // Navigate to the homepage
      Navigator.pushReplacementNamed(context, '/homepage');
    } catch (e) {
      print(e);
      // You may want to show an error message to the user here
    }
  }
}
