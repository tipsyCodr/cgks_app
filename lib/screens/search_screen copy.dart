import 'package:cgks/api_service.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String adhikariNameQuery = "";
  String memberNameQuery = "";
  String selectedDistrict = "All";
  String? selectedPosition;
  String? selectedDesignation;

  List<String> districts = [];
  bool isLoadingDistricts = true;

  final List<String> positions = ['प्रदेश', 'जिला', 'खड़', 'गुड़ी', 'पार', 'बूथ'];

  final List<String> designations = [
    'संयोजक',
    'अध्यक्ष',
    'महामंत्री',
    'संगठन मंत्री',
    'उपाध्यक्ष',
    'मंत्री',
    'सचिव',
    'सहसचिव',
    'मिडिया प्रभारी',
    'IT प्रभारी',
    'सदस्यता प्रभारी',
    'कार्यकारिणी सदस्य',
  ];

  // Dummy users for now
  final List<Map<String, String>> users = [
    {
      "name": "Ravi Kumar",
      "district": "कोंडागाँव",
      "avatar": "https://avatar.iran.liara.run/public/boy?id=1",
      "position": "प्रदेश",
      "designation": "अध्यक्ष",
    },
    {
      "name": "Anita Sharma",
      "district": "बालोद",
      "avatar": "https://avatar.iran.liara.run/public/girl?id=1",
      "position": "जिला",
      "designation": "महामंत्री",
    },
  ];

  Future<void> loadDistricts() async {
    try {
      final fetched = await ApiService().fetchAllDistricts();
      setState(() {
        districts = fetched;
        selectedDistrict = districts.first;
        isLoadingDistricts = false;
      });
    } catch (e) {
      setState(() {
        districts = ["All"];
        isLoadingDistricts = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadDistricts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("सदस्य खोजें")),
      body: Column(
        children: [
          // 🔽 Small filter card
          Padding(
            padding: const EdgeInsets.all(1.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: [
                    _smallTextField("नाम", (v) {
                      setState(() => memberNameQuery = v);
                    }),
                    isLoadingDistricts
                        ? CircularProgressIndicator()
                        : _smallDropdown(
                            hint: "जिला",
                            value: selectedDistrict,
                            items: districts,
                            onChanged: (v) =>
                                setState(() => selectedDistrict = v!),
                          ),
                    // 🔽 Row for पद स्तर + पद नाम
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: _smallDropdown(
                            hint: "पद स्तर",
                            value: selectedPosition,
                            items: positions,
                            onChanged: (v) =>
                                setState(() => selectedPosition = v),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _smallDropdown(
                            hint: "पद नाम",
                            value: selectedDesignation,
                            items: designations,
                            onChanged: (v) =>
                                setState(() => selectedDesignation = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🔽 User list
          Expanded(child: _buildMemberList()),
        ],
      ),
    );
  }

  // 🔽 Compact text field
  Widget _smallTextField(String label, Function(String) onChanged) {
    return SizedBox(
      // width: 150,
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }

  // 🔽 Compact dropdown
  Widget _smallDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isDense: true,
      items: items
          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
          .toList(),
      decoration: InputDecoration(
        labelText: hint,
        isDense: true,
        border: OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }

  // 🔽 Filtered user list
  Widget _buildMemberList() {
    final filtered = users.where((user) {
      final matchesName =
          memberNameQuery.isEmpty ||
          user["name"]!.toLowerCase().contains(memberNameQuery.toLowerCase());
      final matchesDistrict =
          selectedDistrict == "All" || user["district"] == selectedDistrict;
      final matchesPosition =
          selectedPosition == null || user["position"] == selectedPosition;
      final matchesDesignation =
          selectedDesignation == null ||
          user["designation"] == selectedDesignation;

      return matchesName &&
          matchesDistrict &&
          matchesPosition &&
          matchesDesignation;
    }).toList();

    if (filtered.isEmpty) {
      return Center(child: Text("कोई सदस्य नहीं मिला"));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final user = filtered[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(user["avatar"]!),
            ),
            title: Text(user["name"]!),
            subtitle: Text(
              "जिला: ${user["district"]}, पद: ${user["position"]}, ${user["designation"]}",
            ),
          ),
        );
      },
    );
  }
}
