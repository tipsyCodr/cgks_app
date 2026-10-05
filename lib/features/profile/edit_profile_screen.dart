import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cgks/constants.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // 1. व्यक्तिगत विवरण
  late TextEditingController nameController;
  late TextEditingController name2Controller;
  late TextEditingController fatherNameController;
  late TextEditingController motherNameController;
  late TextEditingController dobController;
  String? selectedGender;
  late TextEditingController mobileController;
  late TextEditingController whatsappController;
  late TextEditingController emailController;
  late TextEditingController adharNoController;
  late TextEditingController ppatraController;

  // 2. वर्तमान पता
  late TextEditingController houseNoController;
  late TextEditingController cityController;
  late TextEditingController tahasilController;
  late TextEditingController districtController;
  late TextEditingController stateController;
  late TextEditingController thanaController;
  late TextEditingController postOfficeController;
  late TextEditingController pinCodeController;
  late TextEditingController addressController;

  // 3. पुरखउती (मूल) पता
  late TextEditingController currentAddressController; // Purakhauti gaon
  late TextEditingController panchayatController;
  late TextEditingController vidhansabhaController;
  late TextEditingController loksabhaController;

  // 4. शिक्षा, रूचि अउ बेवसाय
  late TextEditingController eduController;
  late TextEditingController computerController;
  List<String> selectedRuchi = [];
  String? selectedOccupation;
  late TextEditingController designationController;

  // 5. सोशल मीडिया एवं अन्य
  late TextEditingController facebookController;
  late TextEditingController twitterController;
  late TextEditingController otherDesController;
  late TextEditingController bioController;
  late TextEditingController passwordController;

  // Booth / Legacy
  late TextEditingController boothController;
  late TextEditingController paarController;
  late TextEditingController gudiController;
  late TextEditingController khadController;

  final List<String> genderOptions = ['पुरुष', 'महिला', 'अन्य'];

  final List<String> occupationOptions = [
    'खेती किसानी',
    'निजी बेवसाय',
    'सरकारी / प्राइवेट कर्मचारी',
    'विद्यार्थी',
    'बेरोजगार',
    'अन्य',
  ];

  final List<String> ruchiOptions = [
    'समाजिक बुता',
    'स्वास्थ्य',
    'मिडिया',
    'साहित्य',
    'खेल',
    'कला / संस्कृति',
    'खेती किसानी',
    'राजनीति',
    'विशेष योग्यता',
    'अन्य',
  ];

  final List<String> chhattisgarhDistricts = [
    'रायपुर',
    'दुर्ग',
    'बिलासपुर',
    'राजनांदगांव',
    'धमतरी',
    'महासमुन्द',
    'कोरबा',
    'जांजगीर-चांपा',
    'रायगढ़',
    'बलौदाबाजार',
    'कवर्धा',
    'कांकेर',
    'जगदलपुर (बस्तर)',
    'सरगुजा (अम्बिकापुर)',
    'बालोद',
    'बेमेतरा',
    'गरियाबंद',
    'सूरजपुर',
    'बलरामपुर',
    'कोण्डागांव',
    'नारायणपुर',
    'दंतेवाड़ा',
    'बीजापुर',
    'सुकमा',
    'जशपुर',
    'कोरिया',
    'मुंगेली',
    'गौरेला-पेंड्रा-मरवाही',
    'सारंगढ़-बिलाईगढ़',
    'मोहला-मानपुर-अंबागढ़ चौकी',
    'खैरागढ़-छुईखदान-गंडई',
    'सक्ती',
    'मनेन्द्रगढ़-चिरमिरी-भरतपुर',
  ];

  @override
  void initState() {
    super.initState();
    final u = widget.user;

    // 1. Personal
    nameController = TextEditingController(text: u['name'] ?? '');
    name2Controller = TextEditingController(text: u['name2'] ?? '');
    fatherNameController = TextEditingController(text: u['father_name'] ?? '');
    motherNameController = TextEditingController(text: u['mother_name'] ?? '');
    dobController = TextEditingController(text: u['dob'] ?? '');
    selectedGender = u['gender']?.toString().isNotEmpty == true
        ? u['gender'].toString()
        : 'पुरुष';
    mobileController = TextEditingController(text: u['mobile'] ?? '');
    whatsappController = TextEditingController(text: u['whatsapp'] ?? '');
    emailController = TextEditingController(text: u['email'] ?? '');
    adharNoController = TextEditingController(text: u['adhar_no'] ?? '');
    ppatraController = TextEditingController(text: u['ppatra'] ?? '');

    // 2. Current Address
    houseNoController = TextEditingController(text: u['house_no'] ?? '');
    cityController = TextEditingController(text: u['city'] ?? '');
    tahasilController = TextEditingController(text: u['tahasil'] ?? '');
    districtController = TextEditingController(text: u['district'] ?? '');
    stateController = TextEditingController(
      text: u['state']?.toString().isNotEmpty == true
          ? u['state']
          : 'छत्तीसगढ़',
    );
    thanaController = TextEditingController(text: u['thana'] ?? '');
    postOfficeController = TextEditingController(text: u['post_office'] ?? '');
    pinCodeController = TextEditingController(text: u['pin_code'] ?? '');
    addressController = TextEditingController(text: u['address'] ?? '');

    // 3. Purakhauti
    currentAddressController = TextEditingController(
      text: u['current_address'] ?? '',
    );
    panchayatController = TextEditingController(text: u['panchayat'] ?? '');
    vidhansabhaController = TextEditingController(text: u['vidhansabha'] ?? '');
    loksabhaController = TextEditingController(text: u['loksabha'] ?? '');

    // 4. Education, Interest & Occupation
    eduController = TextEditingController(text: u['edu'] ?? '');
    computerController = TextEditingController(text: u['computer'] ?? '');
    if (u['ruchi'] != null) {
      if (u['ruchi'] is List) {
        selectedRuchi = List<String>.from(u['ruchi'].map((e) => e.toString()));
      } else if (u['ruchi'] is String && u['ruchi'].toString().isNotEmpty) {
        try {
          final decoded = jsonDecode(u['ruchi']);
          if (decoded is List) {
            selectedRuchi = List<String>.from(decoded.map((e) => e.toString()));
          } else {
            selectedRuchi = [u['ruchi'].toString()];
          }
        } catch (_) {
          selectedRuchi = [u['ruchi'].toString()];
        }
      }
    }
    selectedOccupation = u['occupation']?.toString();
    designationController = TextEditingController(text: u['designation'] ?? '');

    // 5. Social & Other
    facebookController = TextEditingController(text: u['facebook'] ?? '');
    twitterController = TextEditingController(text: u['twitter'] ?? '');
    otherDesController = TextEditingController(text: u['other_des'] ?? '');
    bioController = TextEditingController(text: u['bio'] ?? '');
    passwordController = TextEditingController();

    // Legacy / booth
    boothController = TextEditingController(text: u['booth'] ?? '');
    paarController = TextEditingController(text: u['paar'] ?? '');
    gudiController = TextEditingController(text: u['gudi'] ?? '');
    khadController = TextEditingController(text: u['khad'] ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    name2Controller.dispose();
    fatherNameController.dispose();
    motherNameController.dispose();
    dobController.dispose();
    mobileController.dispose();
    whatsappController.dispose();
    emailController.dispose();
    adharNoController.dispose();
    ppatraController.dispose();

    houseNoController.dispose();
    cityController.dispose();
    tahasilController.dispose();
    districtController.dispose();
    stateController.dispose();
    thanaController.dispose();
    postOfficeController.dispose();
    pinCodeController.dispose();
    addressController.dispose();

    currentAddressController.dispose();
    panchayatController.dispose();
    vidhansabhaController.dispose();
    loksabhaController.dispose();

    eduController.dispose();
    computerController.dispose();
    designationController.dispose();

    facebookController.dispose();
    twitterController.dispose();
    otherDesController.dispose();
    bioController.dispose();
    passwordController.dispose();

    boothController.dispose();
    paarController.dispose();
    gudiController.dispose();
    khadController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    DateTime initial = DateTime(2000, 1, 1);
    if (dobController.text.isNotEmpty) {
      try {
        initial = DateFormat('yyyy-MM-dd').parse(dobController.text);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      locale: const Locale('hi', 'IN'),
    );

    if (picked != null) {
      setState(() {
        dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      Fluttertoast.showToast(msg: "कृपया अनिवार्य जानकारी भरें");
      return;
    }

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final body = <String, dynamic>{
      // 1. Personal
      "name": nameController.text.trim(),
      "name2": name2Controller.text.trim().toUpperCase(),
      "father_name": fatherNameController.text.trim(),
      "mother_name": motherNameController.text.trim(),
      "dob": dobController.text.trim(),
      "gender": selectedGender ?? '',
      "mobile": mobileController.text.trim(),
      "whatsapp": whatsappController.text.trim(),
      "email": emailController.text.trim(),
      "adhar_no": adharNoController.text.trim(),
      "ppatra": ppatraController.text.trim(),

      // 2. Address
      "house_no": houseNoController.text.trim(),
      "city": cityController.text.trim(),
      "tahasil": tahasilController.text.trim(),
      "district": districtController.text.trim(),
      "state": stateController.text.trim(),
      "thana": thanaController.text.trim(),
      "post_office": postOfficeController.text.trim(),
      "pin_code": pinCodeController.text.trim(),
      "address": addressController.text.trim(),

      // 3. Purakhauti
      "current_address": currentAddressController.text.trim(),
      "panchayat": panchayatController.text.trim(),
      "vidhansabha": vidhansabhaController.text.trim(),
      "loksabha": loksabhaController.text.trim(),

      // 4. Education, Interest & Occupation
      "edu": eduController.text.trim(),
      "computer": computerController.text.trim(),
      "ruchi": selectedRuchi,
      "occupation": selectedOccupation ?? '',
      "designation": designationController.text.trim(),

      // 5. Social & Other
      "facebook": facebookController.text.trim(),
      "twitter": twitterController.text.trim(),
      "other_des": otherDesController.text.trim(),
      "bio": bioController.text.trim(),

      // Legacy booth
      "booth": boothController.text.trim(),
      "paar": paarController.text.trim(),
      "gudi": gudiController.text.trim(),
      "khad": khadController.text.trim(),
    };

    if (passwordController.text.isNotEmpty) {
      body['password'] = passwordController.text;
    }

    try {
      final response = await http.post(
        Uri.parse("${Constants.apiUrl}/update-profile"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: "सदस्यता प्रोफाइल सफलतापूर्वक अपडेट हो गया!");
        final updatedUser = decoded['user'];
        await prefs.setString("user", jsonEncode(updatedUser));
        if (!mounted) return;
        Navigator.pop(context, updatedUser);
      } else {
        final err = decoded['error'];
        String msg = "अपडेट विफल रहा";
        if (err is Map) {
          msg = err.values.map((v) => v is List ? v.join(', ') : v.toString()).join('\n');
        } else if (decoded['message'] != null) {
          msg = decoded['message'].toString();
        }
        Fluttertoast.showToast(msg: msg);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionHeader({
    required int number,
    required String title,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.red.shade900.withValues(alpha: 0.3)
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.red.shade800 : Colors.red.shade100,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: Colors.red.shade700,
            child: Text(
              "$number",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            icon,
            size: 20,
            color: isDark ? Colors.red.shade400 : Colors.red.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.red.shade200 : Colors.red.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
    bool required = false,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    String? hint,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        textCapitalization: textCapitalization,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: required ? "$label *" : label,
          hintText: hint,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        validator: required
            ? (value) => value == null || value.trim().isEmpty ? '$label अनिवार्य है' : null
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text("सदस्यता पाती (Profile Edit)"),
        centerTitle: true,
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
                color: isDark
                    ? Colors.orange.shade900.withValues(alpha: 0.25)
                    : Colors.orange.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isDark ? Colors.orange.shade700 : Colors.orange.shade200,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDark ? Colors.orange.shade300 : Colors.deepOrange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "अपन प्रोफाइल के पूरा विवरण भरव, जेकर से आप मन के सदस्यता पाती डिजिटल रूप म सुरक्षित रहय।",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.orange.shade200 : Colors.brown,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // SECTION 1: व्यक्तिगत विवरण
              _buildSectionHeader(
                number: 1,
                title: "व्यक्तिगत विवरण (Personal Details)",
                icon: Icons.person,
              ),
              _buildTextField("नाव (नाम - छत्तीसगढ़ी/हिंदी म)", nameController, required: true),
              _buildTextField(
                "अंग्रेजी म नाव (IN CAPITAL)",
                name2Controller,
                hint: "उदा. AMIT KUMAR BAGHEL",
                textCapitalization: TextCapitalization.characters,
              ),
              _buildTextField("पिता / पति के नाव", fatherNameController),
              _buildTextField("महतारी (माता) के नाव", motherNameController),
              _buildTextField(
                "जनम तिथि (Date of Birth)",
                dobController,
                readOnly: true,
                onTap: _pickDateOfBirth,
                hint: "YYYY-MM-DD",
                suffixIcon: const Icon(Icons.calendar_today, size: 20),
              ),

              // Gender Selection
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "लिंग (Gender):",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: genderOptions.map((g) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: g,
                                groupValue: selectedGender,
                                activeColor: Colors.red.shade700,
                                onChanged: (val) => setState(() => selectedGender = val),
                              ),
                              Text(g),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              _buildTextField(
                "मोबाईल नंबर",
                mobileController,
                required: true,
                type: TextInputType.phone,
              ),
              _buildTextField(
                "व्हाट्सएप नंबर",
                whatsappController,
                type: TextInputType.phone,
              ),
              _buildTextField(
                "ईमेल (Email Address)",
                emailController,
                type: TextInputType.emailAddress,
              ),
              _buildTextField(
                "आधार नंबर",
                adharNoController,
                type: TextInputType.number,
                hint: "12 अंकों का आधार नंबर",
              ),
              _buildTextField(
                "मतदाता पहचान पत्र क्र. (Voter ID)",
                ppatraController,
                hint: "मतदाता परिचय पत्र क्रमांक",
              ),

              // SECTION 2: वर्तमान पता
              _buildSectionHeader(
                number: 2,
                title: "वर्तमान पता (Current Address)",
                icon: Icons.home,
              ),
              _buildTextField("मकान नं. / पारा", houseNoController),
              _buildTextField("गांव / शहर / वार्ड नाव, नं.", cityController, required: true),
              _buildTextField("तहसील / वि. ख.", tahasilController),

              // District AutoComplete / Dropdown
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Autocomplete<String>(
                  initialValue: TextEditingValue(text: districtController.text),
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return chhattisgarhDistricts;
                    }
                    return chhattisgarhDistricts.where((d) =>
                        d.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (selection) {
                    districtController.text = selection;
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    controller.addListener(() {
                      districtController.text = controller.text;
                    });
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: "जिला (District) *",
                        hintText: "जिला चुनें या लिखें",
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'जिला अनिवार्य है' : null,
                    );
                  },
                ),
              ),

              _buildTextField("राज्य (State)", stateController),
              _buildTextField("थाना", thanaController),
              _buildTextField("डाकघर (पो.आ.)", postOfficeController),
              _buildTextField("पिन कोड", pinCodeController, type: TextInputType.number),
              _buildTextField("स्थानीय पूरा पता (Address)", addressController, maxLines: 2),

              // SECTION 3: पुरखउती पता
              _buildSectionHeader(
                number: 3,
                title: "पुरखउती पता (Ancestral / Native Place)",
                icon: Icons.holiday_village,
              ),
              _buildTextField("पुरखउती गाँव / मूल निवास", currentAddressController),
              _buildTextField("नगर पंचायत / पालिका / निगम", panchayatController),
              _buildTextField("विधान सभा क्षेत्र", vidhansabhaController),
              _buildTextField("लोकसभा क्षेत्र", loksabhaController),

              // SECTION 4: शिक्षा, रूचि अउ बेवसाय
              _buildSectionHeader(
                number: 4,
                title: "शिक्षा, रूचि अउ बेवसाय (Education & Work)",
                icon: Icons.work,
              ),
              _buildTextField("पढ़ई के पुरा जानकारी (Qualification)", eduController),
              _buildTextField("कम्प्यूटर के जानकारी", computerController),

              // Interests / Ruchi Chips
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "रूचि (Areas of Interest):",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ruchiOptions.map((ruchi) {
                        final isSelected = selectedRuchi.contains(ruchi);
                        return FilterChip(
                          label: Text(ruchi),
                          selected: isSelected,
                          selectedColor: isDark
                              ? Colors.red.shade900.withValues(alpha: 0.5)
                              : Colors.red.shade100,
                          checkmarkColor: isDark ? Colors.white : Colors.red.shade800,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? (isSelected ? Colors.white : Colors.white70)
                                : (isSelected ? Colors.red.shade900 : Colors.black87),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedRuchi.add(ruchi);
                              } else {
                                selectedRuchi.remove(ruchi);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Occupation Dropdown
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: DropdownButtonFormField<String>(
                  initialValue: occupationOptions.contains(selectedOccupation)
                      ? selectedOccupation
                      : null,
                  decoration: InputDecoration(
                    labelText: "बेवसाय (Occupation)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  hint: const Text("-- व्यवसाय चुनव --"),
                  items: occupationOptions.map((occ) {
                    return DropdownMenuItem(value: occ, child: Text(occ));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedOccupation = val),
                ),
              ),

              _buildTextField("कर्मचारी के पद नाव / बेवसाय के विवरन", designationController),

              // SECTION 5: सोशल मीडिया एवं अन्य
              _buildSectionHeader(
                number: 5,
                title: "सोशल मीडिया एवं अन्य (Social & Other)",
                icon: Icons.share,
              ),
              _buildTextField("फेसबुक प्रोफाइल लिंक", facebookController, hint: "facebook.com/..."),
              _buildTextField("ट्विटर / X हैंडल", twitterController, hint: "@username"),
              _buildTextField("कोन्हो दूसर संगठन म दायित्व / पद", otherDesController, maxLines: 2),
              _buildTextField(
                "रूचि / संगठन से जुड़ने का उद्देश्य / विचार",
                bioController,
                maxLines: 3,
                hint: "अपन विचार लिखव...",
              ),

              // Optional password change
              _buildTextField(
                "नया पासवर्ड (यदि बदलना चाहते हैं)",
                passwordController,
                obscure: true,
                hint: "खाली छोड़ें यदि नहीं बदलना है",
              ),

              // SECTION 6: बूथ / स्थानीय (वैकल्पिक)
              ExpansionTile(
                title: const Text(
                  "बूथ / वार्ड विवरण (वैकल्पिक)",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                tilePadding: EdgeInsets.zero,
                children: [
                  _buildTextField("Booth", boothController),
                  _buildTextField("Paar (पारा)", paarController),
                  _buildTextField("Gudi (गुड़ी)", gudiController),
                  _buildTextField("Khad (खाद)", khadController),
                ],
              ),

              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isLoading ? "अपडेट हो रहा है..." : "सदस्यता पाती सुरक्षित करें (Save)",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
