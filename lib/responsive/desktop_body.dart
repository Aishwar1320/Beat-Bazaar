import 'package:beat_bazaar/components/my_drawer.dart';
import 'package:beat_bazaar/models/playlist_provider.dart';
import 'package:beat_bazaar/pages/add_music.dart';
import 'package:beat_bazaar/pages/artist_profile_page.dart';
import 'package:beat_bazaar/pages/favpage.dart';
import 'package:beat_bazaar/pages/magic/beats.dart';
import 'package:beat_bazaar/responsive/player_page.dart';
import 'package:beat_bazaar/pages/searchpage.dart';
import 'package:beat_bazaar/pages/settings_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';

class MyDesktopBody extends StatefulWidget {
  const MyDesktopBody({super.key});

  @override
  State<MyDesktopBody> createState() => _MyDesktopBodyState();
}

class _MyDesktopBodyState extends State<MyDesktopBody> {
  int _selectedIndex = 0;
  String? profileImageUrl;
  String username = '';

  final List<Widget> _pages = [
    const HomePageContent(),
    const Favpage(),
    const BeatsPage(),
    const Searchpage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    // Fetch user data from Firestore
    var userId = 'your_user_id'; // Replace with actual user ID
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      setState(() {
        profileImageUrl =
            userDoc['profileImageUrl'] ?? 'assets/images/default_avatar.png';
        username = userDoc['username'] ?? 'User';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _selectedIndex == 0
          ? AppBar(
              title: const Text(
                "B E A T  B A Z A A R",
                style: TextStyle(fontFamily: 'Audiowide'),
              ),
            )
          : null,
      drawer: MyDrawer(
        profileImageUrl: profileImageUrl ?? 'assets/images/profile_logo.jpg',
        username: username,
      ),
      body: Row(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
          if (isLargeScreen)
            Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Quick Links",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    title: const Text("Add Music"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddMusicPage(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text("Favorites"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Favpage(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text("Beats"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BeatsPage(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text("Search"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Searchpage(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text("Settings"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(boxShadow: [
          BoxShadow(
            blurRadius: 90,
            color: Color.fromARGB(255, 57, 57, 57),
          ),
        ]),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(40)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: GNav(
              haptic: true,
              rippleColor: Colors.grey,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              gap: 8,
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              padding: const EdgeInsets.all(16),
              tabs: const [
                GButton(
                  icon: Icons.home,
                  text: "Home",
                ),
                GButton(
                  icon: Icons.favorite_border,
                  text: "Favorites",
                  iconActiveColor: Colors.red,
                ),
                GButton(
                  icon: Icons.polymer_sharp,
                ),
                GButton(
                  icon: Icons.search,
                  text: "Search",
                ),
                GButton(
                  icon: Icons.settings,
                  text: "Settings",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// HomePageContent
class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    final playlistProvider = Provider.of<PlaylistProvider>(context);

    return SingleChildScrollView(
        child: Column(children: [
      const SizedBox(height: 10),
      const Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20.0),
            child: Text(
              "Top 5 Artists",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),

      // Horizontal List View for Top Artists
      SizedBox(
        height: 200,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('songs').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final songs = snapshot.data!.docs;

            // Aggregating playCounts by artistName
            final Map<String, int> artistPlayCounts = {};

            for (var song in songs) {
              String artistName = song['artistName'] ?? 'Unknown Artist';
              int playCount = song['playCount'] ?? 0;

              if (artistPlayCounts.containsKey(artistName)) {
                artistPlayCounts[artistName] =
                    artistPlayCounts[artistName]! + playCount;
              } else {
                artistPlayCounts[artistName] = playCount;
              }
            }

            // Sorting artists by playCount in descending order
            var sortedArtists = artistPlayCounts.keys.toList()
              ..sort((a, b) =>
                  artistPlayCounts[b]!.compareTo(artistPlayCounts[a]!));

            // Limit the number of artists displayed (e.g., top 5)
            final topArtists = sortedArtists.take(5).toList();

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: topArtists.length,
              itemBuilder: (context, index) {
                String artistName = topArtists[index];

                // Fetch artist data from the 'users' collection
                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .where('artistName', isEqualTo: artistName)
                      .limit(10)
                      .get(),
                  builder: (context, artistSnapshot) {
                    if (artistSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!artistSnapshot.hasData ||
                        artistSnapshot.data!.docs.isEmpty) {
                      return const SizedBox(); // If no artist data is found, show nothing
                    }

                    var artistData = artistSnapshot.data!.docs.first.data()
                        as Map<String, dynamic>;

                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to Artist Profile Page using artistName
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ArtistProfilePage(artistName: artistName),
                            ),
                          );
                        },
                        child: Container(
                          width: 153,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey.shade200,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage:
                                    NetworkImage(artistData['profileImageUrl']),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                artistData['artistName'],
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),

      const SizedBox(height: 10),

      const Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20.0),
            child: Text(
              "Trending",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),

      const SizedBox(height: 10),
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('songs')
            .orderBy('playCount', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final songs = snapshot.data!.docs;

          return ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: songs.length,
            itemBuilder: (context, index) {
              var song = songs[index];

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
                          final songId = song.id;
                          final songIndex =
                              playlistProvider.getIndexById(songId);

                          // Debugging line to check tapped song ID
                          print('Tapped Song ID: $songId');

                          if (songIndex != null) {
                            playlistProvider.setCurrentSong(songIndex);

                            // Navigate to player page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SongPage(index: songIndex),
                              ),
                            );
                          } else {
                            print('Song index not found! ID: $songId');
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
      )
    ]));
  }
}
