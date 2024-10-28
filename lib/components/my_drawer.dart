import 'package:beat_bazaar/pages/auth/login_register_page.dart';
import 'package:beat_bazaar/pages/homepage.dart';
import 'package:beat_bazaar/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:beat_bazaar/pages/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyDrawer extends StatelessWidget {
  final String profileImageUrl;
  final String username;
  const MyDrawer({
    super.key,
    required this.profileImageUrl,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
            ),
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(child: Text("Error fetching user data"));
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Navigate to profile page
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    const ProfilePage(),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 40,
                            backgroundImage:
                                NetworkImage(userData['profileImageUrl']),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          userData['username'] ?? 'User',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inverseSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Home tile
                  Padding(
                    padding: const EdgeInsets.only(left: 25.0, top: 25),
                    child: ListTile(
                      title: const Text("H O M E"),
                      leading: const Icon(Icons.home),
                      onTap: () {
                        // Pop drawer
                        if (ModalRoute.of(context)?.settings.name ==
                            '/homepage') {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  const HomePage(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  // Settings tile
                  Padding(
                    padding: const EdgeInsets.only(left: 25.0, top: 0),
                    child: ListTile(
                      title: const Text("S E T T I N G S"),
                      leading: const Icon(Icons.settings),
                      onTap: () {
                        // Pop drawer
                        Navigator.pop(context);
                        // Navigate to settings page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (BuildContext context) =>
                                const SettingsPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  // Logout tile
                  Padding(
                    padding: const EdgeInsets.only(left: 25.0, top: 0),
                    child: ListTile(
                      title: const Text("L O G O U T"),
                      leading: const Icon(Icons.logout),
                      onTap: () {
                        signUserOut();
                        // Pop drawer
                        Navigator.pop(context);
                        // Navigate to login page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (BuildContext context) =>
                                const LoginRegisterPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
