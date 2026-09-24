import 'package:cgks/dto/register_user_dto.dart';
import 'package:cgks/models/user.dart';
import 'package:cgks/models/contact_details.dart';
import 'package:cgks/models/app_banner.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

class ApiService {
  // final String baseUrl = "http://10.0.2.2:8000/api"; // replace with your IP
  final String baseUrl =
      "https://chhattisgarhiyakrantisena.com/api";

  // Timeout duration for HTTP requests
  static const Duration timeout = Duration(seconds: 30);

  Future<List<dynamic>> getAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final userString = prefs.getString("user");

      if (token == null || token.isEmpty) {
        throw Exception("No token found. Please login again.");
      }

      String userId = '';
      if (userString != null) {
        final user = jsonDecode(userString); // Map<String, dynamic>
        userId = user['id'].toString(); // Ensure it's a string
      }

      final response = await http
          .post(
            Uri.parse("$baseUrl/users/all"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({'user': userId}), // ✅ Encode as JSON
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['users'] != null) {
          return List<dynamic>.from(data['users']);
        } else {
          return [];
        }
      } else if (response.statusCode == 401) {
        throw Exception("Session expired. Please login again.");
      } else {
        throw Exception("Failed to fetch all users: ${response.body}");
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
          "Network error. Please check your internet connection.",
        );
      } else if (e is FormatException) {
        throw Exception("Invalid response format from server.");
      } else {
        rethrow;
      }
    }
  }

  Future<List<dynamic>> getUserByPosition(String position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null || token.isEmpty) {
        throw Exception("No token found. Please login again.");
      }

      final response = await http
          .post(
            Uri.parse("$baseUrl/user/by-position"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({"position": position}),
          )
          .timeout(timeout);
      debugPrint(response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['users'] != null) {
          return List<dynamic>.from(data['users']);
        } else {
          return [];
        }
      } else if (response.statusCode == 401) {
        throw Exception("Session expired. Please login again.");
      } else {
        throw Exception("Failed to fetch users by position: ${response.body}");
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
          "Network error. Please check your internet connection.",
        );
      } else if (e is FormatException) {
        throw Exception("Invalid response format from server.");
      } else {
        rethrow;
      }
    }
  }

  Future<List<dynamic>> getUserByDesignation(String designation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null || token.isEmpty) {
        throw Exception("No token found. Please login again.");
      }

      final response = await http
          .post(
            Uri.parse("$baseUrl/user/by-designation"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({"designation": designation}),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['users'] != null) {
          return List<dynamic>.from(data['users']);
        } else {
          return [];
        }
      } else if (response.statusCode == 401) {
        throw Exception("Session expired. Please login again.");
      } else {
        throw Exception(
          "Failed to fetch users by designation: ${response.body}",
        );
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
          "Network error. Please check your internet connection.",
        );
      } else if (e is FormatException) {
        throw Exception("Invalid response format from server.");
      } else {
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null || token.isEmpty) {
        throw Exception("No token found. Please login again.");
      }

      final response = await http
          .get(
            Uri.parse("$baseUrl/user/profile"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        throw Exception("Session expired. Please login again.");
      } else {
        throw Exception("Failed to fetch user profile: ${response.body}");
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
          "Network error. Please check your internet connection.",
        );
      } else if (e is FormatException) {
        throw Exception("Invalid response format from server.");
      } else {
        rethrow;
      }
    }
  }

  // User Login and Session
  Future<Map<String, dynamic>> loginUser(String mobile, String password) async {
    try {
      // Input validation
      if (mobile.trim().isEmpty || password.isEmpty) {
        throw Exception("Mobile and password are required");
      }

      final response = await http
          .post(
            Uri.parse("$baseUrl/login"),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({"mobile": mobile.trim(), "password": password}),
          )
          .timeout(timeout);

      final Map<String, dynamic> data = jsonDecode(response.body);

      // Handle different status codes
      switch (response.statusCode) {
        case 200:
          final token = data['token'];
          final user = data['user'];

          if (token == null || user == null) {
            throw Exception("Invalid server response");
          }

          // Save to preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("token", token);
          await prefs.setString("user", jsonEncode(user));
          await prefs.setBool("logged_in", true);

          return {"token": token, "user": user};

        case 401:
          throw Exception(data['message'] ?? "Invalid credentials");

        case 422:
          throw Exception(data['message'] ?? "Invalid input");

        case 429:
          throw Exception("Too many attempts. Try again later");

        default:
          throw Exception(data['message'] ?? "Login failed");
      }
    } on SocketException {
      throw Exception("No internet connection");
    } on FormatException {
      throw Exception("Invalid server response");
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logoutUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try to call logout endpoint if token exists
      final token = prefs.getString("token");
      if (token != null && token.isNotEmpty) {
        try {
          await http
              .post(
                Uri.parse("$baseUrl/logout"),
                headers: {
                  "Content-Type": "application/json",
                  "Authorization": "Bearer $token",
                },
              )
              .timeout(Duration(seconds: 10)); // Shorter timeout for logout
        } catch (e) {
          debugPrint("Logout endpoint failed: $e");
          // Continue with local logout even if server logout fails
        }
      }

      // Clear local storage
      await prefs.clear();
    } catch (e) {
      debugPrint("Logout error: $e");
      // Even if there's an error, try to clear local storage
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } catch (clearError) {
        debugPrint("Failed to clear preferences: $clearError");
      }
    }
  }

  Future<List<String>> getPositions() async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/positions"),
            headers: {"Content-Type": "application/json"},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item['name'].toString()).toList();
      } else {
        throw Exception("Failed to fetch positions");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getDesignations() async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/designations"),
            headers: {"Content-Type": "application/json"},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item['name'].toString()).toList();
      } else {
        throw Exception("Failed to fetch designations");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<User> registerUser(RegisterUserDTO dto) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/user/register"),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode(dto.toJson()),
          )
          .timeout(timeout);
      debugPrint("Status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      final data = jsonDecode(response.body);
      debugPrint("Registration Response: $data");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint("Registration Response: $data");
        final token = data['token'];
        final user = data['user'];

        if (data['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("token", token);
          await prefs.setString("user", jsonEncode(user));
          await prefs.setBool("logged_in", true);

          debugPrint("User Data: $user");
          return User.fromJson(data['user']);
        } else {
          throw Exception("Invalid response: missing user data");
        }
      } else if (response.statusCode == 422) {
        throw Exception("Referral Code Not Valid");
      } else {
        String errorMessage = "Registration failed. Please try again.";
        if (data['error'] != null &&
            data['error']['mobile'] != null &&
            data['error']['mobile'].isNotEmpty) {
          errorMessage = data['error']['mobile'][0];
        } else if (data['message'] != null) {
          errorMessage = data['message'];
        }

        // ❌ don’t return null, throw instead
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<List<String>> fetchAllDistricts() async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/districts"),
            headers: {"Content-Type": "application/json"},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded["status"] == "success" && decoded["data"] != null) {
          // Extract only names and ensure they're strings
          final districts = List<String>.from(
            decoded["data"]
                .where((d) => d != null && d["name"] != null)
                .map((d) => d["name"].toString())
                .where((name) => name.isNotEmpty),
          );

          // Remove duplicates and sort
          final uniqueDistricts = districts.toSet().toList();
          uniqueDistricts.sort();

          return uniqueDistricts;
        } else {
          throw Exception("Invalid response format: missing data");
        }
      } else if (response.statusCode == 404) {
        throw Exception("Districts endpoint not found");
      } else {
        throw Exception("Failed to fetch districts: ${response.statusCode}");
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
          "Network error. Please check your internet connection.",
        );
      } else if (e is FormatException) {
        throw Exception("Invalid response format from server.");
      } else {
        rethrow;
      }
    }
  }

  Future<User> getReferredCodeUser(String code) async {
    try {
      final normalizedCode = code.trim();

      if (normalizedCode.isEmpty) {
        throw Exception("Referral code cannot be empty");
      }

      final url = Uri.parse("$baseUrl/user/referral/get");

      debugPrint("➡️ Request URL: $url");
      debugPrint(
        "➡️ Request Body: ${jsonEncode({"referral_code": normalizedCode})}",
      );

      final response = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json", // 👈 important
            },
            body: jsonEncode({"referral_code": normalizedCode}),
          )
          .timeout(timeout);

      debugPrint("⬅️ Response Status: ${response.statusCode}");
      debugPrint("⬅️ Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final message = responseData['message'];
        final userData = responseData['user'];

        if (userData == null) {
          throw Exception("Invalid response: missing user data");
        }

        debugPrint("✅ Success Message: $message");
        return User.fromJson(userData);
      } else {
        // ✅ Always give readable error
        String errorMessage = "Something went wrong (${response.statusCode})";

        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'].toString();
          }
        } catch (_) {
          // response was not JSON (likely HTML) → fallback cleanly
          errorMessage = "Server error (${response.statusCode})";
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
          "Network error. Please check your internet connection.",
        );
      } else if (e is FormatException) {
        throw Exception("Invalid response format from server.");
      } else {
        throw Exception(e.toString().replaceFirst("Exception: ", ""));
      }
    }
  }

  // Helper method to check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool("logged_in") ?? false;
      final token = prefs.getString("token");
      return isLoggedIn && token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint("Error checking login status: $e");
      return false;
    }
  }

  // Helper method to get stored user data
  Future<Map<String, dynamic>?> getStoredUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString("user");
      if (userString != null && userString.isNotEmpty) {
        return jsonDecode(userString);
      }
      return null;
    } catch (e) {
      debugPrint("Error getting stored user: $e");
      return null;
    }
  }

  Future<List<dynamic>> getAllAnnouncements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final response = await http
          .post(
            Uri.parse("$baseUrl/announcements"),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        } else {
          throw Exception("Invalid response format: expected a list");
        }
      } else {
        throw Exception(
          "Failed to fetch announcements: ${response.statusCode}",
        );
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
          "Network error. Please check your internet connection.",
        );
      } else if (e is FormatException) {
        throw Exception("Invalid response format from server.");
      } else {
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> getAnnouncementById(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final response = await http
          .post(
            Uri.parse("$baseUrl/announcement/show"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({"id": id}),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        } else {
          throw Exception("Invalid response format: expected a map");
        }
      } else if (response.statusCode == 404) {
        throw Exception("Announcement not found");
      } else {
        throw Exception("Failed to fetch announcement: ${response.statusCode}");
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
          "Network error. Please check your internet connection.",
        );
      } else if (e is FormatException) {
        throw Exception("Invalid response format from server.");
      } else {
        rethrow;
      }
    }
  }

  // Fetch all news
  Future<List<dynamic>> getAllNews() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final response = await http.post(
      Uri.parse("$baseUrl/news"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      debugPrint("News fetch error: ${response.body}");
      throw Exception("Failed to load news");
    }
  }

  Future<List<dynamic>> getAllAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final response = await http.post(
      Uri.parse("$baseUrl/achievements"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      debugPrint("News fetch error: ${response.body}");
      throw Exception("Failed to load news");
    }
  }

  // Fetch single achievement by ID
  Future<Map<String, dynamic>> getAchievementDetails(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final response = await http.post(
      Uri.parse("$baseUrl/achievement/show"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"id": id}),
    );

    debugPrint(
      "Achievement Detail Response: ${response.statusCode} - ${response.body}",
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        "Failed to load achievement detail: ${response.statusCode} - ${response.body}",
      );
    }
  }

  // Fetch single news by ID
  Future<Map<String, dynamic>> getNewsDetail(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final response = await http.post(
      Uri.parse("$baseUrl/news/show"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"id": id}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load news detail");
    }
  }

  Future<bool> sendResetLink(String email) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/forgot-password"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"email": email}),
      );

      debugPrint("Forgot Password Response: ${response.body}");

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? "Failed to send reset link");
      }
    } catch (e) {
      debugPrint("Error sending reset link: $e");
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // LIKES API
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> toggleLike(int postId, String tableName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.post(
      Uri.parse("$baseUrl/likes/toggle"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"post_id": postId, "table_name": tableName}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to toggle like: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getLikeStatus(
    int postId,
    String tableName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    // Token is optional for status, but good to send if available
    final headers = {"Content-Type": "application/json"};
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }

    final response = await http.post(
      Uri.parse("$baseUrl/likes/status"),
      headers: headers,
      body: jsonEncode({"post_id": postId, "table_name": tableName}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to get like status: ${response.body}");
    }
  }

  // ---------------------------------------------------------------------------
  // COMMENTS API
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> getComments(int postId, String tableName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.post(
      Uri.parse("$baseUrl/comments"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"post_id": postId, "table_name": tableName}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch comments: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> addComment(
    int postId,
    String tableName,
    String commentText,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.post(
      Uri.parse("$baseUrl/comments/store"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "post_id": postId,
        "table_name": tableName,
        "comment_text": commentText,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to add comment: ${response.body}");
    }
  }

  // ---------------------------------------------------------------------------
  // CONTACT DETAILS API
  // ---------------------------------------------------------------------------

  Future<ContactDetails> fetchContactDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      debugPrint("Fetching contact details from: $baseUrl/contact-details");
      final response = await http
          .post(
            Uri.parse("$baseUrl/contact-details"),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(timeout);

      debugPrint(
        "Contact Details Response: ${response.statusCode} - ${response.body}",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ContactDetails.fromJson(data);
      } else {
        throw Exception(
          "Failed to fetch contact details: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      debugPrint("Error fetching contact details: $e");

      if (e is SocketException) {
        throw Exception(
          "Network error. Please check your internet connection.",
        );
      } else if (e is FormatException) {
        throw Exception("Invalid response format from server.");
      } else {
        rethrow;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // LIVE VIDEO API
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getLiveVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("$baseUrl/live-video"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    debugPrint(
      "Live Video Response: ${response.statusCode} - ${response.body}",
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Expected format: { "data": [ { "video_id": "...", "title": "..." }, ... ] }
      // Or just a list [ ... ]

      List<dynamic> videoList = [];
      if (data is List) {
        videoList = data;
      } else if (data['data'] is List) {
        videoList = data['data'];
      } else if (data['video_id'] != null) {
        // Single video fallback
        videoList = [data];
      }

      return videoList.map((v) => Map<String, dynamic>.from(v)).toList();
    } else {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // SHORTS / REELS API
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getShorts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    // Assuming endpoint is /shorts
    final response = await http.get(
      Uri.parse("$baseUrl/shorts"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Expected format: { "data": [ { "url": "...", "type": "youtube|instagram", ... }, ... ] }

      List<dynamic> shortsList = [];
      if (data is List) {
        shortsList = data;
      } else if (data['data'] is List) {
        shortsList = data['data'];
      }

      return shortsList.map((v) => Map<String, dynamic>.from(v)).toList();
    } else {
      // Return empty list on error or 404
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // CATEGORY API
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> getNewsCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    // Corrected endpoint based on user input: categories/{type}
    final url = Uri.parse("$baseUrl/categories/news");
    debugPrint("Fetching News Categories: $url");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint(
        "News Categories Response: ${response.statusCode} - ${response.body}",
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          "Failed to load news categories: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("Error fetching news categories: $e");
      rethrow;
    }
  }

  Future<List<dynamic>> getAnnouncementCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    // Corrected endpoint based on user input: categories/{type}
    final url = Uri.parse("$baseUrl/categories/announcement");
    debugPrint("Fetching Announcement Categories: $url");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint(
        "Announcement Categories Response: ${response.statusCode} - ${response.body}",
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          "Failed to load announcement categories: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("Error fetching announcement categories: $e");
      rethrow;
    }
  }

  Future<List<dynamic>> getAchievementCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    // Corrected endpoint based on user input: categories/{type}
    final url = Uri.parse("$baseUrl/categories/achievement");
    debugPrint("Fetching Achievement Categories: $url");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint(
        "Achievement Categories Response: ${response.statusCode} - ${response.body}",
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          "Failed to load achievement categories: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("Error fetching achievement categories: $e");
      rethrow;
    }
  }

  Future<List<dynamic>> getNewsByCategory(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final response = await http.post(
      Uri.parse("$baseUrl/news/category"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"category_id": categoryId}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load news by category");
    }
  }

  Future<List<dynamic>> getAnnouncementsByCategory(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final response = await http.post(
      Uri.parse("$baseUrl/announcements/category"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"category_id": categoryId}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load announcements by category");
    }
  }

  Future<List<dynamic>> getAchievementsByCategory(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final response = await http.post(
      Uri.parse("$baseUrl/achievements/category"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"category_id": categoryId}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load achievements by category");
    }
  }

  Future<List<AppBannerModel>> getAppBanners() async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/app-banners"))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => AppBannerModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching app banners: $e");
      }
      return [];
    }

  }
}
