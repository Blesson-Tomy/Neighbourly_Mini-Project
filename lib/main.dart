import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mini_ui/splash.dart';
import './styles/styles.dart';

// class Config {
//     String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
// }
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await dotenv.load();

  runApp(const MyApp());
  try {
    await Firebase.initializeApp();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Styles.darkPurple, // Replace with your desired color
    ));

    runApp(const MyApp());
  } catch (e) {
    print("Firebase initialization error: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Removes debug banner
      title: 'NEIGHBOURLY',
      theme: ThemeData.light(), // Optional: Change theme
      home: const SplashScreen(), // Set LoginScreen as the first screen
    );
  }
}
