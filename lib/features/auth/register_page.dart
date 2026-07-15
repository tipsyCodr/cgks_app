import 'package:cgks/api_service.dart';
import 'package:cgks/bottom_navigation.dart';
import 'package:cgks/dto/register_user_dto.dart';
import 'package:cgks/features/auth/controllers/register_form_controllers.dart';
import 'package:cgks/features/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:app_links/app_links.dart';

class RegisterPage extends StatefulWidget {
  final String? initialReferralCode;

  const RegisterPage({super.key, this.initialReferralCode});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  TextInputType type = TextInputType.text,
  bool obscure = false,
  Widget? suffixIcon,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon,
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    ),
  );
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final form = RegisterFormControllers();

  bool isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfPasswordVisible = false;

  List<String> designations = [];
  String? selectedDesignation;

  @override
  void initState() {
    super.initState();
    final initialCode = widget.initialReferralCode?.trim();
    if (initialCode != null && initialCode.isNotEmpty) {
      form.referralCode.text = initialCode;
      _fetchReferrerDetails(initialCode);
    }
    _initDeepLinkListener();
  }

  void _initDeepLinkListener() async {
    final _appLinks = AppLinks();

    // Check initial link
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) _handleDeepLink(uri);
    } catch (e) {
      debugPrint("Error getting initial link: $e");
    }

    // Listen for future links
    _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint("Deep link error: $err");
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint("Deep link received: $uri");
    final refCode = uri.queryParameters['ref'];
    if (refCode != null && refCode.isNotEmpty) {
      setState(() {
        form.referralCode.text = refCode;
      });
      _fetchReferrerDetails(refCode);
    }
  }

  void _fetchReferrerDetails(String code) async {
    try {
      Fluttertoast.showToast(msg: "Applying referral code...");
      final user = await ApiService().getReferredCodeUser(code);
      if (mounted) {
        setState(() {
          if (user.district != null) form.district.text = user.district!;
          if (user.city != null) form.city.text = user.city!;
        });
        Fluttertoast.showToast(msg: "Referral applied: ${user.name}");
      }
    } catch (e) {
      debugPrint("Error fetching referrer: $e");
      Fluttertoast.showToast(msg: "Invalid referral code");
    }
  }

  // Future<void> fetchDropdownData() async {
  //   try {
  //     final des = await ApiService().getDesignations();
  //     setState(() {
  //       designations = des;
  //     });
  //   } catch (e) {
  //     Fluttertoast.showToast(msg: "Failed to load designations: $e");
  //   }
  // }

  @override
  void dispose() {
    form.dispose();

    super.dispose();
  }

  Future<void> handleRegister(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      if (form.password.text != form.confPassword.text) {
        Fluttertoast.showToast(msg: "Passwords do not match");
        return;
      }

      setState(() => isLoading = true);

      try {
        final dto = RegisterUserDTO.fromControllers(form);
        debugPrint("User Data: ${dto.toJson()}");

        final data = await ApiService().registerUser(dto);
        debugPrint("Response: ${data.toString()}");
        Fluttertoast.showToast(msg: "Registration Successful 🎉");

        if (!context.mounted) return;
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => BottomNav()));
      } catch (e) {
        debugPrint("Error when registering user: $e");
        Fluttertoast.showToast(msg: "Error when registering user: $e");
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text("रजिस्टर करे")),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Image.asset('assets/images/logo.png', height: 200),
                      SizedBox(height: 20),
                      // 👇 Add Login Link Here
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginPage(),
                              ),
                            );
                          },
                          child: Text(
                            "पहले से अकाउंट है? लॉग इन करें.",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      _buildTextField(controller: form.name, label: "नाम"),
                      _buildTextField(
                        controller: form.mobile,
                        label: "मोबाइल नंबर",
                        type: TextInputType.phone,
                      ),
                      _buildTextField(
                        controller: form.email,
                        label: "ईमेल",
                        type: TextInputType.emailAddress,
                      ),
                      _buildTextField(
                        controller: form.address,
                        label: "पुर्खौती निवास",
                      ),
                      _buildTextField(
                        controller: form.currentAddress,
                        label: "वर्तमान निवास",
                      ),
                      _buildTextField(
                        controller: form.whatsapp,
                        label: "व्हाट्सएप नंबर",
                        type: TextInputType.phone,
                      ),
                      _buildTextField(controller: form.district, label: "जिला"),
                      _buildTextField(controller: form.city, label: "शहर"),
                      _buildTextField(
                        controller: form.referralCode,
                        label: "रेफरल कोड",
                      ),
                      _buildTextField(
                        controller: form.password,
                        label: "पासवर्ड",
                        obscure: !_isPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      _buildTextField(
                        controller: form.confPassword,
                        label: "पासवर्ड सुनिश्चित करे",
                        obscure: !_isConfPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfPasswordVisible = !_isConfPasswordVisible;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => handleRegister(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text("रजिस्टर करे"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
