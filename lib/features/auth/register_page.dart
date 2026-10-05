import 'dart:async';
import 'package:cgks/api_service.dart';
import 'package:cgks/bottom_navigation.dart';
import 'package:cgks/components/qr_scanner_screen.dart';
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
  String? hintText,
  TextInputType type = TextInputType.text,
  bool obscure = false,
  bool required = true,
  TextCapitalization textCapitalization = TextCapitalization.none,
  Widget? suffixIcon,
  String? helperText,
  Color? helperColor,
  void Function(String)? onChanged,
  BuildContext? context,
}) {
  final textColor = context != null
      ? Theme.of(context).colorScheme.onSurface
      : null;
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      style: textColor != null ? TextStyle(color: textColor) : null,
      decoration: InputDecoration(
        labelText: required ? "$label *" : label,
        hintText: hintText,
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon,
        helperText: helperText,
        helperStyle: helperColor != null
            ? TextStyle(
                color: helperColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              )
            : null,
      ),
      validator: (value) =>
          (required && (value == null || value.trim().isEmpty))
              ? 'Required'
              : null,
    ),
  );
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final form = RegisterFormControllers();

  bool isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfPasswordVisible = false;

  Timer? _debounceTimer;
  String? _referrerName;
  bool _isReferrerValid = false;
  bool _isCheckingReferral = false;

  List<String> designations = [];
  String? selectedDesignation;

  @override
  void initState() {
    super.initState();
    final initialCode = widget.initialReferralCode?.trim();
    if (initialCode != null && initialCode.isNotEmpty) {
      form.referralCode.text = initialCode;
      _fetchReferrerDetails(initialCode, showToast: true);
    }
    _initDeepLinkListener();
  }

  void _initDeepLinkListener() async {
    final appLinks = AppLinks();

    // Check initial link
    try {
      final uri = await appLinks.getInitialLink();
      if (uri != null) _handleDeepLink(uri);
    } catch (e) {
      debugPrint("Error getting initial link: $e");
    }

    // Listen for future links
    appLinks.uriLinkStream.listen(
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
    String? refCode = uri.queryParameters['ref'];
    if (refCode == null || refCode.isEmpty) {
      final segments = uri.pathSegments;
      if (segments.length >= 2 && segments[0] == 'register') {
        refCode = segments[1];
      }
    }
    if (refCode != null && refCode.isNotEmpty) {
      setState(() {
        form.referralCode.text = refCode!;
      });
      _fetchReferrerDetails(refCode, showToast: true);
    }
  }

  void _onReferralCodeChanged(String value) {
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
      _fetchReferrerDetails(trimmed, showToast: false);
    });
  }

  Future<void> _scanQrCode() async {
    final scannedResult = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (scannedResult != null && scannedResult.isNotEmpty) {
      setState(() {
        form.referralCode.text = scannedResult;
      });
      _fetchReferrerDetails(scannedResult, showToast: true);
    }
  }

  void _fetchReferrerDetails(String code, {bool showToast = false}) async {
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
          if (user.district.isNotEmpty && form.district.text.isEmpty) {
            form.district.text = user.district;
          }
          if (user.city.isNotEmpty && form.city.text.isEmpty) {
            form.city.text = user.city;
          }
        });
        if (showToast) {
          Fluttertoast.showToast(msg: "Referral applied: ${user.name}");
        }
      }
    } catch (e) {
      debugPrint("Error fetching referrer: $e");
      if (mounted) {
        setState(() {
          _isReferrerValid = false;
          _referrerName = "अमान्य रेफरल कोड";
          _isCheckingReferral = false;
        });
        if (showToast) {
          Fluttertoast.showToast(msg: "Invalid referral code");
        }
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            }
                          },
                          child: Builder(
                            builder: (ctx) {
                              final color = Theme.of(ctx).colorScheme.onSurface;
                              return Text(
                                "पहले से अकाउंट है? लॉग इन करें.",
                                style: TextStyle(
                                  color: color,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                  decorationColor: color,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      _buildTextField(
                        controller: form.name,
                        label: "नाव (नाम - छत्तीसगढ़ी/हिंदी म)",
                        hintText: "उदा. अमित कुमार बघेल",
                        context: context,
                      ),
                      _buildTextField(
                        controller: form.name2,
                        label: "अंग्रेजी म नाव (IN CAPITAL)",
                        hintText: "उदा. AMIT KUMAR BAGHEL",
                        required: false,
                        textCapitalization: TextCapitalization.characters,
                        context: context,
                      ),
                      _buildTextField(
                        controller: form.mobile,
                        label: "मोबाइल नंबर",
                        type: TextInputType.phone,
                        context: context,
                      ),
                      _buildTextField(
                        controller: form.email,
                        label: "ईमेल",
                        type: TextInputType.emailAddress,
                        context: context,
                      ),
                      _buildTextField(
                        controller: form.address,
                        label: "पुर्खौती निवास",
                        context: context,
                      ),
                      _buildTextField(
                        controller: form.currentAddress,
                        label: "वर्तमान निवास",
                        context: context,
                      ),
                      _buildTextField(
                        controller: form.whatsapp,
                        label: "व्हाट्सएप नंबर",
                        type: TextInputType.phone,
                        context: context,
                      ),
                      _buildTextField(controller: form.district, label: "जिला", context: context),
                      _buildTextField(controller: form.city, label: "शहर", context: context),
                      _buildTextField(
                        controller: form.referralCode,
                        label: "रेफरल कोड",
                        onChanged: _onReferralCodeChanged,
                        helperText: _referrerName,
                        helperColor: _isReferrerValid
                            ? Colors.green[700]
                            : Colors.red,
                        context: context,
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
                      ),
                      _buildTextField(
                        controller: form.password,
                        label: "पासवर्ड",
                        obscure: !_isPasswordVisible,
                        context: context,
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
                        context: context,
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
