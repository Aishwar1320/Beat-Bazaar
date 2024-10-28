import 'package:beat_bazaar/components/neu_box.dart';
import 'package:beat_bazaar/models/playlist_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SongPageDesktop extends StatefulWidget {
  final int index;

  const SongPageDesktop({super.key, required this.index});

  @override
  State<SongPageDesktop> createState() => _SongPageDesktopState();
}

class _SongPageDesktopState extends State<SongPageDesktop> {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
        builder: (context, playlistProvider, child) {
      //final playlist = playlistProvider.playlist;
      final currentSongIndex = playlistProvider.currentSongIndex;
      print('Building SongPageDesktop. Current song index: $currentSongIndex');

      if (currentSongIndex == null || playlistProvider.playlist.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      //If there is a valid song, display it
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
                    // Back button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),

                    // Title
                    const Text("N O W  P L A Y I N G"),

                    // Menu button
                    IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
                  ],
                ),

                const SizedBox(height: 25),

                // Album art and song details
                NeuBox(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(currentSong.albumArtImagePath),
                      ),

                      // Song name and artist
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
                            const Icon(
                              Icons.favorite,
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Time and slider
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Current time
                          Text(formatTime(playlistProvider.currentDuration)),

                          // Shuffle and repeat buttons
                          const Icon(Icons.shuffle),
                          const Icon(Icons.repeat),

                          // Total duration
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

                // Playback controls
                Row(
                  children: [
                    // Previous song button
                    Expanded(
                      child: GestureDetector(
                        onTap: playlistProvider.playPreviousSong,
                        child: const NeuBox(
                          child: Icon(Icons.skip_previous),
                        ),
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Play/pause button
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

                    // Next song button
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
