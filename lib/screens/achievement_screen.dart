import 'package:cgks/api_service.dart';
import 'package:cgks/components/post_card.dart';
import 'package:flutter/material.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({Key? key}) : super(key: key);

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  late Future<List<dynamic>> _achievementFuture;
  late Future<List<dynamic>> _categoriesFuture;
  String? _selectedCategoryId;

  List<bool>? isLikedList;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ApiService().getAchievementCategories();
    _fetchAchievements();
  }

  void _fetchAchievements() {
    setState(() {
      if (_selectedCategoryId == null) {
        _achievementFuture = ApiService().getAllAchievements();
      } else {
        _achievementFuture = ApiService().getAchievementsByCategory(
          _selectedCategoryId!,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("उपलब्धि"), // Achievement in Hindi
        centerTitle: true,
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
                              _fetchAchievements();
                            }
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: Colors.green[100],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.green : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.green
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
                          _fetchAchievements();
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: Colors.green[100],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.green : Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.green
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
                future: _achievementFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("कोई उपलब्धि नहीं मिली।"));
                  }

                  final achievementList = snapshot.data!;
                  isLikedList ??= List<bool>.filled(
                    achievementList.length,
                    false,
                  );

                  return ListView.builder(
                    itemCount: achievementList.length,
                    itemBuilder: (context, index) {
                      return PostCard(
                        post: achievementList[index], // <-- THIS IS THE FIX
                        showActions: false,
                        isAchievement: true,
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
