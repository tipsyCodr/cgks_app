import 'package:flutter/material.dart';

class FullscreenImagePage extends StatelessWidget {
  final String imageUrl;
  final bool isAsset;

  const FullscreenImagePage({
    super.key,
    required this.imageUrl,
    this.isAsset = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          // <-- pinch to zoom support
          child: isAsset
              ? Image.asset(imageUrl, fit: BoxFit.contain)
              : Image.network(imageUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
