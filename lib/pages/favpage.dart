import 'package:beat_bazaar/components/my_drawer.dart';
import 'package:beat_bazaar/models/playlist_provider.dart';
import 'package:beat_bazaar/responsive/player_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Favpage extends StatefulWidget {
  const Favpage({super.key});

  @override
  State<Favpage> createState() => _FavpageState();
}

class _FavpageState extends State<Favpage> {
  String? profileImageUrl;
  String username = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          profileImageUrl =
              userDoc['profileImageUrl'] ?? 'assets/images/default_avatar.png';
          username = userDoc['username'] ?? 'User';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "F A V O R I T E S",
          style: TextStyle(fontFamily: 'Audiowide'),
        ),
      ),
      drawer: MyDrawer(
        profileImageUrl: profileImageUrl ?? 'assets/images/default_avatar.png',
        username: username,
      ),
      body: const FavPageContent(),
    );
  }
}

class FavPageContent extends StatefulWidget {
  const FavPageContent({super.key});

  @override
  State<FavPageContent> createState() => _FavPageContentState();
}

class _FavPageContentState extends State<FavPageContent> {
  List<Map<String, String>> favoriteSongs = []; // Store favorites as maps
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserFavorites();
  }

  Future<void> _fetchUserFavorites() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          favoriteSongs =
              List<Map<String, String>>.from(userDoc['favorites'] ?? []);
          print('Fetched favorites: $favoriteSongs'); // Debugging line
          isLoading = false; // Update loading state
        });
      } else {
        print('User document does not exist.'); // Debugging line
        setState(() {
          isLoading = false;
        });
      }
    } else {
      print('No user logged in.'); // Debugging line
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Row(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 20.0),
                child: Text(
                  "Your Likes",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('songs').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final songs = snapshot.data!.docs;

              // Filter songs based on user's favorites
              final favoriteSongsList = songs.where((song) {
                return favoriteSongs.any((favSong) =>
                    favSong['songName']?.toLowerCase() ==
                        song['songName']?.toLowerCase() &&
                    favSong['artistName']?.toLowerCase() ==
                        song['artistName']?.toLowerCase());
              }).toList();

              print(
                  'Filtered favorite songs: $favoriteSongsList'); // Debugging line

              if (favoriteSongsList.isEmpty) {
                return const Center(child: Text('No favorite songs found.'));
              }

              return ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: favoriteSongsList.length,
                itemBuilder: (context, index) {
                  var song = favoriteSongsList[index];

                  return Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                      ),
                      child: SizedBox(
                        height: 80,
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: ListTile(
                            textColor: Theme.of(context).colorScheme.primary,
                            title: Text(song['songName']),
                            subtitle: Text(song['artistName']),
                            leading: Image.network(
                              song['albumArtImagePath'],
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.image_not_supported,
                                    size: 50);
                              },
                            ),
                            onTap: () {
                              final playlistProvider =
                                  Provider.of<PlaylistProvider>(context,
                                      listen: false);
                              final playlist = playlistProvider.playlist;

                              print(
                                  'Navigating to SongPage with index: $index');
                              print('Playlist length: ${playlist.length}');

                              if (playlist.isNotEmpty) {
                                playlistProvider.setCurrentSong(index);

                                // Navigate to player page
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SongPage(index: index),
                                  ),
                                );
                              } else {
                                print('Playlist is empty, cannot navigate.');
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
