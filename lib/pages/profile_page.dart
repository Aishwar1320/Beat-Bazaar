import 'package:beat_bazaar/components/my_drawer.dart';
import 'package:beat_bazaar/models/playlist_provider.dart';
import 'package:beat_bazaar/pages/add_music.dart';
import 'package:beat_bazaar/responsive/player_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore database access
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // For image picking
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage
import 'dart:io';

import 'package:provider/provider.dart'; // For File

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _descriptionController = TextEditingController();
  String _description = "";
  String username = '';
  final user = FirebaseAuth.instance.currentUser;

  // Track edit mode
  bool _isEditingMode = false;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _fetchDescription();
      _fetchUsername();
    }
  }

  // Fetch the user's description from Firestore
  Future<void> _fetchDescription() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    setState(() {
      _description = userDoc.get('description') ?? '';
      _descriptionController.text = _description;
    });
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

  // Save the description to Firestore
  Future<void> _saveDescription() async {
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set(
        {'description': _descriptionController.text}, SetOptions(merge: true));

    setState(() {
      _description = _descriptionController.text;
      _isEditingMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Description saved')),
    );
  }

  // Handle profile image change
  Future<void> _changeProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profileImages/${user!.uid}.jpg');
        await storageRef.putFile(File(pickedFile.path));

        String newDownloadUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({'profileImageUrl': newDownloadUrl});

        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully')),
        );
      } catch (e) {
        print('Error uploading profile image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating profile image')),
        );
      }
    }
  }

  // Fetch uploaded songs
  Stream<QuerySnapshot> _fetchUploadedSongs() {
    return FirebaseFirestore.instance
        .collection('songs')
        .where('userId', isEqualTo: user!.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Profile"),
        ),
        body: const Center(child: Text("No user is logged in.")),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "Y O U R  P R O F I L E",
          style: TextStyle(fontFamily: 'Audiowide'),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditingMode ? Icons.check : Icons.edit,
              color: _isEditingMode ? Colors.green : Colors.black,
            ),
            onPressed: () {
              setState(() {
                if (_isEditingMode) {
                  _saveDescription();
                } else {
                  _isEditingMode = true;
                }
              });
            },
          ),
        ],
      ),
      drawer: MyDrawer(
        profileImageUrl: '', // Placeholder for the profile image URL.
        username: username,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(child: Text("Error fetching user data"));
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>?;

                return userData != null &&
                        userData.containsKey('profileImageUrl')
                    ? GestureDetector(
                        onTap: () {
                          if (_isEditingMode) {
                            _changeProfileImage();
                          }
                        },
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage:
                              NetworkImage(userData['profileImageUrl']),
                        ),
                      )
                    : GestureDetector(
                        onTap: () {
                          if (_isEditingMode) {
                            _changeProfileImage();
                          }
                        },
                        child: const CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey,
                          child:
                              Icon(Icons.person, size: 60, color: Colors.white),
                        ),
                      );
              },
            ),
            const SizedBox(height: 20),

            // Description field
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              enabled: _isEditingMode,
              decoration: const InputDecoration(
                labelText: "Profile Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // Uploaded Songs Section
            const Text(
              "Your Uploaded Songs",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Uploaded songs list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _fetchUploadedSongs(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final songs = snapshot.data!.docs;

                  if (songs.isEmpty) {
                    return const Center(child: Text("No songs uploaded yet."));
                  }

                  return ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      var song = songs[index];

                      return ListTile(
                        leading: const Icon(Icons.music_note),
                        title: Text(song['songName']),
                        subtitle: Text(song['artistName']),
                        onTap: () {
                          // Access the playlist provider
                          final playlistProvider =
                              Provider.of<PlaylistProvider>(context,
                                  listen: false);

                          // Set the current song in the playlist provider
                          playlistProvider.setCurrentSong(index);
                          playlistProvider.play(); // Start playing the song

                          // Navigate to the player page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SongPage(index: index),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMusicPage(),
            ),
          );
        },
        child: const Icon(Icons.playlist_add),
      ),
    );
  }
}
