import 'package:beat_bazaar/models/playlist_provider.dart';
import 'package:beat_bazaar/pages/auth/check.dart';
import 'package:beat_bazaar/pages/homepage.dart';
import 'package:beat_bazaar/pages/settings_page.dart';
import 'package:beat_bazaar/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ChangeNotifierProvider(create: (context) => PlaylistProvider()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          theme: themeProvider.themeData,
          debugShowCheckedModeBanner: false,
          home: const CheckAuth(),
          routes: {
            '/homepage': (context) => const HomePage(),
            '/settings': (context) => const SettingsPage(),
            // Add other routes
          },
        );
      },
    );
  }
}
