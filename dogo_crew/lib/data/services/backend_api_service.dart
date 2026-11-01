import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendApiService {
  // Replace with Danny's live backend URL (e.g. https://api.dogo.app or Render / Railway URL)
  static String baseUrl = 'https://api.dogo.app';

  static String? _cachedAccessToken;

  /// Sets or updates the backend base URL dynamically
  static void setBaseUrl(String url) {
    var cleaned = url.trim();
    if (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    baseUrl = cleaned;
  }

  /// Submits an agent clearance application adhering to Danny26y/DOGO-APP API contract:
  /// 1. Registers / signs in user via POST /api/v1/auth/register or /login
  /// 2. Updates name and phone via PATCH /api/v1/users/me
  /// 3. Submits application via POST /api/v1/delivery/agents/apply
  static Future<Map<String, dynamic>?> submitDeliveryAgentApplication({
    required String agentType, // 'driver' or 'rider'
    required String fullName,
    required String phone,
    required String email,
    String password = 'Password@123!',
  }) async {
    try {
      final token = await _ensureUserToken(email: email, password: password);
      if (token == null) return null;

      // Complete name & phone on profile
      final profileUri = Uri.parse('$baseUrl/api/v1/users/me');
      await http.patch(
        profileUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'full_name': fullName,
          'phone': phone,
        }),
      );

      // Submit application
      final applyUri = Uri.parse('$baseUrl/api/v1/delivery/agents/apply');
      final applyRes = await http.post(
        applyUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'agent_type': agentType,
        }),
      );

      if (applyRes.statusCode == 200 || applyRes.statusCode == 201) {
        return json.decode(applyRes.body) as Map<String, dynamic>;
      } else if (applyRes.statusCode == 409) {
        // Application already exists
        return {'status': 'pending', 'message': 'Application already exists'};
      }
    } catch (_) {}
    return null;
  }

  /// Checks clearance status from Danny's backend via GET /api/v1/delivery/me
  static Future<String?> checkClearanceStatus({String? email, String password = 'Password@123!'}) async {
    try {
      String? token = _cachedAccessToken;
      if (token == null && email != null) {
        token = await _ensureUserToken(email: email, password: password);
      }
      if (token == null) return null;

      final uri = Uri.parse('$baseUrl/api/v1/delivery/me');
      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(res.body);
        if (list.isNotEmpty) {
          final first = list.first as Map<String, dynamic>;
          return first['status'] as String?; // 'pending', 'active', 'suspended'
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _ensureUserToken({required String email, required String password}) async {
    if (_cachedAccessToken != null) return _cachedAccessToken;

    try {
      // 1. Try registering
      final regUri = Uri.parse('$baseUrl/api/v1/auth/register');
      final regRes = await http.post(
        regUri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (regRes.statusCode == 201 || regRes.statusCode == 200) {
        final data = json.decode(regRes.body) as Map<String, dynamic>;
        _cachedAccessToken = data['access_token'] as String?;
        return _cachedAccessToken;
      }

      // 2. If already registered, log in
      final loginUri = Uri.parse('$baseUrl/api/v1/auth/login');
      final loginRes = await http.post(
        loginUri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (loginRes.statusCode == 200) {
        final data = json.decode(loginRes.body) as Map<String, dynamic>;
        _cachedAccessToken = data['access_token'] as String?;
        return _cachedAccessToken;
      }
    } catch (_) {}
    return null;
  }
}
