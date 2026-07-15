import 'dart:typed_data';

import 'package:cgks/components/like_button.dart';
import 'package:cgks/constants.dart';
import 'package:cgks/screens/achievement_details.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
// import 'package:readmore/readmore.dart';
import 'package:share_plus/share_plus.dart';

// import '../api_service.dart';
import '../screens/news_detail_screen.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool showActions; // show Like + Comment + Share?
  final bool isAchievement; // if true, navigate differently

  const PostCard({
    super.key,
    required this.post,
    this.showActions = true,
    this.isAchievement = false,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final createdAt = widget.post['created_at'] != null
        ? DateFormat.yMMMd().format(DateTime.parse(widget.post['created_at']))
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// -------- HEADER ----------
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundImage: AssetImage("assets/images/logo.png"),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "छत्तीसगढ़ क्रांति सेना",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            createdAt,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (widget.post['category'] != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.5),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                widget.post['category'] is Map
                                    ? widget.post['category']['name'] ?? ''
                                    : widget.post['category'].toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'download') {
                      if (widget.post['image_url'] != null) {
                        _downloadImage(widget.post['image_url'], context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("No image to download")),
                        );
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      const PopupMenuItem<String>(
                        value: 'download',
                        child: Row(
                          children: [
                            Icon(Icons.download, color: Colors.black),
                            SizedBox(width: 8),
                            Text('Download Image'),
                          ],
                        ),
                      ),
                    ];
                  },
                  icon: const Icon(CupertinoIcons.ellipsis_vertical),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          /// -------- CONTENT TEXT ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GestureDetector(
              onTap: () => setState(() => expanded = !expanded),
              child: expanded
                  ? Html(data: widget.post['content'] ?? widget.post['title'])
                  : Text(
                      _stripHtml(
                        widget.post['content'] ?? widget.post['title'],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 10),

          /// -------- IMAGE ----------
          if (widget.post['image_url'] != null &&
              widget.post['image_url'] != "null")
            GestureDetector(
              onTap: () {
                if (!widget.isAchievement) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NewsDetailScreen(
                        newsId: widget.post['id'].toString(),
                      ),
                    ),
                  );
                } else if (widget.isAchievement) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AchievementDetailsScreen(
                        id: widget.post['id'].toString(),
                      ),
                    ),
                  );
                }
              },
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    "${Constants.storageUrl}/${widget.post['image_url']}",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 10),

          /// -------- ACTION ROW ----------
          if (widget.showActions)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  LikeButtonWidget(
                    postId: widget.post['id'],
                    tableName: 'news',
                  ),

                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NewsDetailScreen(
                            newsId: widget.post['id'].toString(),
                          ),
                        ),
                      );
                    },
                    child: const Row(
                      children: [
                        Icon(CupertinoIcons.chat_bubble_text, size: 20),
                        SizedBox(width: 6),
                        Text("Comment"),
                      ],
                    ),
                  ),

                  InkWell(
                    onTap: _sharePost,
                    child: const Row(
                      children: [
                        Icon(CupertinoIcons.share, size: 20),
                        SizedBox(width: 6),
                        Text("Share"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  void _sharePost() {
    String shareText =
        "${widget.post['title']}\n\n${widget.post['content'] ?? ''}";
    if (widget.post['image_url'] != null) {
      shareText += "\n\n${Constants.storageUrl}/${widget.post['image_url']}";
    }
    Share.share(shareText);
  }

  Future<void> _downloadImage(String imageUrl, context) async {
    try {
      // Check for access permission
      bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        hasAccess = await Gal.requestAccess();
      }

      if (hasAccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Downloading image...")));

        var response = await Dio().get(
          "${Constants.storageUrl}/$imageUrl",
          options: Options(responseType: ResponseType.bytes),
        );

        await Gal.putImageBytes(
          Uint8List.fromList(response.data),
          name: "news_${DateTime.now().millisecondsSinceEpoch}",
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image saved to gallery!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permission denied to save image.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error downloading image: $e")));
    }
  }
}
