import 'package:flutter/material.dart';
import 'package:cgks/video_splash_screen.dart';

import 'package:cgks/constants.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Constants.darkTheme,
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
