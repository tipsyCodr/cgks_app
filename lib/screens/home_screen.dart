import 'dart:convert';

// import 'package:cgks/bottom_navigation.dart';
import 'package:cgks/components/shorts_carousel.dart';
import 'package:cgks/components/app_banner_carousel.dart';
import 'package:cgks/components/announcement_card.dart';
import 'package:cgks/features/auth/login_page.dart';
import 'package:cgks/features/profile/profile_screen.dart';
import 'package:cgks/screens/anouncements_screen.dart';
import 'package:cgks/screens/live_video_screen.dart';
import 'package:cgks/screens/news_screen.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cgks/api_service.dart';
import 'package:cgks/screens/announcement_detail_screen.dart';
import 'package:cgks/screens/news_detail_screen.dart';
import 'package:cgks/constants.dart';
import 'package:cgks/models/contact_details.dart';
import 'package:cgks/components/curved_body.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? user;

  final String userName = "प्रमोद साहू";

  final String pad = "सदस्य";

  final String userMobile = "+91 9876543210";

  final Map<String, String> rtoCodes = {
    "रायपुर": "04",
    "धमतरी": "05",
    "महासमुन्द": "06",
    "दुर्ग": "07",
    "राजनांदगांव": "08",
    "कवर्धा": "09",
    "बिलासपुर": "10",
    "जांजगीर-चाम्पा": "11",
    "कोरबा": "12",
    "रायगढ़": "13",
    "जशपुर": "14",
    "सरगुजा": "15",
    "कोरिया": "16",
    "जगदलपुर": "17",
    "दंतेवाड़ा": "18",
    "कांकेर": "19",
    "बीजापुर": "20",
    "नारायणपुर": "21",
    "बलौदाबाजार": "22",
    "गरियाबंद": "23",
    "बालोद": "24",
    "बेमेतरा": "25",
    "सुकमा": "26",
    "कोंडागाँव": "27",
    "मुंगेली": "28",
    "सूरजपुर": "29",
    "बलरामपुर": "30",
  };

  final List<String> announcements = [
    "assets/images/banner.jpg",
    "नई घोषणा 🚀",
    "सर्वर बंद है ",
    "मेम्बर के लिए स्पेशल ऑफर्स ",
  ];

  final List<String> advertisements = [
    "बैनर विज्ञापन 1",
    "बैनर विज्ञापन 2",
    "बैनर विज्ञापन 3",
    "बैनर विज्ञापन 4",
  ];

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString("user");

    if (userString != null) {
      return jsonDecode(userString); // returns Map<String, dynamic>
    }
    return null;
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString("user");
    if (userString != null) {
      setState(() {
        user = jsonDecode(userString);
      });
    }
  }

  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _news = [];
  bool _isLoadingCarousel = true;
  Future<ContactDetails>? _contactDetailsFuture;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _fetchCarouselData();
    _loadUserData();
    _contactDetailsFuture = ApiService().fetchContactDetails();
  }

  Future<void> _fetchCarouselData() async {
    try {
      final api = ApiService();
      final announcementsFuture = api.getAllAnnouncements();
      final newsFuture = api.getAllNews();

      final results = await Future.wait([announcementsFuture, newsFuture]);
      final announcementsData = results[0];
      final newsData = results[1];

      List<Map<String, dynamic>> tempAnnouncements = [];
      List<Map<String, dynamic>> tempNews = [];

      // Process Announcements
      for (var item in announcementsData) {
        tempAnnouncements.add({
          'type': 'announcement',
          'id': item['id'].toString(),
          'title': item['title'] ?? 'No Title',
          'image': item['image_url'] is List && (item['image_url'] as List).isNotEmpty
              ? (item['image_url'] as List).first
              : item['image_url'],
          'created_at': item['created_at'],
          'published_date': item['published_date'],
          'category_name': item['category_name'] ??
              (item['category'] is Map ? item['category']['name'] : null) ??
              'Uncategorized',
          'data': item,
        });
      }

      // Process News
      for (var item in newsData) {
        tempNews.add({
          'type': 'news',
          'id': item['id'].toString(),
          'title': item['title'] ?? 'No Title',
          'image': item['image_url'] is List && (item['image_url'] as List).isNotEmpty
              ? (item['image_url'] as List).first
              : item['image_url'],
          'created_at': item['created_at'],
          'data': item,
        });
      }

      // Sort by created_at descending
      int sortFunction(Map<String, dynamic> a, Map<String, dynamic> b) {
        DateTime? dateA = a['created_at'] != null
            ? DateTime.tryParse(a['created_at'])
            : null;
        DateTime? dateB = b['created_at'] != null
            ? DateTime.tryParse(b['created_at'])
            : null;
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      }

      tempAnnouncements.sort(sortFunction);
      tempNews.sort(sortFunction);

      // Take top 10
      if (tempAnnouncements.length > 10) {
        tempAnnouncements = tempAnnouncements.sublist(0, 10);
      }
      if (tempNews.length > 10) {
        tempNews = tempNews.sublist(0, 10);
      }

      if (mounted) {
        setState(() {
          _announcements = tempAnnouncements;
          _news = tempNews;
          _isLoadingCarousel = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching carousel data: $e");
      if (mounted) {
        setState(() {
          _isLoadingCarousel = false;
        });
      }
    }
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.navBarColor,
      appBar: AppBar(
        backgroundColor: Constants.navBarColor,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 72,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(8),
          child: SizedBox(height: 8),
        ),
        titleSpacing: 14,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 42,
              width: 42,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "छत्तीसगढ़ क्रांति सेना",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    "हमर समाज  •  हमर अधिकार  •  हमर छत्तीसगढ़",
                    style: TextStyle(
                      fontSize: 9.5,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.live_tv, color: Colors.white, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LiveVideoScreen()),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          FutureBuilder<Map<String, dynamic>?>(
            future: getUserData(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              final profilePhoto = user != null && user['profile_photo'] != null
                  ? "${Constants.storageUrl}/${user['profile_photo']}"
                  : null;

              return GestureDetector(
                onTap: () {
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  );
                },
                child: CircleAvatar(
                  radius: 19,
                  backgroundColor: Colors.white24,
                  child: ClipOval(
                    child: profilePhoto != null
                        ? Image.network(
                            profilePhoto,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.person,
                              color: Colors.white70,
                              size: 22,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Colors.white70,
                            size: 22,
                          ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: CurvedBody(
        backgroundColor: Colors.grey[50]!,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const AppBannerCarousel(),
            const SizedBox(height: 14),

            // Action Buttons: Visit Website & Share Referral (Side by Side)
            Row(
              children: [
                // 1. Visit Website Button
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF8B121A),
                          Color(0xFFB71C1C),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B121A).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final uri = Uri.parse(Constants.baseUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 14.0,
                            horizontal: 8.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.language_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Visit Website',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // 2. Share Referral Link Button
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1565C0),
                          Color(0xFF42A5F5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (user == null) {
                            Fluttertoast.showToast(
                              msg: "Please wait, content loading...",
                            );
                            return;
                          }
                          final referralCode = user!['referral_code'] ?? '';
                          if (referralCode.isEmpty) {
                            Fluttertoast.showToast(msg: "Referral code not found");
                            return;
                          }
                          final link =
                              "${Constants.baseUrl}/register?ref=$referralCode";
                          Share.share(
                            "Join CGKS App using my referral code: $referralCode\n\nLink: $link",
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 14.0,
                            horizontal: 8.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.share_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Share Referral',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),
            const ShortsCarousel(),

            const SizedBox(height: 24),
            if (_isLoadingCarousel)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Announcements Section
              if (_announcements.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.campaign,
                          color: Color(0xFFE53935),
                          size: 26,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "घोषणा",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AnouncementsScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 2,
                        ),
                        child: Row(
                          children: const [
                            Text(
                              "सभी देखें",
                              style: TextStyle(
                                color: Color(0xFFE53935),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right,
                              color: Color(0xFFE53935),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount:
                      _announcements.length > 3 ? 3 : _announcements.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _announcements[index];
                    return AnnouncementCard(
                      announcement: item,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AnnouncementDetailScreen(
                              announcementId: item['id'].toString(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],

              // News Section
              if (_news.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "समाचार",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => NewsScreen()),
                        );
                      },
                      child: const Text(
                        "See All",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _news.length,
                    itemBuilder: (context, index) {
                      final item = _news[index];
                      final imageUrl = item['image'];
                      final title = item['title'];

                      bool hasImage =
                          imageUrl != null &&
                          imageUrl.toString().isNotEmpty &&
                          imageUrl.toString() != "null";

                      return Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: hasImage
                              ? Colors.transparent
                              : Colors
                                    .primaries[index % Colors.primaries.length]
                                    .shade400,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    NewsDetailScreen(newsId: item['id']),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: hasImage
                                ? Image.network(
                                    "${Constants.storageUrl}/$imageUrl",
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          height: 1.4,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              if (_announcements.isEmpty && _news.isEmpty)
                const Center(child: Text("कोई घोषणा या समाचार उपलब्ध नहीं है")),
            ],

            const SizedBox(height: 24),

            // Contact Details Section
            FutureBuilder<ContactDetails>(
              future: _contactDetailsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  debugPrint("Contact Details Error: ${snapshot.error}");
                  return Center(
                    child: Text(
                      "Error loading contact details: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (!snapshot.hasData) {
                  return const Center(child: Text("No contact details found"));
                }

                final contact = snapshot.data!;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "संपर्क विवरण",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (contact.address != null) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                contact.address!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (contact.mobile != null) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              contact.mobile!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (contact.email != null) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.email,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              contact.email!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (contact.qrCode != null)
                        Center(
                          child: Image.network(
                            "${Constants.storageUrl}/${contact.qrCode}",
                            height: 600,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: 100),

            GestureDetector(
              onTap: () {
                launchUrl(Uri.parse("https://pathideamultiskill.com"));
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Developed By ",
                    style: TextStyle(color: Color.fromARGB(255, 100, 98, 98)),
                  ),
                  Image.asset(
                    "assets/images/path_logo.png",
                    height: 50,
                    width: 100,
                  ),
                ],
              ),
            ),
            SizedBox(height: 100),
            //this is las padding add widget before this.
          ],
        ),
      ),
    ),
  );
}
}
