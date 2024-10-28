import 'package:beat_bazaar/components/neu_box.dart';
import 'package:beat_bazaar/models/playlist_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SongPage extends StatefulWidget {
  final int index;

  const SongPage({
    super.key,
    required this.index,
  });

  @override
  State<SongPage> createState() => _SongPageState();
}

class _SongPageState extends State<SongPage> {
  // Convert duration to a formatted string
  String formatTime(Duration duration) {
    String twoDigitsSeconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "${duration.inMinutes}:$twoDigitsSeconds";
  }

  @override
  void initState() {
    super.initState();
    final playlistProvider =
        Provider.of<PlaylistProvider>(context, listen: false);
    playlistProvider.setCurrentSong(widget.index);
  }

  void _toggleFavorite(PlaylistProvider playlistProvider) {
    final currentSongIndex = playlistProvider.currentSongIndex;
    if (currentSongIndex != null) {
      playlistProvider
          .toggleFavorite(currentSongIndex); // Call the provider's method
      print(
          'Favorite toggled for song at index: $currentSongIndex'); // Debugging
    } else {
      print('No current song index available'); // Debugging
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
        builder: (context, playlistProvider, child) {
      final currentSongIndex = playlistProvider.currentSongIndex;
      print('Building SongPage. Current song index: $currentSongIndex');

      if (currentSongIndex == null || playlistProvider.playlist.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      final currentSong = playlistProvider.playlist[currentSongIndex];

      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 25, right: 25, bottom: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Text("N O W  P L A Y I N G"),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
                  ],
                ),
                const SizedBox(height: 25),
                NeuBox(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(currentSong.albumArtImagePath),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentSong.songName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                                Text(currentSong.artistName),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                currentSong.isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color:
                                    currentSong.isFavorite ? Colors.red : null,
                              ),
                              onPressed: () =>
                                  _toggleFavorite(playlistProvider),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(formatTime(playlistProvider.currentDuration)),
                          const Icon(Icons.shuffle),
                          const Icon(Icons.repeat),
                          Text(formatTime(playlistProvider.totalDuration)),
                        ],
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 0),
                      ),
                      child: Slider(
                        min: 0,
                        max: playlistProvider.totalDuration.inSeconds > 0
                            ? playlistProvider.totalDuration.inSeconds
                                .toDouble()
                            : 1.0,
                        value: playlistProvider.currentDuration.inSeconds
                            .toDouble()
                            .clamp(
                                0.0,
                                playlistProvider.totalDuration.inSeconds
                                    .toDouble()),
                        activeColor: Colors.deepPurple,
                        onChanged: (double newValue) {},
                        onChangeEnd: (double newValue) {
                          playlistProvider
                              .seek(Duration(seconds: newValue.toInt()));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: playlistProvider.playPreviousSong,
                        child: const NeuBox(
                          child: Icon(Icons.skip_previous),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: playlistProvider.pauseOrResume,
                        child: NeuBox(
                          child: Icon(
                            playlistProvider.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: GestureDetector(
                        onTap: playlistProvider.playNextSong,
                        child: const NeuBox(child: Icon(Icons.skip_next)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
