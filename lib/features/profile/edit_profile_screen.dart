import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController mobileController;
  late TextEditingController boothController;
  late TextEditingController paarController;
  late TextEditingController gudiController;
  late TextEditingController khadController;
  late TextEditingController occupationController;
  late TextEditingController emailController;
  late TextEditingController addressController;
  late TextEditingController passwordController;
  late TextEditingController currentAddressController;
  late TextEditingController whatsappController;

  @override
  void initState() {
    super.initState();
    final user = widget.user;

    // Initialize controllers with user data
    nameController = TextEditingController(text: user['name'] ?? '');
    mobileController = TextEditingController(text: user['mobile'] ?? '');
    boothController = TextEditingController(text: user['booth'] ?? '');
    paarController = TextEditingController(text: user['paar'] ?? '');
    gudiController = TextEditingController(text: user['gudi'] ?? '');
    khadController = TextEditingController(text: user['khad'] ?? '');
    occupationController = TextEditingController(
      text: user['occupation'] ?? '',
    );
    emailController = TextEditingController(text: user['email'] ?? '');
    addressController = TextEditingController(text: user['address'] ?? '');
    currentAddressController = TextEditingController(
      text: user['current_address'] ?? '',
    );
    whatsappController = TextEditingController(text: user['whatsapp'] ?? '');
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    boothController.dispose();
    paarController.dispose();
    gudiController.dispose();
    khadController.dispose();
    occupationController.dispose();
    emailController.dispose();
    addressController.dispose();
    passwordController.dispose();
    currentAddressController.dispose();
    whatsappController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final body = {
      "name": nameController.text,
      "mobile": mobileController.text,
      "booth": boothController.text,
      "paar": paarController.text,
      "gudi": gudiController.text,
      "khad": khadController.text,
      "occupation": occupationController.text,
      "email": emailController.text,
      "address": addressController.text,
      "current_address": currentAddressController.text,
      "whatsapp": whatsappController.text,
    };

    if (passwordController.text.isNotEmpty) {
      body['password'] = passwordController.text;
    }

    try {
      final response = await http.post(
        Uri.parse("https://cgks.pathideamultiskill.com/api/update-profile"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: body,
      );

      final decoded = jsonDecode(response.body);
      debugPrint(response.body);

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: "Profile updated!");
        prefs.setString("user", jsonEncode(decoded['user']));
        Navigator.pop(context, decoded['user']); // return updated user
      } else {
        Fluttertoast.showToast(
          msg: decoded['error']?.toString() ?? "Update failed",
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      obscureText: obscure,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField("Name", nameController),
              _buildTextField("Mobile", mobileController),
              _buildTextField("Booth", boothController),
              _buildTextField("Paar", paarController),
              _buildTextField("Gudi", gudiController),
              _buildTextField("Khad", khadController),
              _buildTextField("Occupation", occupationController),
              _buildTextField("Email", emailController),
              _buildTextField("Address", addressController),
              _buildTextField("Current Address", currentAddressController),
              _buildTextField("WhatsApp", whatsappController),
              _buildTextField("Password", passwordController, obscure: true),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
