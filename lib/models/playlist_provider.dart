import 'package:audioplayers/audioplayers.dart';
import 'package:beat_bazaar/models/song.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PlaylistProvider extends ChangeNotifier {
  final List<Song> _playlist = [];
  int? currentSongIndex;

  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _currentDuration = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = true;

  PlaylistProvider() {
    _initAudioPlayerListeners();
    fetchSongsFromFirebase(); // Fetch songs from Firebase on init
  }

  List<Song> get playlist => _playlist;
  bool get isLoading => _isLoading;

  /// Fetch songs from Firebase Firestore
  void fetchSongsFromFirebase() {
    FirebaseFirestore.instance
        .collection('songs')
        .orderBy('playCount', descending: true)
        .snapshots()
        .listen((snapshot) {
      _playlist.clear(); // Clear existing songs
      for (var doc in snapshot.docs) {
        _playlist.add(Song(
          songName: doc['songName'],
          artistName: doc['artistName'],
          albumArtImagePath: doc['albumArtImagePath'],
          audioPath: doc['audioPath'],
          playCount: doc['playCount'] ?? 0,
          id: doc.id,
          isFavorite: doc['isFavorite'] ?? false,
        ));
        print(
            'Added song: ${doc['songName']} with ID: ${doc.id}'); // Debugging line
      }

      _isLoading = false; // Set loading to false after fetching
      notifyListeners();
    });
  }

  /// Set the current song by index and play it
  void setCurrentSong(int index) {
    if (index >= 0 && index < _playlist.length) {
      currentSongIndex = index;
      print('Current song index set to: $currentSongIndex');
      play(); // This will now only increment the count once
      notifyListeners();
    } else {
      print('Invalid index: $index');
    }
  }

  /// Play the current song
  void play() async {
    if (currentSongIndex == null || _playlist.isEmpty) return;

    final String path = _playlist[currentSongIndex!].audioPath;
    final String songId = _playlist[currentSongIndex!].id; // Get the song ID

    try {
      await _audioPlayer.stop(); // Stop any currently playing audio

      if (path.startsWith('http')) {
        await _audioPlayer.play(UrlSource(path)); // Play from URL
      } else {
        await _audioPlayer.play(AssetSource(path)); // Play from assets
      }

      // Only call updatePlayCount to handle Firestore updates
      await updatePlayCount(songId);

      _isPlaying = true; // Update playing state
      notifyListeners();
    } catch (e) {
      print("Error playing song: $e");
    }
  }

  /// Update play count in Firestore
  Future<void> updatePlayCount(String songId) async {
    try {
      DocumentReference songRef =
          FirebaseFirestore.instance.collection('songs').doc(songId);
      await songRef.update({
        'playCount': FieldValue.increment(1), // Increment the playCount by 1
      });
      notifyListeners(); // Notify listeners of play count update
    } catch (e) {
      print("Error updating play count: $e");
    }
  }

  /// Pause or resume the current song
  void pauseOrResume() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  /// Play the previous song
  void playPreviousSong() {
    if (currentSongIndex != null) {
      currentSongIndex = (currentSongIndex! - 1) < 0
          ? _playlist.length - 1
          : currentSongIndex! - 1;
      play();
      notifyListeners();
    }
  }

  /// Play the next song
  void playNextSong() {
    if (currentSongIndex != null) {
      currentSongIndex = (currentSongIndex! + 1) % _playlist.length;
      play();
      notifyListeners();
    }
  }

  /// Seek
  void seek(Duration position) async {
    await _audioPlayer.seek(position);
    _currentDuration = position;
    notifyListeners();
  }

  /// Get song index by Firebase document ID
  int? getIndexById(String songId) {
    for (int i = 0; i < _playlist.length; i++) {
      if (_playlist[i].id == songId) {
        return i;
      }
    }
    return null; // If not found, return null
  }

  /// Initialize audio player listeners
  void _initAudioPlayerListeners() {
    _audioPlayer.onDurationChanged.listen((Duration newDuration) {
      _totalDuration = newDuration;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((Duration newPosition) {
      _currentDuration = newPosition;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      playNextSong();
    });
  }

  // Toggle the favorite status of the current song
  void toggleFavorite(int index) async {
    if (index >= 0 && index < _playlist.length) {
      _playlist[index].isFavorite = !_playlist[index].isFavorite; // Toggle

      // Call Firestore update
      await updateFavoriteStatus(
          _playlist[index].id, _playlist[index].isFavorite);

      print(
          'Toggled favorite for song: ${_playlist[index].songName} to ${_playlist[index].isFavorite}');
      notifyListeners(); // Notify UI
    }
  }

  Future<void> updateFavoriteStatus(String songId, bool isFavorite) async {
    try {
      DocumentReference songRef =
          FirebaseFirestore.instance.collection('songs').doc(songId);
      await songRef.update({
        'isFavorite': isFavorite, // Update the favorite status in Firestore
      });
      print("Updated favorite status for song: $songId to $isFavorite");
    } catch (e) {
      print("Error updating favorite status: $e");
    }
  }

  // Getters for the playlist provider state
  bool get isPlaying => _isPlaying;
  Duration get currentDuration => _currentDuration;
  Duration get totalDuration => _totalDuration;
}
