import 'package:flutter/material.dart';
import 'package:cgks/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  Future<void> sendResetLink() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please enter your email")));
      return;
    }

    debugPrint("[ForgotPasswordScreen] User requested reset for: $email");
    setState(() => isLoading = true);

    try {
      await ApiService().sendResetLink(email);
      debugPrint("[ForgotPasswordScreen] Reset link successfully sent to: $email");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Reset link sent. Please Check your Registered email.",
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      debugPrint("[ForgotPasswordScreen] Error sending reset link: $e");
      debugPrint("[ForgotPasswordScreen] Stack trace: $stackTrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll("Exception: ", ""),
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("पासवर्ड भूल गए ?")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: "अपना ईमेल डाले ",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isLoading ? null : sendResetLink,
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text("रिसेट लिंक सेंड करे"),
            ),
          ],
        ),
      ),
    );
  }
}
