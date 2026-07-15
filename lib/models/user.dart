class User {
  final int id;
  final String name;
  final String mobile;
  final String district;
  final String city;
  final String? position;
  final String? designation;

  User({
    required this.id,
    required this.mobile,
    required this.name,
    required this.district,
    required this.city,
    required this.position,
    required this.designation,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? "",
      mobile: json['mobile']?.toString() ?? "",
      district: json['district'] ?? "",
      city: json['city'] ?? "",
      position: json['position'] ?? "",
      designation: json['designation'] ?? "",
    );
  }
}
