import 'package:beat_bazaar/components/my_drawer.dart';
import 'package:beat_bazaar/themes/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore database access
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage access
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase Auth
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _profileImageUrl;
  String username = '';
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _fetchProfileImage();
      _fetchUsername();
    }
  }

  // Fetch the user's profile image from Firebase Storage
  Future<void> _fetchProfileImage() async {
    try {
      String downloadUrl = await FirebaseStorage.instance
          .ref('profileImages/${user!.uid}.jpg')
          .getDownloadURL();

      setState(() {
        _profileImageUrl = downloadUrl;
      });
    } catch (e) {
      print('Error fetching profile image: $e');
    }
  }

  // Fetch the username from Firestore
  Future<void> _fetchUsername() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    setState(() {
      username = userDoc.get('username') ?? 'User';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "S E T T I N G S",
          style: TextStyle(fontFamily: "Audiowide"),
        ),
      ),
      drawer: MyDrawer(
        profileImageUrl: _profileImageUrl ?? 'assets/images/default_avatar.png',
        username: username,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //darkmode
            const Text(
              "Dark Mode",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            //switch
            CupertinoSwitch(
                value: Provider.of<ThemeProvider>(context, listen: true)
                    .isDarkMode,
                onChanged: (value) =>
                    Provider.of<ThemeProvider>(context, listen: false)
                        .toggletheme())
          ],
        ),
      ),
    );
  }
}
