import 'package:cgks/api_service.dart';
import 'package:cgks/constants.dart';
import 'package:cgks/screens/user_details_screen.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Filters
  String adhikariNameQuery = "";
  String selectedDistrict = "All";
  String? selectedPosition = "All";
  String? selectedDesignation = "All";

  // Districts
  List<String> districts = ["All"];
  bool isLoadingDistricts = true;
  String? districtsError;

  // Positions & Designations
  final List<String> positions = [
    'All',
    'प्रदेश',
    'जिला',
    'खड़',
    'गुड़ी',
    'पार',
    'बूथ',
  ];

  final List<String> designations = [
    'All',
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

  // Users from server
  List<dynamic> fetchedUsers = [];
  bool isLoadingUsers = false;
  String? usersError;

  @override
  void initState() {
    super.initState();
    loadDistricts();
    fetchUsers();
  }

  /// Load districts from server
  Future<void> loadDistricts() async {
    try {
      if (!mounted) return;
      setState(() {
        isLoadingDistricts = true;
        districtsError = null;
      });

      final fetched = await ApiService().fetchAllDistricts();
      final uniqueDistricts = <String>{"All", ...fetched}.toList();

      if (!mounted) return;
      setState(() {
        districts = uniqueDistricts;
        isLoadingDistricts = false;
        if (!districts.contains(selectedDistrict)) selectedDistrict = "All";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        districts = ["All"];
        isLoadingDistricts = false;
        selectedDistrict = "All";
        districtsError = "Failed to load districts: $e";
      });
    }
  }

  /// Fetch users from server based on selected filters
  Future<void> fetchUsers() async {
    if (!mounted) return;
    setState(() {
      isLoadingUsers = true;
      usersError = null;
    });

    try {
      List<dynamic> usersByPosition = [];
      List<dynamic> usersByDesignation = [];

      if (selectedPosition != null && selectedPosition != "All") {
        usersByPosition = await ApiService().getUserByPosition(
          selectedPosition!,
        );
      }

      if (selectedDesignation != null && selectedDesignation != "All") {
        usersByDesignation = await ApiService().getUserByDesignation(
          selectedDesignation!,
        );
      }

      List<dynamic> finalUsers;
      if (selectedPosition != "All" && selectedDesignation != "All") {
        finalUsers = usersByPosition
            .where((u) => usersByDesignation.any((d) => d['id'] == u['id']))
            .toList();
      } else if (selectedPosition != "All") {
        finalUsers = usersByPosition;
      } else if (selectedDesignation != "All") {
        finalUsers = usersByDesignation;
      } else {
        finalUsers = await ApiService().getAllUsers();
      }

      if (adhikariNameQuery.isNotEmpty) {
        finalUsers = finalUsers
            .where(
              (u) => (u['name'] ?? "").toLowerCase().contains(
                adhikariNameQuery.toLowerCase(),
              ),
            )
            .toList();
      }

      if (!mounted) return;
      setState(() {
        fetchedUsers = finalUsers;
        isLoadingUsers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        usersError = e.toString();
        isLoadingUsers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "सदस्य खोजें",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.5),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            SizedBox(height: 12),
            _smallTextField("नाम से ढूंढे", (v) {
              setState(() => adhikariNameQuery = v);
              fetchUsers();
            }),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _smallDropdown(
                    hint: "पद स्तर",
                    value: selectedPosition,
                    items: positions,
                    onChanged: (v) async {
                      setState(() => selectedPosition = v);
                      await fetchUsers();
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _smallDropdown(
                    hint: "पद नाम",
                    value: selectedDesignation,
                    items: designations,
                    onChanged: (v) async {
                      setState(() => selectedDesignation = v);
                      await fetchUsers();
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Expanded(child: _buildAdhikariList()),
          ],
        ),
      ),
    );
  }

  Widget _smallTextField(String label, Function(String) onChanged) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: onChanged,
    );
  }

  Widget _smallDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final uniqueItems = items.isEmpty ? [hint] : items.toSet().toList();
    final validValue = value != null && uniqueItems.contains(value)
        ? value
        : null;

    return DropdownButtonFormField<String>(
      value: validValue,
      isDense: true,
      isExpanded: true,
      items: uniqueItems
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      decoration: InputDecoration(
        labelText: hint,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildAdhikariList() {
    if (isLoadingUsers) {
      return Center(child: CircularProgressIndicator());
    }

    if (usersError != null) {
      return Center(
        child: Text(usersError!, style: TextStyle(color: Colors.red)),
      );
    }

    if (fetchedUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "कोई पदाधिकारी नहीं मिला",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: fetchedUsers.length,
      itemBuilder: (context, index) {
        final user = fetchedUsers[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                '${Constants.storageUrl}/${user["profile_photo"]}' ?? "",
              ),
              onBackgroundImageError: (_, __) {},
              child: user["profile_photo"]?.isEmpty ?? true
                  ? Icon(Icons.person)
                  : null,
            ),
            title: Text(
              user["name"] ?? "Unknown",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              "पद स्तर: ${user["position"] ?? ""}, पद नाम: ${user["designation"] ?? ""}",
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserDetailsScreen(user: user),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
