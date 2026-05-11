//new api all fixed i used api.env

import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

final String baseUrl = dotenv.env['BASE_URL']!;

class FCMService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _logger = Logger();

  /// Nuclear reset for FCM tokens
  Future<void> nuclearReset() async {
    _logger.i('💣 Initiating FCM nuclear reset...');

    // 1. Force unregister
    await _fcm.deleteToken();

    // 2. Clear cached FCM data
    await Firebase.app().delete();
    await Firebase.initializeApp();

    // 3. Get fresh token
    String? newToken = await _fcm.getToken();
    _logger.i('💥 NEW TOKEN: $newToken');

    // 4. Validate token
    if (newToken == null || !newToken.startsWith('APA')) {
      throw Exception('Invalid token generated');
    }

    // 5. Send to backend
    await sendTokenToServer(newToken);
  }

  /// Send FCM token to server (for login)
  Future<void> sendTokenToServer(String token) async {
    try {
      _logger.i('📤 Sending FCM token to server...');
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      String? role = prefs.getString('role');

      if (userId == null || role == null) {
        _logger.e('❌ Cannot send FCM token: userId or role is null');
        return;
      }

      final endpoint =
          role == 'Organization'
              ? '$baseUrl/organization/save-fcm-token'
              : '$baseUrl/users/save-fcm-token';

      final body =
          role == 'Organization'
              ? {'organizationId': userId, 'fcmToken': token}
              : {'userId': userId, 'fcmToken': token};

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        _logger.i('✅ FCM token saved successfully for $role');
      } else {
        _logger.e(
          '❌ Failed to save FCM token: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      _logger.e('❌ Error sending FCM token to server:', error: e);
    }
  }

  /// Remove FCM token from server (for logout)
  Future<void> removeTokenFromServer(
    String userId,
    String fcmToken,
    String authToken,
    String role,
  ) async {
    try {
      _logger.i('🗑️ Removing FCM token from server...');

      final endpoint =
          role == 'Organization'
              ? '$baseUrl/organization/remove-fcm-token'
              : '$baseUrl/users/remove-fcm-token';

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'id': userId, 'fcmToken': fcmToken}),
      );

      if (response.statusCode == 200) {
        _logger.i('✅ FCM token removed from server successfully');
      } else {
        _logger.e('❌ Failed to remove FCM token from server: ${response.body}');
      }
    } catch (e) {
      _logger.e('❌ Error removing FCM token from server', error: e);
    }
  }

  /// Complete FCM setup after successful login
  Future<void> setupFCMAfterLogin() async {
    try {
      _logger.i('🔧 Setting up FCM after login...');

      // Get FCM token
      final fcmToken = await _fcm.getToken();
      if (fcmToken != null) {
        _logger.i('🎫 FCM token obtained: ${fcmToken.substring(0, 20)}...');

        // Send to server
        await sendTokenToServer(fcmToken);

        // Store token locally for future reference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', fcmToken);

        _logger.i('✅ FCM setup completed after login');
      } else {
        _logger.w('⚠️ No FCM token available');
      }
    } catch (e) {
      _logger.e('❌ Error setting up FCM after login', error: e);
    }
  }

  /// Complete FCM cleanup before logout
  Future<void> cleanupFCMBeforeLogout() async {
    try {
      _logger.i('🧹 Cleaning up FCM before logout...');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getString('userId');
      final role = prefs.getString('role');

      if (token != null && userId != null && role != null) {
        // Get current FCM token
        final fcmToken = await _fcm.getToken();
        if (fcmToken != null) {
          // Remove from server
          await removeTokenFromServer(userId, fcmToken, token, role);
        }
      }

      // Delete token locally from Firebase
      await _fcm.deleteToken();

      // Remove stored FCM token from SharedPreferences
      await prefs.remove('fcm_token');

      _logger.i('✅ FCM cleanup completed before logout');
    } catch (e) {
      _logger.e('❌ Error cleaning up FCM before logout', error: e);
    }
  }

  /// Get current FCM token
  Future<String?> getCurrentToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      _logger.e('❌ Error getting current FCM token', error: e);
      return null;
    }
  }

  /// Check if FCM token is registered with server
  Future<bool> isTokenRegisteredWithServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('fcm_token');
      final currentToken = await getCurrentToken();

      return storedToken != null && storedToken == currentToken;
    } catch (e) {
      _logger.e('❌ Error checking FCM token registration', error: e);
      return false;
    }
  }

  /// Force refresh FCM token and send to server
  Future<void> refreshAndSendToken() async {
    try {
      _logger.i('🔄 Refreshing FCM token...');

      // Delete old token
      await _fcm.deleteToken();

      // Get new token
      final newToken = await _fcm.getToken();
      if (newToken != null) {
        _logger.i('🆕 New FCM token: ${newToken.substring(0, 20)}...');
        await sendTokenToServer(newToken);
      }
    } catch (e) {
      _logger.e('❌ Error refreshing FCM token', error: e);
    }
  }

  /// Debug method to check FCM token status
  Future<Map<String, dynamic>> debugTokenStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentToken = await getCurrentToken();
      final storedToken = prefs.getString('fcm_token');
      final userId = prefs.getString('userId');
      final role = prefs.getString('role');

      final status = {
        'hasCurrentToken': currentToken != null,
        'currentTokenPrefix': currentToken?.substring(0, 20) ?? 'null',
        'hasStoredToken': storedToken != null,
        'storedTokenPrefix': storedToken?.substring(0, 20) ?? 'null',
        'tokensMatch': currentToken == storedToken,
        'userId': userId ?? 'null',
        'role': role ?? 'null',
        'isUserLoggedIn': userId != null && role != null,
      };

      _logger.i('🔍 FCM Token Debug Status: $status');
      return status;
    } catch (e) {
      _logger.e('❌ Error getting debug status', error: e);
      return {'error': e.toString()};
    }
  }
}
