import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

Future<void> uploadFile(
    File songFile, File imageFile, String songName, String artistName) async {
  try {
    // Upload song file
    String songFileName = 'songs/${DateTime.now().millisecondsSinceEpoch}.mp3';
    Reference songRef = FirebaseStorage.instance.ref().child(songFileName);
    await songRef.putFile(songFile);

    // Upload image file
    String imageFileName =
        'images/${DateTime.now().millisecondsSinceEpoch}.jpeg';
    Reference imageRef = FirebaseStorage.instance.ref().child(imageFileName);
    await imageRef.putFile(imageFile);

    // Get download URLs for both files
    String songUrl = await songRef.getDownloadURL();
    String imageUrl = await imageRef.getDownloadURL();

    // Save song metadata to Firestore
    await FirebaseFirestore.instance.collection('songs').add({
      'songName': songName,
      'artistName': artistName,
      'songUrl': songUrl,
      'imageUrl': imageUrl,
      'uploadedAt': Timestamp.now(),
    });
  } catch (e) {
    print('Error uploading file: $e');
  }
}
