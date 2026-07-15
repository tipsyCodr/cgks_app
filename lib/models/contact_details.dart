class ContactDetails {
  final String? mobile;
  final String? email;
  final String? address;
  final String? qrCode;

  ContactDetails({this.mobile, this.email, this.address, this.qrCode});

  factory ContactDetails.fromJson(Map<String, dynamic> json) {
    return ContactDetails(
      mobile: json['mobile_no'],
      email: json['email'],
      address: json['address'],
      qrCode: json['qr_code'],
    );
  }
}
