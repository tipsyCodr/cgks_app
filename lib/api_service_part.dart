//   // ---------------------------------------------------------------------------
//   // CONTACT DETAILS API
//   // ---------------------------------------------------------------------------

//   Future<ContactDetails> fetchContactDetails() async {
//     try {
//       final response = await http
//           .get(
//             Uri.parse("$baseUrl/contact-details"),
//             headers: {"Content-Type": "application/json"},
//           )
//           .timeout(timeout);

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return ContactDetails.fromJson(data);
//       } else {
//         throw Exception("Failed to fetch contact details: ${response.body}");
//       }
//     } catch (e) {
//       if (e is SocketException) {
//         throw Exception(
//           "Network error. Please check your internet connection.",
//         );
//       } else if (e is FormatException) {
//         throw Exception("Invalid response format from server.");
//       } else {
//         rethrow;
//       }
//     }
//   }
// }
