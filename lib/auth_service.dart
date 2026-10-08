// lib/auth_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final String _baseUrl = 'http://127.0.0.1:8000'; 

  String? _token;
  String? _userRole;
  int? _userId; 

  String? get token => _token;
  String? get userRole => _userRole;
  int? get userId => _userId; 
  bool get isAuthenticated => _token != null;
  
  // Bulletproof JWT Token Decoder that handles standard padding rules correctly
  Map<String, dynamic> _decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      
      // Select the exact payload segment block (Index 1)
      String payloadSource = parts[1];
      
      // Automatically normalize missing Base64 structural character padding elements
      switch (payloadSource.length % 4) {
        case 2: payloadSource += '=='; break;
        case 3: payloadSource += '='; break;
      }
      
      final String decodedJson = utf8.decode(base64Url.decode(payloadSource));
      return jsonDecode(decodedJson);
    } catch (e) {
      print("JWT Parsing Error details tracker failed: $e");
      return {};
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access'];
        
        // Safely extract role parameters right out of the dictionary block array
        final decodedToken = _decodeToken(_token!);
        _userRole = decodedToken['role'] ?? 'student'; 
        _userId = decodedToken['id']; 
        
        await _storage.write(key: 'access_token', value: _token);
        await _storage.write(key: 'refresh_token', value: data['refresh']);
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    _token = null;
    _userRole = null;
    _userId = null;
    notifyListeners();
  }
}
