import 'package:cgks/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class LiveVideoScreen extends StatefulWidget {
  const LiveVideoScreen({super.key});

  @override
  State<LiveVideoScreen> createState() => _LiveVideoScreenState();
}

class _LiveVideoScreenState extends State<LiveVideoScreen> {
  late Future<List<Map<String, dynamic>>> _videosFuture;
  YoutubePlayerController? _controller;
  Map<String, dynamic>? _currentVideo;

  @override
  void initState() {
    super.initState();
    _videosFuture = ApiService().getLiveVideos();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _initializePlayer(String videoId) {
    // If controller exists, load new video
    if (_controller != null) {
      _controller!.load(videoId);
      return;
    }

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        isLive: true,
      ),
    );
  }

  void _playVideo(Map<String, dynamic> video) {
    setState(() {
      _currentVideo = video;
    });
    _initializePlayer(video['video_id']);
  }

  @override
  Widget build(BuildContext context) {
    // If we have a controller, we use YoutubePlayerBuilder to handle full screen
    // correctly. It wraps the Scaffold.
    if (_controller != null) {
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _controller!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.red,
          onReady: () {
            // _controller.addListener(listener);
          },
        ),
        builder: (context, player) {
          return Scaffold(
            appBar: AppBar(title: const Text("Live Video"), centerTitle: true),
            body: Column(
              children: [
                player,
                const SizedBox(height: 10),
                if (_currentVideo != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _currentVideo!['title'] ?? "Live Stream",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const Divider(),
                Expanded(child: _buildVideoList()),
              ],
            ),
          );
        },
      );
    }

    // Initial state: Fetching videos or showing list to select
    return Scaffold(
      appBar: AppBar(title: const Text("Live Video"), centerTitle: true),
      body: _buildVideoList(),
    );
  }

  Widget _buildVideoList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _videosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "No live videos currently available.",
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        final videos = snapshot.data!;

        // If no video is playing yet, automatically play the first one
        if (_controller == null && _currentVideo == null) {
          // We need to schedule this to avoid state change during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _playVideo(videos.first);
          });
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            final isSelected =
                _currentVideo != null &&
                _currentVideo!['video_id'] == video['video_id'];

            return ListTile(
              leading: const Icon(Icons.play_circle_fill, color: Colors.red),
              title: Text(video['title'] ?? "Live Stream ${index + 1}"),
              subtitle: Text(
                isSelected
                    ? "Playing Now"
                    : (video['created_at'] ?? "Tap to play"),
              ),
              tileColor: isSelected ? Colors.red.withOpacity(0.1) : null,
              onTap: () => _playVideo(video),
            );
          },
        );
      },
    );
  }
}
