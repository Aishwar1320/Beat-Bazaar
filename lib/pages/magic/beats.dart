import 'dart:convert';
import 'package:beat_bazaar/components/my_drawer.dart';
import 'package:beat_bazaar/models/playlist_provider.dart';
import 'package:beat_bazaar/responsive/player_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:another_audio_recorder/another_audio_recorder.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class BeatsPage extends StatefulWidget {
  const BeatsPage({super.key});

  @override
  State<BeatsPage> createState() => _BeatsPageState();
}

class _BeatsPageState extends State<BeatsPage> {
  late AnotherAudioRecorder _recorder;
  //String _result = 'Tap to recognize a song';
  bool _isRecording = false;
  String? _recordedPath;
  String? profileImageUrl;
  String username = '';

  @override
  void initState() {
    super.initState();
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;

    final status = await Permission.microphone.request();
    if (status.isGranted) {
      try {
        setState(() {
          _isRecording = true;
          //_result = 'Listening...';
        });

        final directory = await getTemporaryDirectory();
        _recordedPath = '${directory.path}/audio.wav';

        if (await File(_recordedPath!).exists()) {
          await File(_recordedPath!).delete();
        }

        _recorder =
            AnotherAudioRecorder(_recordedPath!, audioFormat: AudioFormat.WAV);
        await _recorder.initialized;
        await _recorder.start();
        print("Recording started...");
      } catch (e) {
        print("Error starting recorder: $e");
        setState(() {
          //_result = 'Error starting recorder: $e';
          _isRecording = false;
        });
      }
    } else {
      setState(() {
        //_result = 'Microphone permission denied';
      });
      if (status.isPermanentlyDenied) {
        openAppSettings();
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      final recording = await _recorder.stop();
      setState(() {
        _isRecording = false;
      });
      print("Recording stopped.");

      final path = recording?.path;
      if (path != null && await File(path).exists()) {
        print("Recording file path: $path");
        final audioData = await File(path).readAsBytes();
        print("Audio data size: ${audioData.length} bytes");

        if (audioData.isNotEmpty) {
          await _sendAudioToACRCloud(audioData);
        } else {
          setState(() {
            //_result = 'Recorded audio data is empty.';
          });
        }
      } else {
        setState(() {
          // _result = 'Recording failed. Please try again.';
        });
      }
    } catch (e) {
      print("Error stopping recorder: $e");
      setState(() {
        //_result = 'Error stopping recorder: $e';
      });
    }
  }

  Future<void> _sendAudioToACRCloud(Uint8List audioData) async {
    const accessKey = 'c15ff15211186c6fa170dcc7963ee8b1';
    const accessSecret = 'Hj7w0DlWnLB1SBfMbn285YR31xIQf8b3DR0cbMoI';
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString();
    const dataType = 'audio';
    const signatureVersion = '1';

    final stringToSign =
        'POST\n/v1/identify\n$accessKey\n$dataType\n$signatureVersion\n$timestamp';
    final signature = base64.encode(Hmac(sha1, utf8.encode(accessSecret))
        .convert(utf8.encode(stringToSign))
        .bytes);

    final uri =
        Uri.parse('https://identify-ap-southeast-1.acrcloud.com/v1/identify');

    var request = http.MultipartRequest('POST', uri);
    request.fields['access_key'] = accessKey;
    request.fields['sample_bytes'] = audioData.length.toString();
    request.fields['timestamp'] = timestamp;
    request.fields['signature'] = signature;
    request.fields['data_type'] = dataType;
    request.fields['signature_version'] = signatureVersion;

    request.files.add(http.MultipartFile.fromBytes(
      'sample',
      audioData,
      filename: 'audio.wav',
      contentType: MediaType('audio', 'wav'),
    ));

    try {
      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson =
            json.decode(responseData.body);

        // Check if a song title was recognized
        if (responseJson.containsKey('metadata') &&
            responseJson['metadata'].containsKey('custom_files') &&
            responseJson['metadata']['custom_files'].isNotEmpty) {
          final songTitle =
              responseJson['metadata']['custom_files'][0]['title'];

          // Fetch Firebase data for the recognized song title
          final songSnapshot = await FirebaseFirestore.instance
              .collection('songs')
              .where('songName', isEqualTo: songTitle)
              .get();

          if (songSnapshot.docs.isNotEmpty) {
            final songData = songSnapshot.docs.first.data();
            _showResultDialog(
              songName: songTitle,
              artistName: songData['artistName'],
              albumArtImagePath: songData['albumArtImagePath'],
              isFavorite: songData['isFavorite'],
            );
          } else {
            _showResultDialog(
              songName: songTitle,
              artistName: 'Unknown Artist',
              albumArtImagePath: '',
              isFavorite: false,
            );
          }
        } else {
          // No song recognized; reset the button and result message
          setState(() {
            //_result = 'No song recognized';
            _isRecording = false;
          });
        }
      } else {
        // Error in response; reset button and result
        setState(() {
          //_result = 'Recognition failed';
          _isRecording = false;
        });
      }
    } catch (e) {
      // Exception; reset button and result
      setState(() {
        //_result = 'Recognition failed';
        _isRecording = false;
      });
    }
  }

  void _showResultDialog({
    required String songName,
    required String artistName,
    required String albumArtImagePath,
    required bool isFavorite,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "S O N G  R E C O G N I Z E D!",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Audiowide'),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    albumArtImagePath.isNotEmpty
                        ? albumArtImagePath
                        : 'https://example.com/default_image.png',
                    width: 100,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  songName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  artistName,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to the SongPage here
                    Navigator.of(context).pop(); // Close the dialog first
                    _navigateToSongPage(
                        songName, artistName, albumArtImagePath, isFavorite);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                  ),
                  child: const Text(
                    "Go To Player",
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToSongPage(String songName, String artistName,
      String albumArtImagePath, bool isFavorite) {
    // Use the provider to find the index of the song, or manage it differently if needed.
    final playlistProvider =
        Provider.of<PlaylistProvider>(context, listen: false);
    final songIndex = playlistProvider.playlist
        .indexWhere((song) => song.songName == songName);

    if (songIndex != -1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SongPage(index: songIndex),
        ),
      );
    } else {
      // Handle case where song is not found in the playlist
      print('Song not found in playlist.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "C A P T U R E  B E A T S",
          style: TextStyle(fontFamily: 'Audiowide'),
        ),
      ),
      drawer: MyDrawer(
        profileImageUrl:
            profileImageUrl ?? 'https://example.com/default_avatar.png',
        username: username,
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animated wave effect surrounding the button
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: _isRecording ? 200 : 120,
              height: _isRecording ? 200 : 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording
                    ? Colors.red.withOpacity(0.3)
                    : Colors.deepPurple.withOpacity(0.1),
              ),
              child: const SizedBox.shrink(),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: _isRecording ? 250 : 160,
              height: _isRecording ? 250 : 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording
                    ? Colors.red.withOpacity(0.2)
                    : Colors.deepPurple.withOpacity(0.05),
              ),
              child: const SizedBox.shrink(),
            ),
            // Main button with elevated effect
            Material(
              elevation: 10, // Adds shadow to give an elevated effect
              shape: const CircleBorder(),
              child: GestureDetector(
                onTap: _isRecording ? _stopRecording : _startRecording,
                child: CircleAvatar(
                  radius: 60, // Button size
                  backgroundColor:
                      _isRecording ? Colors.red : Colors.deepPurple,
                  child: const Icon(
                    Icons.polymer_sharp,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
