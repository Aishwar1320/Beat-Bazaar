import 'package:beat_bazaar/responsive/desktop_body.dart';
import 'package:beat_bazaar/responsive/mobile_body.dart';
import 'package:beat_bazaar/responsive/responsive_layout.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

void signUserOut() {
  FirebaseAuth.instance.signOut();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: ResponsiveLayout(
            mobileBody: MyMobileBody(), desktopBody: MyDesktopBody()));
  }
}
