import 'package:flutter/material.dart';
import 'package:cgks/video_splash_screen.dart';

import 'package:cgks/constants.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Constants.darkTheme,
        colorScheme: const ColorScheme.dark(
          surface: Constants.darkTheme,
          onSurface: Colors.white,
          primary: Colors.red,
          onPrimary: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF1E2529),
          labelStyle: TextStyle(color: Colors.white70),
          hintStyle: TextStyle(color: Colors.white54),
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white30),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.redAccent, width: 2),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Constants.darkTheme,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      home: VideoSplashScreen(),
    ),
  );
}
