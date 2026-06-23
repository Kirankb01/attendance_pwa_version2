import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AgentApiService {
  // Use relative path in production (to utilize Vercel's proxy) and full URL in debug
  static const String baseUrl = kReleaseMode ? '' : 'https://janathamilk.momsuat.com';
  
  String? _apiToken;

  /// Authenticate and get the API token
  Future<bool> login() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/method/api_janatha.api.user.login'),
        body: {
          'username': 'ashkar.vk@example.com',
          'password': 'frappe@123',
        },
      );

      if (response.statusCode == 200) {
        // Extract the token from the JSON response
        final responseData = jsonDecode(response.body);
        if (responseData['token'] != null) {
          _apiToken = responseData['token'];
        }
        return true;
      } else {
        print('Login failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error during login: $e');
      return false;
    }
  }

  /// Register agent with dummy data for other fields
  Future<bool> registerAgent({required String agentName, required String city}) async {
    // If not logged in or no token, attempt to login first
    if (_apiToken == null || _apiToken!.isEmpty) {
      final loggedIn = await login();
      if (!loggedIn) return false;
    }

    try {
      final url = Uri.parse('$baseUrl/api/method/api_janatha.api.agent_register.make_agent_register');
      
      final Map<String, dynamic> payload = {
        "args": {
          "user_id": "ashkar.vk@example.com",
          "name": "",
          "agent_name": agentName,
          "latitude": "9.08",
          "longitude": "90.20",
          "posting_date": "2021-02-03",
          "agent_category": "Milk Booth",
          "mobile_no": "9778833744",
          "whats_app_no": "9778833744",
          "address_line_1": "address 1",
          "address_line_2": "address 2",
          "city": city,
          "state": "Kerala",
          "country": "India",
          "postal_code": "678993",
          "status": "Active"
        }
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_apiToken != null && _apiToken!.isNotEmpty)
            'Authorization': 'Basic $_apiToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('Agent registered successfully: ${response.body}');
        return true;
      } else {
        print('Failed to register agent. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error during agent registration: $e');
      return false;
    }
  }
}
