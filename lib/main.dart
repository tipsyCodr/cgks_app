import 'package:flutter/material.dart';
import 'package:cgks/video_splash_screen.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins'),
      home: VideoSplashScreen(),
    ),
  );
}
