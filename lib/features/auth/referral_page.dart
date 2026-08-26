import 'dart:async';
import 'package:cgks/api_service.dart';
import 'package:cgks/components/qr_scanner_screen.dart';
import 'package:cgks/features/auth/login_page.dart';
import 'package:cgks/features/auth/register_page.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  final TextEditingController _controller = TextEditingController();
  bool isLoading = false;
  Timer? _debounceTimer;
  String? _referrerName;
  bool _isReferrerValid = false;
  bool _isCheckingReferral = false;

  void _onReferralChanged(String value) {
    _debounceTimer?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _referrerName = null;
        _isReferrerValid = false;
        _isCheckingReferral = false;
      });
      return;
    }

    setState(() {
      _isCheckingReferral = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _lookupReferrer(trimmed);
    });
  }

  Future<void> _lookupReferrer(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _isCheckingReferral = true;
    });

    try {
      final user = await ApiService().getReferredCodeUser(trimmed);
      if (mounted) {
        setState(() {
          _isReferrerValid = true;
          _referrerName =
              "रेफरर: ${user.name}${user.city.isNotEmpty ? ' (${user.city})' : ''}";
          _isCheckingReferral = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isReferrerValid = false;
          _referrerName = "अमान्य रेफरल कोड";
          _isCheckingReferral = false;
        });
      }
    }
  }

  Future<void> _scanQrCode() async {
    final scannedResult = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (scannedResult != null && scannedResult.isNotEmpty) {
      setState(() {
        _controller.text = scannedResult;
      });
      _submitReferralCode(scannedResult);
    }
  }

  Future<void> _submitReferralCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      Fluttertoast.showToast(msg: "Please Enter Referral Code");
      return;
    }

    try {
      setState(() => isLoading = true);
      await ApiService().getReferredCodeUser(trimmed);
      Fluttertoast.showToast(
        msg: "Referral Code Found!",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RegisterPage(initialReferralCode: trimmed),
        ),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "$e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
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
                  const SizedBox(height: 20),
                  const Text(
                    'रेफरल कोड भरे',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    autofocus: true,
                    controller: _controller,
                    onChanged: _onReferralChanged,
                    style: const TextStyle(
                      color: Colors.black,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'रेफरल कोड ',
                      hintStyle: const TextStyle(fontWeight: FontWeight.w500),
                      filled: true,
                      fillColor: Colors.white,
                      helperText: _referrerName,
                      helperStyle: TextStyle(
                        color: _isReferrerValid
                            ? Colors.green[700]
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isCheckingReferral)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          else if (_isReferrerValid)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.0),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                            ),
                          IconButton(
                            icon: const Icon(
                              Icons.qr_code_scanner,
                              color: Colors.red,
                            ),
                            tooltip: "QR कोड स्कैन करें",
                            onPressed: _scanQrCode,
                          ),
                        ],
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
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
                      onPressed: () => _submitReferralCode(_controller.text),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'जमा करें ',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Text(
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
                  if (isLoading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: const Center(child: CircularProgressIndicator()),
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
