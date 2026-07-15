import 'package:cgks/api_service.dart';
import 'package:cgks/features/auth/register_page.dart';
import 'package:cgks/features/auth/login_page.dart'; // ✅ uncommented
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ReferralPage extends StatefulWidget {
  ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  final TextEditingController _controller = TextEditingController();
  bool isLoading = false; // 👈 loader state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'रेफरल कोड ',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo.png', height: 200),
                  SizedBox(height: 20),
                  Text(
                    'रेफरल कोड भरे',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    autofocus: true,
                    controller: _controller,
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'रेफरल कोड ',
                      hintStyle: TextStyle(fontWeight: FontWeight.w500),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 8,
                    ),
                    child: FilledButton(
                      onPressed: () async {
                        try {
                          final code = _controller.text.trim();

                          if (code.isEmpty) {
                            Fluttertoast.showToast(
                              msg: "Please Enter Referral Code",
                            );
                            return;
                          }

                          setState(() => isLoading = true); // 👈 show loader
                          await ApiService().getReferredCodeUser(code);
                          Fluttertoast.showToast(
                            msg: "Referral Code Found!",
                            backgroundColor: Colors.green,
                            textColor: Colors.white,
                          );
                          if (!mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  RegisterPage(initialReferralCode: code),
                            ),
                          );
                        } catch (e) {
                          Fluttertoast.showToast(msg: "$e");
                        } finally {
                          if (mounted) {
                            setState(() => isLoading = false);
                          } // 👈 hide loader
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'जमा करें ',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),

                  // 👇 Add Login Link Here
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      child: Text(
                        "Already have an account? Login",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.black,
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
            ],
          ),
        ),
      ),
    );
  }
}
