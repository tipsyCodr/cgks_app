import 'package:cgks/constants.dart';
import 'package:cgks/components/curved_body.dart';
import 'package:flutter/material.dart';
import '../api_service.dart';
import 'package:intl/intl.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final String announcementId;
  const AnnouncementDetailScreen({Key? key, required this.announcementId})
    : super(key: key);

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  late Future<Map<String, dynamic>> _announcementFuture;

  @override
  void initState() {
    super.initState();
    _announcementFuture = ApiService().getAnnouncementById(
      widget.announcementId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.navBarColor,
      appBar: AppBar(
        title: const Text(
          'घोषणा विवरण',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Constants.navBarColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: CurvedBody(
        child: FutureBuilder<Map<String, dynamic>>(
        future: _announcementFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('त्रुटि: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('घोषणा नहीं मिली।'));
          }
          final ann = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    // height: 500,
                    decoration: BoxDecoration(
                      color: Colors.blue,
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
                  SizedBox(height: 20),
                  if (ann['category'] != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.withOpacity(0.5)),
                      ),
                      child: Text(
                        ann['category'] is Map
                            ? ann['category']['name'] ?? ''
                            : ann['category'].toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Text(
                    ann['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ann['created_at'] != null
                        ? DateFormat(
                            "dd MMM yyyy, hh:mm a",
                          ).format(DateTime.parse(ann['created_at']))
                        : '',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  if (ann['content'] != null)
                    Text(ann['content'], style: const TextStyle(fontSize: 15)),
                  // Add more fields as needed
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
}
