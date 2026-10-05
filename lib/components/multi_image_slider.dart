import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cgks/constants.dart';

List<String> extractImages(dynamic raw) {
  if (raw == null || raw == "null") return [];
  if (raw is List) {
    return raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty && e != "null")
        .toList();
  }
  if (raw is String) {
    final str = raw.trim();
    if (str.isEmpty || str == "null") return [];
    if (str.startsWith('[')) {
      try {
        final decoded = jsonDecode(str);
        if (decoded is List) {
          return decoded
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty && e != "null")
              .toList();
        }
      } catch (_) {}
    }
    return [str];
  }
  return [];
}

class MultiImageSlider extends StatefulWidget {
  final List<String> images;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  const MultiImageSlider({
    super.key,
    required this.images,
    this.height = 240,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.onTap,
  });

  @override
  State<MultiImageSlider> createState() => _MultiImageSliderState();
}

class _MultiImageSliderState extends State<MultiImageSlider> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();

    if (widget.images.length == 1) {
      return GestureDetector(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: Image.network(
            "${Constants.storageUrl}/${widget.images[0]}",
            width: double.infinity,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SizedBox(
            height: widget.height,
            width: double.infinity,
            child: PageView.builder(
              itemCount: widget.images.length,
              onPageChanged: (idx) => setState(() => _currentIndex = idx),
              itemBuilder: (context, idx) {
                return GestureDetector(
                  onTap: widget.onTap,
                  child: Image.network(
                    "${Constants.storageUrl}/${widget.images[idx]}",
                    width: double.infinity,
                    height: widget.height,
                    fit: widget.fit,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.white54),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Counter badge top-right
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xAA000000),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${_currentIndex + 1} / ${widget.images.length}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Indicator dots at bottom
          Positioned(
            bottom: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (idx) {
                final isSelected = _currentIndex == idx;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isSelected ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
