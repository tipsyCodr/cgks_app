import 'package:cgks/api_service.dart';
import 'package:cgks/bottom_navigation.dart';
import 'package:cgks/features/auth/forgot_password_screen.dart';
import 'package:cgks/features/auth/referral_page.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:app_links/app_links.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false; // 👈 loader state
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _checkDeepLink();
  }

  void _checkDeepLink() async {
    try {
      final appLinks = AppLinks();
      final uri = await appLinks.getInitialLink();
      if (uri != null && uri.path.contains('/register')) {
        if (mounted) {
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (_) => ReferralPage()));
        }
      }
    } catch (e) {
      debugPrint("Deep link error in login: $e");
    }
  }

  void handleLogin(BuildContext context) async {
    if (_mobileController.text.isEmpty || _passwordController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please enter Phone & Password!",
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
      return;
    }

    try {
      setState(() => isLoading = true); // 👈 show loader

      final result = await ApiService().loginUser(
        _mobileController.text.trim(),
        _passwordController.text.trim(),
      );

      debugPrint("Login Response: $result");

      Fluttertoast.showToast(
        msg: "Login Successful!",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      // ✅ Navigate after successful login
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => BottomNav()),
        (Route<dynamic> route) => false, // remove all previous routes
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Login failed: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => isLoading = false); // 👈 hide loader
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "लॉग इन ",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
        centerTitle: true,
        // leading: const BackButton(),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/logo.png', height: 200),
                    SizedBox(height: 20),
                    AutofillGroup(
                      child: TextFormField(
                        controller: _mobileController,
                        autofillHints: [
                          AutofillHints.username,
                          AutofillHints.telephoneNumber,
                        ],
                        keyboardType: TextInputType.phone, // or phone
                        decoration: InputDecoration(
                          labelText: 'मोबाइल नंबर डाले',
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AutofillGroup(
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        autofillHints: [AutofillHints.password],

                        decoration: InputDecoration(
                          labelText: 'पासवर्ड डाले',
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          border: OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => handleLogin(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('लॉग इन करे'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => ReferralPage()),
                            );
                          },
                          child: const Text(
                            "अकाउंट नहीं है? हमसे जुड़े",
                            style: TextStyle(
                              color: Colors.black,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.black,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "पासवर्ड याद नहीं ?",
                            style: TextStyle(
                              color: Colors.black,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // optional fullscreen loader overlay
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
