import 'package:flutter/material.dart';
import '../api_service.dart';

class LikeButtonWidget extends StatefulWidget {
  final int postId;
  final String tableName;

  const LikeButtonWidget({
    super.key,
    required this.postId,
    required this.tableName,
  });

  @override
  State<LikeButtonWidget> createState() => _LikeButtonWidgetState();
}

class _LikeButtonWidgetState extends State<LikeButtonWidget> {
  bool isLiked = false;
  int likeCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLikeStatus();
  }

  Future<void> _fetchLikeStatus() async {
    try {
      final data = await ApiService().getLikeStatus(
        widget.postId,
        widget.tableName,
      );
      if (mounted) {
        setState(() {
          isLiked = data['liked'] ?? false;
          likeCount = data['count'] ?? 0;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _toggleLike() async {
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });

    try {
      final data = await ApiService().toggleLike(
        widget.postId,
        widget.tableName,
      );

      if (mounted) {
        setState(() {
          isLiked = data['liked'] ?? isLiked;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLiked = !isLiked;
          likeCount += isLiked ? 1 : -1;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to update like: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 60,
        height: 20,
        child: Center(
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return InkWell(
      onTap: _toggleLike,
      child: Row(
        children: [
          Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : Colors.grey.shade700,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            "$likeCount ${isLiked ? "Unlike" : "Like"}",
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
