import 'package:cgks/constants.dart';
import 'package:flutter/material.dart';
import '../api_service.dart';
import 'package:flutter_html/flutter_html.dart';

class AchievementDetailsScreen extends StatefulWidget {
  final String id;
  const AchievementDetailsScreen({super.key, required this.id});

  @override
  State<AchievementDetailsScreen> createState() =>
      _AchievementDetailsScreenState();
}

class _AchievementDetailsScreenState extends State<AchievementDetailsScreen> {
  late Future<Map<String, dynamic>> _achievementFuture;

  @override
  void initState() {
    super.initState();
    _achievementFuture = ApiService().getAchievementDetails(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("उपलब्धि विवरण")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _achievementFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("विवरण उपलब्ध नहीं है"));
          }

          final achievement = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (achievement['category'] != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.5)),
                    ),
                    child: Text(
                      achievement['category'] is Map
                          ? achievement['category']['name'] ?? ''
                          : achievement['category'].toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Text(
                  achievement['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (achievement['image_url'] != null &&
                    achievement['image_url'] != "null")
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      "${Constants.storageUrl}/${achievement['image_url']}",
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 8),
                // Caption if available, otherwise skip
                if (achievement['caption'] != null)
                  Text(
                    achievement['caption'] ?? '',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                const SizedBox(height: 12),
                Html(
                  data: achievement['content'] ?? 'कोई विवरण नहीं',
                  style: {
                    "body": Style(
                      fontSize: FontSize(16),
                      fontWeight: FontWeight.w500,
                    ),
                  },
                ),
                const SizedBox(height: 20),
                const Divider(),
                const Text(
                  "Comments",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _CommentsSection(
                  postId: int.parse(widget.id),
                  tableName: 'achievements',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CommentsSection extends StatefulWidget {
  final int postId;
  final String tableName;

  const _CommentsSection({required this.postId, required this.tableName});

  @override
  State<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      final comments = await ApiService().getComments(
        widget.postId,
        widget.tableName,
      );
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching comments: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final newComment = await ApiService().addComment(
        widget.postId,
        widget.tableName,
        _commentController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _comments.add(newComment); // Add to list locally
          _commentController.clear();
          _isSending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to add comment: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Comment List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _comments.length,
          itemBuilder: (context, index) {
            final comment = _comments[index];
            final user = comment['user'];
            final userName = user != null ? user['name'] : 'Unknown';
            final commentText = comment['comment_text'] ?? '';

            return ListTile(
              leading: CircleAvatar(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                ),
              ),
              title: Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(commentText),
            );
          },
        ),
        if (_comments.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("No comments yet. Be the first to comment!"),
          ),

        const SizedBox(height: 10),

        // Add Comment Input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: "Write a comment...",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isSending ? null : _addComment,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Colors.blue),
            ),
          ],
        ),
      ],
    );
  }
}
