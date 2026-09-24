import 'package:cgks/constants.dart';
import 'package:cgks/components/curved_body.dart';
import 'package:cgks/components/announcement_card.dart';
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
      backgroundColor: Constants.navBarColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Constants.navBarColor,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "घोषणा",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18),
        ),
      ),
      body: CurvedBody(
        child: Column(
          children: [
            const SizedBox(height: 8),
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
                          label: const Text("सभी"),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategoryId = null;
                              });
                              _fetchAnnouncements();
                            }
                          },
                          backgroundColor: const Color(0xFFF1F3F5),
                          selectedColor: Constants.accentColor,
                          showCheckmark: false,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide.none,
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
                        backgroundColor: const Color(0xFFF1F3F5),
                        selectedColor: Constants.accentColor,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide.none,
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
                  return ListView.separated(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    itemCount: announcements.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final ann = Map<String, dynamic>.from(announcements[index]);
                      return AnnouncementCard(
                        announcement: ann,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnnouncementDetailScreen(
                                announcementId: ann['id'].toString(),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
