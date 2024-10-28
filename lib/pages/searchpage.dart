import 'package:beat_bazaar/components/my_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore database access
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage access
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase Auth
import 'package:flutter/material.dart';

class Searchpage extends StatefulWidget {
  const Searchpage({super.key});

  @override
  _SearchpageState createState() => _SearchpageState();
}

class _SearchpageState extends State<Searchpage> {
  String? _profileImageUrl;
  String username = '';
  final user = FirebaseAuth.instance.currentUser;
  String searchQuery = ''; // Store the current search query
  List<DocumentSnapshot> songResults = []; // Store the song search results
  List<DocumentSnapshot> artistResults = []; // Store the artist search results

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

  // Perform search on Firestore based on query
  Future<void> _performSearch(String query) async {
    if (query.isNotEmpty) {
      // Search for songs
      final songResultsQuery = await FirebaseFirestore.instance
          .collection('songs')
          .where('songName', isGreaterThanOrEqualTo: query)
          .where('songName',
              isLessThanOrEqualTo:
                  '$query\uf8ff') // Ensures the search is accurate
          .get();

      // Search for artists
      final artistResultsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username',
              isLessThanOrEqualTo:
                  '$query\uf8ff') // Ensures the search is accurate
          .get();

      setState(() {
        songResults =
            songResultsQuery.docs; // Update the state with song results
        artistResults =
            artistResultsQuery.docs; // Update the state with artist results
      });
    } else {
      // Clear results if the query is empty
      setState(() {
        songResults.clear(); // Clear song results
        artistResults.clear(); // Clear artist results
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "S E A R C H",
          style: TextStyle(fontFamily: 'Audiowide'),
        ),
      ),
      drawer: MyDrawer(
        profileImageUrl: _profileImageUrl ?? 'assets/images/default_avatar.png',
        username: username,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value; // Update search query
                });
                _performSearch(value); // Perform search whenever the user types
              },
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  onPressed: () {
                    _performSearch(
                        searchQuery); // Trigger search on button press
                  },
                  icon: const Icon(Icons.search),
                ),
                hintText: 'Search for songs or artists...',
                focusedBorder: const OutlineInputBorder(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: songResults.isEmpty && artistResults.isEmpty
                  ? const Center(child: Text('No results found.'))
                  : ListView.builder(
                      itemCount: songResults.length + artistResults.length,
                      itemBuilder: (context, index) {
                        if (index < songResults.length) {
                          var song = songResults[index];
                          return ListTile(
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
                              // Navigate to the song page or perform any action on tap
                              print('Tapped on song: ${song['songName']}');
                            },
                          );
                        } else {
                          var artist =
                              artistResults[index - songResults.length];
                          return ListTile(
                            title: Text(artist['username']),
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                  artist['profileImageUrl'] ??
                                      'assets/images/default_avatar.png'),
                              radius: 25,
                            ),
                            onTap: () {
                              // Navigate to the artist profile or perform any action on tap
                              print('Tapped on artist: ${artist['username']}');
                            },
                          );
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
