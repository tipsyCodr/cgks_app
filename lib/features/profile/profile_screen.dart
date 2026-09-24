import 'dart:convert';
import 'dart:io';
import 'package:cgks/api_service.dart';
import 'package:cgks/constants.dart';
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
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  File? _image;
  bool isUploading = false;
  final String baseUrl = Constants.apiUrl;

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
    final link = "${Constants.baseUrl}/register?ref=$referralCode";

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

  bool _isProfileIncomplete() {
    if (user == null) return false;
    final father = user!['father_name']?.toString() ?? '';
    final adhar = user!['adhar_no']?.toString() ?? '';
    final curAddr = user!['current_address']?.toString() ?? '';
    return father.isEmpty || adhar.isEmpty || curAddr.isEmpty;
  }

  Widget _buildMemberIdCard(String? profilePhoto) {
    final name = user!['name'] ?? '';
    final name2 = user!['name2']?.toString().trim() ?? '';
    final mobile = user!['mobile'] ?? '-';
    final district = user!['district']?.toString().trim() ?? '';
    final tahasil = user!['tahasil']?.toString().trim() ?? '';
    final vidhansabha = user!['vidhansabha']?.toString().trim() ?? '';
    final location = district.isNotEmpty
        ? (tahasil.isNotEmpty ? "$district, $tahasil" : district)
        : (vidhansabha.isNotEmpty ? vidhansabha : 'छत्तीसगढ़');
    final pad = (user!['designation'] != null && user!['designation'].toString().trim().isNotEmpty)
        ? user!['designation'].toString().trim()
        : (user!['position'] != null && user!['position'].toString().trim().isNotEmpty
            ? user!['position'].toString().trim()
            : 'सदस्य');
    final referralCode = user!['referral_code']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD4AF37), width: 2.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.5),
        child: Container(
          color: const Color(0xFFFCFBF9),
          child: Stack(
            children: [
              // Background Watermark of Logo
              Positioned.fill(
                child: Center(
                  child: Opacity(
                    opacity: 0.06,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 210,
                      height: 210,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. TOP HEADER BAND
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF5A0B13),
                          Color(0xFF8B121A),
                          Color(0xFFA61B24),
                          Color(0xFF8B121A),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFD4AF37), width: 2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(height: 2.5, color: const Color(0xFFD4AF37)),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFFD4AF37),
                                    width: 1.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(2.5),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "छत्तीसगढ़िया क्रान्ति सेना",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD4AF37),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            "सदस्यता पहचान पत्र",
                                            style: TextStyle(
                                              color: Color(0xFF4A0000),
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          "MEMBER ID CARD",
                                          style: TextStyle(
                                            color: Color(0xFFFFD54F),
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. MIDDLE DETAILS: PHOTO + INFO
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Photo Column
                        GestureDetector(
                          onTap: _pickImage,
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 86,
                                    height: 102,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFD4AF37),
                                        width: 2.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                      color: Colors.grey.shade200,
                                      image: DecorationImage(
                                        image: _image != null
                                            ? FileImage(_image!)
                                            : (profilePhoto != null
                                                ? NetworkImage(profilePhoto)
                                                : const AssetImage('assets/images/profile.png'))
                                                as ImageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8B121A),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFF81C784)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 10, color: Color(0xFF2E7D32)),
                                    SizedBox(width: 3),
                                    Text(
                                      "सक्रिय सदस्य",
                                      style: TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Information Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A1A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (name2.isNotEmpty) ...[
                                const SizedBox(height: 1),
                                Text(
                                  name2,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 6),

                              _buildIdCardDetailRow(
                                icon: Icons.phone_android_rounded,
                                label: "मोबाईल",
                                value: mobile,
                              ),
                              const SizedBox(height: 3.5),
                              _buildIdCardDetailRow(
                                icon: Icons.location_on_outlined,
                                label: "स्थान",
                                value: location,
                              ),
                              const SizedBox(height: 3.5),
                              _buildIdCardDetailRow(
                                icon: Icons.badge_outlined,
                                label: "दायित्व",
                                value: pad,
                              ),
                              const SizedBox(height: 3.5),
                              _buildIdCardDetailRow(
                                icon: Icons.verified_user_outlined,
                                label: "मान्यता",
                                value: "आजीवन (Lifetime)",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. MEMBERSHIP NUMBER STRIP
                  if (referralCode.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFF9E6),
                            Color(0xFFFFECB3),
                            Color(0xFFFFE082),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD4AF37), width: 1.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.card_membership_rounded,
                                size: 16,
                                color: Color(0xFF8B121A),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "सदस्यता क्र. : ",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4A0000),
                                ),
                              ),
                              Text(
                                referralCode,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF8B121A),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: _showReferralQrCode,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B121A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.qr_code, size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    "QR कोड",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 4. FOOTER BAND (Clickable to visit website)
                  InkWell(
                    onTap: _launchWebsite,
                    child: Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(vertical: 5.5),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF5A0B13),
                            Color(0xFF8B121A),
                            Color(0xFF5A0B13),
                          ],
                        ),
                        border: Border(
                          top: BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "🌾 हमर छत्तीसगढ़ महतारी 🌾",
                          style: TextStyle(
                            color: Color(0xFFFFD54F),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdCardDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF8B121A)),
        const SizedBox(width: 4),
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    final str = (value == null || value.toString().trim().isEmpty) ? '-' : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              str,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _parseRuchi(dynamic ruchiRaw) {
    if (ruchiRaw == null) return [];
    if (ruchiRaw is List) {
      return List<String>.from(ruchiRaw.map((e) => e.toString()));
    }
    if (ruchiRaw is String && ruchiRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(ruchiRaw);
        if (decoded is List) {
          return List<String>.from(decoded.map((e) => e.toString()));
        }
      } catch (_) {}
      return [ruchiRaw];
    }
    return [];
  }

  Future<void> _launchWebsite() async {
    try {
      final uri = Uri.parse(Constants.baseUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Fluttertoast.showToast(msg: "Could not open website");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error opening website");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profilePhoto = user!['profile_photo'] != null
        ? "${Constants.storageUrl}/${user!['profile_photo']}"
        : null;

    final ruchiList = _parseRuchi(user!['ruchi']);

    return Scaffold(
      appBar: AppBar(
        title: const Text("सदस्यता पाती (Profile)"),
        centerTitle: true,
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: "Visit Website",
            onPressed: _launchWebsite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Member ID Card
            _buildMemberIdCard(profilePhoto),

            const SizedBox(height: 16),

            // Action Buttons (Single Row)
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      final updatedUser = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(user: user!),
                        ),
                      );
                      if (updatedUser != null) {
                        setState(() => user = updatedUser);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Edit Profile', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _showReferralQrCode,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.qr_code, size: 14),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('QR Code', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
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
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.share, size: 14),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Share Link', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
              ],
            ),

            if (isUploading) const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),

            const SizedBox(height: 16),

            // Incomplete Profile Prompt Banner
            if (_isProfileIncomplete())
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  children: [
                    Icon(Icons.assignment_late_outlined, color: Colors.amber.shade800),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "अपन प्रोफाइल पूरा करव",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            "सदस्यता पाती के पूरा विवरण भरे बर Edit Profile म क्लिक करव।",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(user: user!),
                          ),
                        );
                        if (updated != null) setState(() => user = updated);
                      },
                      child: const Text("भरें", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // SECTION 1: Personal Details
            _buildSectionCard(
              title: "व्यक्तिगत विवरण (Personal Details)",
              icon: Icons.person_outline,
              children: [
                _buildInfoRow("नाव (हिंदी)", user!['name']),
                _buildInfoRow("नाव (English)", user!['name2']),
                _buildInfoRow("पिता / पति", user!['father_name']),
                _buildInfoRow("माता के नाव", user!['mother_name']),
                _buildInfoRow("जनम तिथि", user!['dob']),
                _buildInfoRow("लिंग (Gender)", user!['gender']),
                _buildInfoRow("मोबाईल", user!['mobile']),
                _buildInfoRow("व्हाट्सएप", user!['whatsapp']),
                _buildInfoRow("ईमेल", user!['email']),
                _buildInfoRow("आधार नंबर", user!['adhar_no']),
                _buildInfoRow("मतदाता पत्र (Voter ID)", user!['ppatra']),
              ],
            ),

            // SECTION 2: Current Address
            _buildSectionCard(
              title: "वर्तमान पता (Current Address)",
              icon: Icons.home_outlined,
              children: [
                _buildInfoRow("मकान नं / पारा", user!['house_no']),
                _buildInfoRow("गांव / शहर", user!['city']),
                _buildInfoRow("तहसील", user!['tahasil']),
                _buildInfoRow("जिला", user!['district']),
                _buildInfoRow("राज्य", user!['state']),
                _buildInfoRow("थाना", user!['thana']),
                _buildInfoRow("डाकघर", user!['post_office']),
                _buildInfoRow("पिन कोड", user!['pin_code']),
                _buildInfoRow("पूरा पता", user!['address']),
              ],
            ),

            // SECTION 3: Purakhauti (Ancestral) Place
            _buildSectionCard(
              title: "पुरखउती पता (Ancestral Place)",
              icon: Icons.location_city_outlined,
              children: [
                _buildInfoRow("पुरखउती गाँव", user!['current_address']),
                _buildInfoRow("पंचायत / निगम", user!['panchayat']),
                _buildInfoRow("विधान सभा", user!['vidhansabha']),
                _buildInfoRow("लोकसभा क्षेत्र", user!['loksabha']),
              ],
            ),

            // SECTION 4: Education & Work
            _buildSectionCard(
              title: "शिक्षा, रूचि अउ बेवसाय",
              icon: Icons.work_outline,
              children: [
                _buildInfoRow("पढ़ई", user!['edu']),
                _buildInfoRow("कम्प्यूटर", user!['computer']),
                _buildInfoRow("बेवसाय", user!['occupation']),
                _buildInfoRow("पद / विवरण", user!['designation']),
                if (ruchiList.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  const Text(
                    "रूचियाँ:",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: ruchiList.map((r) {
                      return Chip(
                        label: Text(r, style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.red.shade50,
                        side: BorderSide(color: Colors.red.shade200),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),

            // SECTION 5: Social & Thoughts
            _buildSectionCard(
              title: "सोशल मीडिया एवं विचार",
              icon: Icons.public_outlined,
              children: [
                _buildInfoRow("फेसबुक", user!['facebook']),
                _buildInfoRow("ट्विटर / X", user!['twitter']),
                _buildInfoRow("अन्य दायित्व", user!['other_des']),
                _buildInfoRow("विचार / उद्देश्य", user!['bio']),
              ],
            ),

            // SECTION 6: Booth / Local
            if (user!['booth'] != null || user!['paar'] != null || user!['gudi'] != null || user!['khad'] != null)
              _buildSectionCard(
                title: "बूथ एवं स्थानीय विवरण",
                icon: Icons.domain,
                children: [
                  _buildInfoRow("Booth", user!['booth']),
                  _buildInfoRow("Paar", user!['paar']),
                  _buildInfoRow("Gudi", user!['gudi']),
                  _buildInfoRow("Khad", user!['khad']),
                ],
              ),

            const SizedBox(height: 10),

            // Visit Website Tile
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blue.shade100),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.language, color: Colors.blue, size: 20),
                ),
                title: const Text(
                  "वेबसाइट देखें (Visit Website)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue),
                ),
                subtitle: const Text(
                  Constants.baseUrl,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: const Icon(Icons.open_in_new, size: 18, color: Colors.blue),
                onTap: _launchWebsite,
              ),
            ),

            const SizedBox(height: 10),

            // Logout Tile
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red.shade100),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  "Logout",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
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
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
