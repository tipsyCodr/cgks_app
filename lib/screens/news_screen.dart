import 'package:cgks/components/pinned_live_video.dart';
import 'package:cgks/components/post_card.dart';

import 'package:flutter/material.dart';
import '../api_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<dynamic>> _newsFuture;
  late Future<List<dynamic>> _categoriesFuture;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ApiService().getNewsCategories();
    _fetchNews();
  }

  void _fetchNews() {
    setState(() {
      if (_selectedCategoryId == null) {
        _newsFuture = ApiService().getAllNews();
      } else {
        _newsFuture = ApiService().getNewsByCategory(_selectedCategoryId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        centerTitle: true,
        title: const Text(
          "समाचार",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          // Categories List
          FutureBuilder<List<dynamic>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 50,
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return SizedBox(
                  height: 50,
                  child: Center(child: Text("Error: ${snapshot.error}")),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox(
                  height: 50,
                  child: Center(child: Text("No categories found")),
                );
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
                              _fetchNews();
                            }
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: Colors.red[100],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.red : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.red
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
                          _fetchNews();
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: Colors.red[100],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.red : Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? Colors.red : Colors.transparent,
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
                future: _newsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("कोई समाचार नहीं मिला।"));
                  }

                  final newsList = snapshot.data!;

                  return ListView.builder(
                    itemCount: newsList.length + 1, // +1 for PinnedLiveVideo
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const PinnedLiveVideo();
                      }
                      final newsIndex = index - 1;
                      return PostCard(
                        post: newsList[newsIndex],
                        showActions: true,
                        isAchievement: false,
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
