import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:law4her/splashscreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();
  // Initialize Firebase with platform-specific configuration
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['API_KEY'] ?? '',
        authDomain: dotenv.env['AUTH_DOMAIN'] ?? '',
        projectId: dotenv.env['PROJECT_ID'] ?? '',
        storageBucket: dotenv.env['STORAGE_BUCKET'] ?? '',
        messagingSenderId: dotenv.env['MESSAGING_SENDER_ID'] ?? '',
        appId: dotenv.env['APP_ID'] ?? '',
        measurementId: dotenv.env['MEASUREMENT_ID'] ?? '',

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
