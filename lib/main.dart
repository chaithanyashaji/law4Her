import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:law4her/splashscreen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific configuration
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBkm1V_86doUEbtGGeydiiOssKH6Hgp-J0",
        authDomain: "law4her-3ce9a.firebaseapp.com",
        projectId: "law4her-3ce9a",
        storageBucket: "law4her-3ce9a.appspot.com",
        messagingSenderId: "1058685362057",
        appId: "1:1058685362057:web:04d306b9c0d38b98b28b58",
        measurementId: "G-VY1YYZ72P8",
      ),
    );
  } else {
    await Firebase.initializeApp(); // Default initialization for mobile
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Law4Her',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFc5d0d3), // Dark background
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF416d6d), // Navbar background
          iconTheme: const IconThemeData(color: Colors.white), // White icons
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.white, // White text
            fontSize: 20,
          ),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(

        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF416d6d), // Button background
            textStyle: GoogleFonts.poppins(
              color: Colors.white, // Button text
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFc5d0d3), // Highlight color
          primary: const Color(0xFF608E8E), // Primary color
          secondary: const Color(0xFF416d6d), // Secondary color
        ),
      ),
      home: Splashscreen(),
    );
  }
}