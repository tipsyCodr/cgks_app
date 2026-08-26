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
import 'package:qr_flutter/qr_flutter.dart';

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

  void _showReferralQrCode() {
    final referralCode = user!['referral_code'] ?? '';
    if (referralCode.isEmpty) {
      Fluttertoast.showToast(msg: "Referral code not found");
      return;
    }
    final link = "https://cgks.pathideamultiskill.com/register?ref=$referralCode";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "मेरा रेफरल क्यूआर कोड",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                user!['name'] ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: link,
                  version: QrVersions.auto,
                  size: 200.0,
                  embeddedImage: const AssetImage('assets/images/logo.png'),
                  embeddedImageStyle: const QrEmbeddedImageStyle(
                    size: Size(36, 36),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "कोड: $referralCode",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Share.share(
                    "Join CGKS App using my referral code: $referralCode\n\nLink: $link",
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text("शेयर करें"),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
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
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
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
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Profile'),
                ),
                FilledButton.icon(
                  onPressed: _showReferralQrCode,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code, size: 18),
                  label: const Text('QR Code'),
                ),
                FilledButton.icon(
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
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share Link'),
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
