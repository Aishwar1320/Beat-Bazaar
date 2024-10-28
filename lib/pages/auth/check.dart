import 'package:beat_bazaar/pages/auth/login_register_page.dart';
import 'package:beat_bazaar/pages/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CheckAuth extends StatelessWidget {
  const CheckAuth({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          //yes
          if (snapshot.hasData) {
            return const HomePage();
          }
          //no
          else {
            return const LoginRegisterPage();
          }
        },
      ),
    );
  }
}
