import 'package:beat_bazaar/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:beat_bazaar/components/my_button.dart';
import 'package:beat_bazaar/components/my_textfield.dart';
import 'package:beat_bazaar/components/square_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final usernameController = TextEditingController();

  // Selected image file
  File? _imageFile;

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  // Sign user up method
  void signUserUp() async {
    // Input validation
    if (usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      showErrorMessage("Please fill in all fields.");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      showErrorMessage("Passwords don't match");
      return;
    }

    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Upload profile image if selected
      String imageUrl = '';
      if (_imageFile != null) {
        imageUrl = await uploadProfileImageToFirebase(userCredential.user?.uid);
        if (imageUrl.isEmpty) {
          Navigator.pop(context);
          showErrorMessage("Image upload failed.");
          return;
        }
      }

      // Store user metadata in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .set({
        'uid': userCredential.user?.uid,
        'username': usernameController.text,
        'email': emailController.text,
        'profileImageUrl': imageUrl,
        'uploadedSongsCount': 0,
        'favorites': [],
      });

      Navigator.pop(context);
      Navigator.pushReplacementNamed(context, '/homepage');
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      showErrorMessage(e.code);
    } catch (e) {
      Navigator.pop(context);
      print("Error: $e"); // Log unexpected errors
      showErrorMessage("An unexpected error occurred.");
    }
  }

  // Function to upload profile image to Firebase Storage
  Future<String> uploadProfileImageToFirebase(String? uid) async {
    if (_imageFile == null) return '';

    try {
      String imageFileName =
          'images/${uid}_${DateTime.now().millisecondsSinceEpoch}.jpeg';
      Reference imageRef = FirebaseStorage.instance.ref().child(imageFileName);
      await imageRef.putFile(_imageFile!);
      String imageUrl = await imageRef.getDownloadURL();
      print('Image uploaded. Download URL: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    }
  }

  // Method to show error messages
  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: Text(message),
          ),
        );
      },
    );
  }

  // Method to pick an image from gallery
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                const Icon(Icons.lock, size: 50),
                const SizedBox(height: 50),
                Text(
                  'Make your new account right now!',
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
                const SizedBox(height: 25),
                MyTextField(
                  controller: usernameController,
                  hintText: 'Username',
                  obscureText: false,
                ),
                const SizedBox(height: 10),
                MyTextField(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                ),
                const SizedBox(height: 10),
                MyTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                MyTextField(
                  controller: confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _imageFile == null
                              ? 'Select Profile Image'
                              : 'Image Selected',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt),
                          onPressed: pickImage,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _imageFile != null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.file(
                            _imageFile!,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.check, color: Colors.green),
                        ],
                      )
                    : const SizedBox.shrink(),
                const SizedBox(height: 25),
                MyButton(
                  text: "Sign Up",
                  onTap: signUserUp,
                ),
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(thickness: 0.5, color: Colors.grey[400]),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'Or continue with',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      Expanded(
                        child: Divider(thickness: 0.5, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SquareTile(
                      onTap: () => AuthService().signInWithGoogle(context),
                      imagePath: 'assets/images/google.png',
                    ),
                    const SizedBox(width: 25),
                    SquareTile(
                      onTap: () {},
                      imagePath: 'assets/images/apple.png',
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Login now',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
