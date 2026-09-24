import 'package:flutter/material.dart';
import '../api_service.dart';
import '../components/announcement_card.dart';
import 'announcement_detail_screen.dart';

class AllAnnouncementsScreen extends StatefulWidget {
  const AllAnnouncementsScreen({Key? key}) : super(key: key);

  @override
  State<AllAnnouncementsScreen> createState() => _AllAnnouncementsScreenState();
}

class _AllAnnouncementsScreenState extends State<AllAnnouncementsScreen> {
  late Future<List<dynamic>> _announcementsFuture;

  @override
  void initState() {
    super.initState();
    _announcementsFuture = ApiService().getAllAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('सभी घोषणाएँ'), centerTitle: true),
      body: FutureBuilder<List<dynamic>>(
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
            padding: const EdgeInsets.all(16),
            itemCount: announcements.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
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
    );
  }
}
