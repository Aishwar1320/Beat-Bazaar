import 'package:beat_bazaar/components/my_button.dart';
import 'package:beat_bazaar/components/my_textfield.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

class AddMusicPage extends StatefulWidget {
  const AddMusicPage({super.key});

  @override
  _AddMusicPageState createState() => _AddMusicPageState();
}

class _AddMusicPageState extends State<AddMusicPage> {
  File? _songFile;
  File? _imageFile;
  final TextEditingController _songNameController = TextEditingController();
  final TextEditingController _artistNameController = TextEditingController();
  bool _isUploading = false;

  Future<void> pickSongFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
    );

    if (result != null) {
      setState(() {
        _songFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> pickImageFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _imageFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> uploadFile() async {
    if (_songFile == null ||
        _imageFile == null ||
        _songNameController.text.isEmpty ||
        _artistNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill all fields and select files')));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload song file
      String songFileName =
          'songs/${DateTime.now().millisecondsSinceEpoch}.mp3';
      Reference songRef = FirebaseStorage.instance.ref().child(songFileName);
      await songRef.putFile(_songFile!);

      // Upload image file
      String imageFileName =
          'images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference imageRef = FirebaseStorage.instance.ref().child(imageFileName);
      await imageRef.putFile(_imageFile!);

      String audioPath = await songRef.getDownloadURL();
      String albumArtImagePath = await imageRef.getDownloadURL();

      // Get current user ID
      final User? user = FirebaseAuth.instance.currentUser;
      final String userId = user!.uid;

      // Store the song in Firestore with user ID
      DocumentReference songDocRef =
          await FirebaseFirestore.instance.collection('songs').add({
        'songName': _songNameController.text,
        'artistName': _artistNameController.text,
        'audioPath': audioPath,
        'albumArtImagePath': albumArtImagePath,
        'uploadedAt': Timestamp.now(),
        'userId': userId,
        'playCount': 0,
      });

      // Update the user's collection and increment uploadedSongsCount
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      // Create a reference to the artist's document
      String artistName = _artistNameController.text;
      DocumentReference artistRef =
          FirebaseFirestore.instance.collection('users').doc(artistName);

      FirebaseFirestore.instance.runTransaction((transaction) async {
        // Check if the user exists and update their uploadedSongsCount
        DocumentSnapshot userSnapshot = await transaction.get(userRef);
        if (userSnapshot.exists) {
          int newCount = (userSnapshot.get('uploadedSongsCount') ?? 0) + 1;
          transaction.update(userRef, {
            'uploadedSongsCount': newCount,
            'favorites': FieldValue.arrayUnion([songDocRef.id]),
          });
        }

        // Check if the artist exists and create if not
        DocumentSnapshot artistSnapshot = await transaction.get(artistRef);
        if (!artistSnapshot.exists) {
          transaction.set(artistRef, {
            'artistName': artistName,
            'uploadedSongsCount':
                1, // Start with 1 since this is the first song
          });
        } else {
          int artistNewCount =
              (artistSnapshot.get('uploadedSongsCount') ?? 0) + 1;
          transaction.update(artistRef, {
            'uploadedSongsCount': artistNewCount,
          });
        }
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Upload successful')));
      setState(() {
        _songFile = null;
        _imageFile = null;
        _songNameController.clear();
        _artistNameController.clear();
        _isUploading = false;
      });
    } catch (e) {
      print('Error uploading file: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error uploading file')));
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "A D D  M U S I C",
          style: TextStyle(fontFamily: 'Audiowide'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),

                // logo
                const Icon(
                  Icons.upload_rounded,
                  size: 100,
                ),

                const SizedBox(height: 10),

                // description
                Text(
                  "Upload your creativity below!",
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 25),

                MyTextField(
                  controller: _songNameController,
                  hintText: 'Song Name',
                  obscureText: false,
                ),

                const SizedBox(height: 25),

                MyTextField(
                  controller: _artistNameController,
                  hintText: 'Artist Name',
                  obscureText: false,
                ),

                const SizedBox(height: 20),

                // Upload Song button
                ElevatedButton(
                  onPressed: _isUploading ? null : pickSongFile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 80, vertical: 25),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.music_note, color: Colors.black),
                      const SizedBox(width: 10),
                      if (_isUploading)
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      else
                        Text(
                          _songFile == null ? 'Upload Song' : 'Song Selected',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Upload Image button
                ElevatedButton(
                  onPressed: _isUploading ? null : pickImageFile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 80, vertical: 25),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.image, color: Colors.black),
                      const SizedBox(width: 10),
                      if (_isUploading)
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      else
                        Text(
                          _imageFile == null
                              ? 'Upload Image'
                              : 'Image Selected',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _isUploading
                    ? const CircularProgressIndicator()
                    : MyButton(
                        onTap: () async {
                          setState(() {
                            _isUploading = true;
                          });

                          await uploadFile();

                          setState(() {
                            _isUploading = false;
                          });
                        },
                        text: 'Upload',
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
