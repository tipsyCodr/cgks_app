import 'package:cgks/constants.dart';
import 'package:flutter/material.dart';
import '../api_service.dart';
import 'announcement_detail_screen.dart';

class AnouncementsScreen extends StatefulWidget {
  const AnouncementsScreen({Key? key}) : super(key: key);

  @override
  State<AnouncementsScreen> createState() => _AnouncementsScreenState();
}

class _AnouncementsScreenState extends State<AnouncementsScreen> {
  late Future<List<dynamic>> _announcementsFuture;
  late Future<List<dynamic>> _categoriesFuture;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ApiService().getAnnouncementCategories();
    _fetchAnnouncements();
  }

  void _fetchAnnouncements() {
    setState(() {
      if (_selectedCategoryId == null) {
        _announcementsFuture = ApiService().getAllAnnouncements();
      } else {
        _announcementsFuture = ApiService().getAnnouncementsByCategory(
          _selectedCategoryId!,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        centerTitle: true,
        title: const Text(
          "घोषणा",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          // Categories List
          FutureBuilder<List<dynamic>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              final categories = snapshot.data!;
              return Container(
                height: 50,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedCategoryId == null;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text("All"),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategoryId = null;
                              });
                              _fetchAnnouncements();
                            }
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: Colors.blue[100],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.blue : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      );
                    }
                    final category = categories[index - 1];
                    final isSelected =
                        _selectedCategoryId == category['id'].toString();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category['name'] ?? ''),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoryId = selected
                                ? category['id'].toString()
                                : null;
                          });
                          _fetchAnnouncements();
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: Colors.blue[100],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.blue : Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.blue
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: FutureBuilder<List<dynamic>>(
                future: _announcementsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('त्रुटि: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('कोई घोषणा नहीं मिली।'));
                  }
                  final announcements = snapshot.data!;
                  return ListView.builder(
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      final ann = announcements[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors
                                    .primaries[index % Colors.primaries.length]
                                    .shade300,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                              child:
                                  ann['image_url'] != null &&
                                      ann['image_url'].toString().isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                      child: Image.network(
                                        "${Constants.storageUrl}/${ann['image_url']}",
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Center(
                                      child: Text(
                                        "चित्र",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AnnouncementDetailScreen(
                                            announcementId: ann['id']
                                                .toString(),
                                          ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      if (ann['category'] != null)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.blue.withOpacity(
                                                0.5,
                                              ),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            ann['category'] is Map
                                                ? ann['category']['name'] ?? ''
                                                : ann['category'].toString(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.blue[700],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        ann['title'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        ann['content'] ?? '',
                                        maxLines: 3,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
