import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ArtistProfilePage extends StatelessWidget {
  final String artistName;

  const ArtistProfilePage({super.key, required this.artistName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'P R O F I L E',
          style: TextStyle(fontFamily: 'Audiowide'),
        ),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .where('artistName', isEqualTo: artistName)
            .get(), // Fetch artist data using artistName
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No artist found'));
          }

          final artistData =
              snapshot.data!.docs.first.data() as Map<String, dynamic>;

          // Safely accessing data with null checks
          final profileImageUrl = artistData['profileImageUrl'] ?? '';
          // ignore: unnecessary_string_interpolations
          final artistDisplayName = artistData['name'] ?? '$artistName';
          final description =
              artistData['description'] ?? 'No description available.';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : const AssetImage('assets/default_avatar.png')
                        as ImageProvider,
              ),
              const SizedBox(height: 20),
              Text(
                artistDisplayName,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(description),
              const SizedBox(height: 30),
              const Text(
                'Uploaded Songs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('songs')
                      .where('artistName',
                          isEqualTo: artistName) // Fetch songs by artistName
                      .snapshots(),
                  builder: (context, songSnapshot) {
                    if (!songSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final songs = songSnapshot.data!.docs;

                    if (songs.isEmpty) {
                      return const Center(
                          child: Text('No songs uploaded by this artist.'));
                    }

                    return ListView.builder(
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        var song = songs[index];
                        final songName = song['songName'] ?? 'Unknown Song';

                        return ListTile(
                          leading: const Icon(Icons.music_note),
                          title: Text(songName),
                          subtitle: Text(song['artistName']),
                          onTap: () {
                            // Add your song play logic here
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
