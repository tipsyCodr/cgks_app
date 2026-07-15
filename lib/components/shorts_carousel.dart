import 'package:cgks/api_service.dart';
import 'package:cgks/screens/shorts_player_screen.dart';
import 'package:flutter/material.dart';

class ShortsCarousel extends StatefulWidget {
  const ShortsCarousel({super.key});

  @override
  State<ShortsCarousel> createState() => _ShortsCarouselState();
}

class _ShortsCarouselState extends State<ShortsCarousel> {
  late Future<List<Map<String, dynamic>>> _shortsFuture;

  @override
  void initState() {
    super.initState();
    _shortsFuture = ApiService().getShorts();
  }

  /// Extract YouTube video ID and return thumbnail
  String? getYoutubeThumbnail(String url) {
    try {
      Uri uri = Uri.parse(url);

      // Case 1: https://youtube.com/watch?v=ID
      if (uri.queryParameters.containsKey('v')) {
        final id = uri.queryParameters['v'];
        return "https://img.youtube.com/vi/$id/hqdefault.jpg";
      }

      // Case 2: https://youtu.be/ID
      if (uri.host.contains("youtu.be")) {
        final id = uri.pathSegments.first;
        return "https://img.youtube.com/vi/$id/hqdefault.jpg";
      }

      // Case 3: https://youtube.com/shorts/ID
      if (uri.pathSegments.contains('shorts')) {
        final index = uri.pathSegments.indexOf('shorts');
        if (index + 1 < uri.pathSegments.length) {
          final id = uri.pathSegments[index + 1];
          return "https://img.youtube.com/vi/$id/hqdefault.jpg";
        }
      }

      // Case 4: https://youtube.com/embed/ID
      if (uri.pathSegments.contains('embed')) {
        final index = uri.pathSegments.indexOf('embed');
        if (index + 1 < uri.pathSegments.length) {
          final id = uri.pathSegments[index + 1];
          return "https://img.youtube.com/vi/$id/hqdefault.jpg";
        }
      }
    } catch (_) {}

    return null;
  }

  /// Return final thumbnail depending on video type
  String? getThumbnail(Map<String, dynamic> short) {
    var type = short["type"]?.toString().toLowerCase();
    final url = short["url"] ?? short["video_url"];

    if (url == null) return null;

    // Auto-detect YouTube if type is missing or URL looks like YouTube
    if (type == null || url.toString().contains('youtu')) {
      type = 'youtube';
    }

    if (type == "youtube") {
      return getYoutubeThumbnail(url);
    }

    // Instagram = No API thumbnails → return placeholder
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _shortsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final shorts = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Padding(
            //   padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            //   child: Text(
            //     "Shorts & Reels",
            //     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            //   ),
            // ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: shorts.length,
                padding: const EdgeInsets.symmetric(horizontal: 1),
                itemBuilder: (context, index) {
                  final short = shorts[index];
                  final title = short['title'] ?? "Short";
                  final url = short['url'] ?? short['video_url'];
                  var type = short['type']?.toString().toLowerCase();

                  if (type == null &&
                      url != null &&
                      url.toString().contains('youtu')) {
                    type = 'youtube';
                  }
                  type ??= 'youtube';

                  final thumbnail = getThumbnail(short); // <-- auto thumb

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShortsPlayerScreen(
                            shorts: shorts,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        image: thumbnail != null
                            ? DecorationImage(
                                image: NetworkImage(thumbnail),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: Stack(
                        children: [
                          // Fallback if no thumbnail (Instagram or invalid)
                          if (thumbnail == null)
                            const Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),

                          // Type Icon (YouTube / Instagram)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(
                              type == 'youtube'
                                  ? Icons.play_circle_fill
                                  : Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),

                          // Title Overlay
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.8),
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
