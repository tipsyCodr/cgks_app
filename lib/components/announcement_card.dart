import 'package:flutter/material.dart';
import '../constants.dart';

class AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> announcement;
  final VoidCallback? onTap;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.onTap,
  });

  static const Map<int, String> _hindiMonths = {
    1: 'जनवरी',
    2: 'फरवरी',
    3: 'मार्च',
    4: 'अप्रैल',
    5: 'मई',
    6: 'जून',
    7: 'जुलाई',
    8: 'अगस्त',
    9: 'सितंबर',
    10: 'अक्टूबर',
    11: 'नवंबर',
    12: 'दिसंबर',
  };

  static String formatHindiDate(dynamic rawDate) {
    if (rawDate == null) return '';
    final str = rawDate.toString().trim();
    if (str.isEmpty) return '';
    try {
      final dt = DateTime.parse(str);
      final day = dt.day.toString().padLeft(2, '0');
      final month = _hindiMonths[dt.month] ?? '';
      final year = dt.year.toString();
      return '$day $month $year';
    } catch (_) {
      return str;
    }
  }

  String? _resolveImageUrl() {
    final raw = announcement['image_url'] ?? announcement['image'];
    if (raw == null) return null;
    final str = raw.toString().trim();
    if (str.isEmpty) return null;
    if (str.startsWith('http://') || str.startsWith('https://')) {
      return str;
    }
    return '${Constants.storageUrl}/$str';
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(
          Icons.campaign_outlined,
          color: Constants.accentColor.withOpacity(0.7),
          size: 30,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = (announcement['title'] ?? '').toString();
    final dateRaw = announcement['published_date'] ?? announcement['created_at'];
    final formattedDate = formatHindiDate(dateRaw);
    final imageUrl = _resolveImageUrl();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left thumbnail image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          width: 74,
                          height: 74,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildThumbnailPlaceholder(),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              width: 74,
                              height: 74,
                              color: const Color(0xFFF8FAFC),
                              child: const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : _buildThumbnailPlaceholder(),
                ),
                const SizedBox(width: 12),
                // Middle text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          height: 1.25,
                        ),
                      ),
                      if (formattedDate.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          formattedDate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Right chevron icon
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF64748B),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
