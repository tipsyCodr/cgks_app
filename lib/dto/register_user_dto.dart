// DTO for registration (data you send to API)
import 'package:cgks/features/auth/controllers/register_form_controllers.dart';

class RegisterUserDTO {
  final String name;
  final String? name2;
  final String mobileNumber;
  final String? district;
  final String? city;
  final String? email;
  final String? address;
  final String? currentAddress;
  final String? occupation;
  final String? whatsapp;
  final String? referralCode;
  final String password;

  RegisterUserDTO({
    required this.name,
    this.name2,
    required this.mobileNumber,
    required this.email,
    required this.address,
    required this.currentAddress,
    required this.occupation,
    required this.district,
    required this.city,
    required this.whatsapp,
    required this.referralCode,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "name2": name2,
      "district": district,
      "city": city,
      "email": email,
      "address": address,
      "currentAddress": currentAddress,
      "occupation": occupation,
      "whatsapp": whatsapp,
      "referral_code": referralCode,
      "password": password,
      "mobile": mobileNumber,
    };
  }

  /// Factory to build from form controllers
  factory RegisterUserDTO.fromControllers(RegisterFormControllers form) {
    final normalizedReferralCode = form.referralCode.text.trim();
    final name2Text = form.name2.text.trim();

    return RegisterUserDTO(
      name: form.name.text,
      name2: name2Text.isEmpty ? null : name2Text,
      mobileNumber: form.mobile.text,
      password: form.password.text,
      district: form.district.text,
      city: form.city.text,
      email: form.email.text,
      address: form.address.text,
      currentAddress: form.currentAddress.text,
      occupation: form.occupation.text,
      whatsapp: form.whatsapp.text,
      referralCode:
          normalizedReferralCode.isEmpty ? null : normalizedReferralCode,
    );
  }
}
