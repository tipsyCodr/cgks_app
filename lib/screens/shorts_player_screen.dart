import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ShortsPlayerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> shorts;
  final int initialIndex;

  const ShortsPlayerScreen({
    super.key,
    required this.shorts,
    required this.initialIndex,
  });

  @override
  State<ShortsPlayerScreen> createState() => _ShortsPlayerScreenState();
}

class _ShortsPlayerScreenState extends State<ShortsPlayerScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.shorts.length,
        itemBuilder: (context, index) {
          return ShortsVideoItem(short: widget.shorts[index]);
        },
      ),
    );
  }
}

class ShortsVideoItem extends StatefulWidget {
  final Map<String, dynamic> short;

  const ShortsVideoItem({super.key, required this.short});

  @override
  State<ShortsVideoItem> createState() => _ShortsVideoItemState();
}

class _ShortsVideoItemState extends State<ShortsVideoItem> {
  YoutubePlayerController? _youtubeController;
  bool _isYoutube = false;

  @override
  void initState() {
    super.initState();
    final platform = widget.short['platform']?.toString().toLowerCase();
    final type = widget.short['type']?.toString().toLowerCase();
    final url = widget.short['url'] ?? '';

    // Prioritize 'platform' field, then 'type', then URL detection
    if (platform == 'youtube' ||
        (platform == null && type == 'youtube') ||
        (platform == null &&
            type == null &&
            (url.contains('youtube.com') || url.contains('youtu.be')))) {
      _isYoutube = true;
      final videoId = YoutubePlayer.convertUrlToId(url);
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            isLive: false,
            forceHD: true,
            hideControls: true,
            loop: true,
          ),
        );
      }
    } else {
      // Assume Instagram or other web-based player if not YouTube
      _isYoutube = false;
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  void _shareShort() {
    final url = widget.short['url'];
    if (url != null) {
      Share.share('Check out this video: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Video Content
        // Video Content
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: _isYoutube
                ? (_youtubeController != null
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            child: YoutubePlayer(
                              controller: _youtubeController!,
                              showVideoProgressIndicator: true,
                              progressIndicatorColor: Colors.red,
                            ),
                          ),
                        )
                      : const Center(
                          child: Text(
                            "Invalid YouTube URL",
                            style: TextStyle(color: Colors.white),
                          ),
                        ))
                : InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri(
                        widget.short['url'] ?? 'https://instagram.com',
                      ),
                    ),
                    initialSettings: InAppWebViewSettings(
                      userAgent:
                          "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36",
                      javaScriptEnabled: true,
                      domStorageEnabled: true,
                      mediaPlaybackRequiresUserGesture: false,
                      allowsInlineMediaPlayback: true,
                      transparentBackground: true,
                      useWideViewPort: true,
                      loadWithOverviewMode: true,
                      mixedContentMode:
                          MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                    ),
                  ),
          ),
        ),

        // Overlay Controls
        Positioned(
          top: 40,
          left: 16,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        Positioned(
          bottom: 40,
          right: 16,
          child: Column(
            children: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white, size: 30),
                onPressed: _shareShort,
              ),
              const Text(
                "Share",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),

        // Title/Info Overlay
        Positioned(
          bottom: 40,
          left: 16,
          right: 80, // Leave space for share button
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.short['title'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
