import 'package:cgks/constants.dart';
import 'package:flutter/material.dart';

class UserDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserDetailsScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(user["name"] ?? "User Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    user["profile_photo"] != null &&
                        user["profile_photo"].isNotEmpty
                    ? NetworkImage(
                        '${Constants.storageUrl}/${user["profile_photo"]}',
                      )
                    : null,
                child:
                    (user["profile_photo"] == null ||
                        user["profile_photo"].isEmpty)
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              user["name"] ?? "Unknown",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            _infoRow("पद स्तर", user["position"]),
            _infoRow("पद नाम", user["designation"]),
            _infoRow("जिला", user["district"]),
            _infoRow("मोबाइल", user["mobile"]),
            _infoRow("Email", user["email"]),

            const SizedBox(height: 20),
            const Divider(),

            const Text(
              "अधिक जानकारी",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Text(user["bio"] ?? "कोई विवरण उपलब्ध नहीं"),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value.toString())),
        ],
      ),
    );
  }
}
