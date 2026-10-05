import 'package:flutter/material.dart';

class RegisterFormControllers {
  final name = TextEditingController();
  final name2 = TextEditingController();
  final mobile = TextEditingController();
  final email = TextEditingController();
  final district = TextEditingController();
  final city = TextEditingController();

  final address = TextEditingController();
  final currentAddress = TextEditingController();
  final occupation = TextEditingController();
  final whatsapp = TextEditingController();
  final referralCode = TextEditingController();

  final password = TextEditingController();
  final confPassword = TextEditingController();

  void dispose() {
    name.dispose();
    name2.dispose();
    mobile.dispose();
    email.dispose();
    district.dispose();
    city.dispose();
    address.dispose();
    currentAddress.dispose();
    occupation.dispose();
    whatsapp.dispose();
    referralCode.dispose();
    password.dispose();
    confPassword.dispose();
  }
}
