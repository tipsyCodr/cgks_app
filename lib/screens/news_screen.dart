import 'package:cgks/components/pinned_live_video.dart';
import 'package:cgks/components/post_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  DateTime? _selectedDate;

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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      helpText: "समाचार दिनांक चुनें",
      cancelText: "रद्द करें",
      confirmText: "चुनें",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return "आज (${DateFormat('dd MMM yyyy').format(date)})";
    } else if (itemDate == yesterday) {
      return "कल (${DateFormat('dd MMM yyyy').format(date)})";
    } else {
      return DateFormat('dd MMMM yyyy').format(date);
    }
  }

  DateTime? _parseItemDate(dynamic item) {
    final dateStr = item['published_date'] ?? item['created_at'];
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_month,
              color: _selectedDate != null ? Colors.red : Colors.black87,
            ),
            tooltip: "तारीख से खोजें",
            onPressed: _pickDate,
          ),
        ],
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

          // Active Date Filter Badge
          if (_selectedDate != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  Chip(
                    avatar: const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.red,
                    ),
                    label: Text(
                      "तारीख: ${DateFormat('dd MMM yyyy').format(_selectedDate!)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    deleteIconColor: Colors.red,
                    onDeleted: () {
                      setState(() {
                        _selectedDate = null;
                      });
                    },
                    backgroundColor: Colors.red[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
              ),
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

                  List<dynamic> newsList = List.from(snapshot.data!);

                  // Sort news by date descending
                  newsList.sort((a, b) {
                    final dateA = _parseItemDate(a) ?? DateTime(1970);
                    final dateB = _parseItemDate(b) ?? DateTime(1970);
                    return dateB.compareTo(dateA);
                  });

                  // Filter by selected date if active
                  if (_selectedDate != null) {
                    newsList = newsList.where((item) {
                      final date = _parseItemDate(item);
                      if (date == null) return false;
                      return date.year == _selectedDate!.year &&
                          date.month == _selectedDate!.month &&
                          date.day == _selectedDate!.day;
                    }).toList();
                  }

                  if (newsList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.event_busy,
                            size: 60,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedDate != null
                                ? "${DateFormat('dd MMM yyyy').format(_selectedDate!)} को कोई समाचार नहीं मिला।"
                                : "कोई समाचार नहीं मिला।",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          if (_selectedDate != null)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedDate = null;
                                });
                              },
                              child: const Text("सभी तारीखें देखें"),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: newsList.length + 1, // +1 for PinnedLiveVideo
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const PinnedLiveVideo();
                      }
                      final newsIndex = index - 1;
                      final post = newsList[newsIndex];
                      final currentDate = _parseItemDate(post);

                      // Determine if we need a date section header
                      bool showDateHeader = false;
                      if (currentDate != null && _selectedDate == null) {
                        if (newsIndex == 0) {
                          showDateHeader = true;
                        } else {
                          final prevDate =
                              _parseItemDate(newsList[newsIndex - 1]);
                          if (prevDate != null) {
                            showDateHeader =
                                prevDate.year != currentDate.year ||
                                prevDate.month != currentDate.month ||
                                prevDate.day != currentDate.day;
                          }
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDateHeader && currentDate != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 12.0,
                                bottom: 8.0,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: Colors.black54,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatDateHeader(currentDate),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Expanded(
                                    child: Divider(
                                      indent: 10,
                                      color: Colors.black12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          PostCard(
                            post: post,
                            showActions: true,
                            isAchievement: false,
                          ),
                        ],
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
