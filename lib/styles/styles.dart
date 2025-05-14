import 'package:flutter/material.dart';

mixin Styles {
  // Colors
  static const Color darkPurple = Color(0xFF2D1E59);
  static const Color lightPurple = Color(0xFF826DA6);
  static const Color veryLightPurple = Color.fromARGB(255, 173, 158, 199);
  static const Color mildPurple = Color.fromARGB(255, 99, 78, 134);
  static const Color white = Colors.white;
  static const Color offWhite = Color.fromARGB(255, 202, 202, 202);

  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    color: white,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle nameStyle = TextStyle(
    color: white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: white,
    fontSize: 16,
  );

  static const TextStyle settingsTitleStyle = TextStyle(
    color: white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 18,
    color: Colors.white,
    fontWeight: FontWeight.w400,
  ); 

  // Box Decorations
  static BoxDecoration boxDecoration = BoxDecoration(
    color: lightPurple,
    borderRadius: BorderRadius.circular(20),
  );

  // Button Style
  static ButtonStyle settingsButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Styles.mildPurple,
    // shadowColor: Colors.transparent,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );

  static InputDecoration inputDecoration = InputDecoration(
    prefixIcon:  Icon(Icons.edit, color: Colors.white),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide:  BorderSide(color: Colors.white, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide:  BorderSide(color: Colors.white, width: 1),
    ),
  );

  // Helper function to create pill-shaped containers
  static Widget buildPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      decoration: BoxDecoration(
        color: color, // Use the passed color for background
        borderRadius: BorderRadius.circular(20), // Rounded pill shape
      ),
      child: Text(
        text,
        style: Styles.buttonTextStyle.copyWith(fontSize: 14, color: Colors.white),
      ),
    );
  }
}
