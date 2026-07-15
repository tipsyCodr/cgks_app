import 'dart:convert';
import 'dart:io';
import 'package:cgks/api_service.dart';
import 'package:cgks/features/auth/login_page.dart';
import 'package:cgks/features/profile/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:share_plus/share_plus.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  File? _image;
  bool isUploading = false;
  final String baseUrl = "https://cgks.pathideamultiskill.com/api";

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Photo',
            toolbarColor: Colors.red,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Crop Profile Photo'),
        ],
      );

      if (croppedFile != null) {
        setState(() => _image = File(croppedFile.path));
        await uploadProfilePhoto(_image!);
      }
    }
  }

  Future<void> uploadProfilePhoto(File imageFile) async {
    setState(() => isUploading = true);
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/update-profile-photo"),
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token != null) {
        request.headers['Accept'] = 'application/json';
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        await http.MultipartFile.fromPath('profile_photo', imageFile.path),
      );
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      final decoded = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        prefs.setString("profile_photo", decoded['user']['profile_photo']);
        Fluttertoast.showToast(msg: "Profile updated!");
        setState(() => user = decoded['user']);
        prefs.setString("user", jsonEncode(decoded['user']));
      } else {
        Fluttertoast.showToast(msg: decoded['error'] ?? "Upload failed");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Upload failed: $e");
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  Widget _buildDetailRow(String title, String? value) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value ?? "N/A"),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profilePhoto = user!['profile_photo'] != null
        ? "https://cgks.pathideamultiskill.com/storage/${user!['profile_photo']}"
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text("Profile Details"), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : (profilePhoto != null ? NetworkImage(profilePhoto) : null)
                          as ImageProvider?,
                child: (_image == null && profilePhoto == null)
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user!['name'] ?? '',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user!['mobile'] ?? '',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                FilledButton(
                  onPressed: () async {
                    final updatedUser = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(user: user!),
                      ),
                    );
                    if (updatedUser != null) setState(() => user = updatedUser);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [const Icon(Icons.edit), Text('Edit Profile')],
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () {
                    final referralCode = user!['referral_code'] ?? '';
                    if (referralCode.isEmpty) {
                      Fluttertoast.showToast(msg: "Referral code not found");
                      return;
                    }
                    final link =
                        "https://cgks.pathideamultiskill.com/register?ref=$referralCode";
                    Share.share(
                      "Join CGKS App using my referral code: $referralCode\n\nLink: $link",
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [const Icon(Icons.share), Text('Share Link')],
                  ),
                ),
              ],
            ),
            if (isUploading) const LinearProgressIndicator(),
            const Divider(),
            _buildDetailRow("Booth", user!['booth']),
            _buildDetailRow("Paar", user!['paar']),
            _buildDetailRow("Gudi", user!['gudi']),
            _buildDetailRow("Khad", user!['khad']),
            _buildDetailRow("Occupation", user!['occupation']),
            _buildDetailRow("Email", user!['email']),
            _buildDetailRow("Address", user!['address']),
            _buildDetailRow("Current Address", user!['current_address']),
            _buildDetailRow("WhatsApp", user!['whatsapp']),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Logout",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                ApiService().logoutUser();
                Fluttertoast.showToast(msg: "Logout Successfully!");
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
