import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';
import 'package:skillmatch_platform/widgets/applicatin_startup/startup_page.dart';
import 'package:skillmatch_platform/widgets/applicatin_startup/web_startup_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:skillmatch_platform/services/fcm_service.dart';
import 'dart:convert';

class AuthUtils {
  static final Logger _logger = Logger();
  static final String baseUrl = dotenv.env['BASE_URL']!;

  /// Complete logout function that clears all data and navigates to startup
  static Future<void> performCompleteLogout(BuildContext context) async {
    try {
      _logger.i("🚪 Starting complete logout process...");
      _logger.i("📱 Platform: ${kIsWeb ? 'Web' : 'Mobile'}");

      final prefs = await SharedPreferences.getInstance();

      // Get current state for FCM token removal
      final token = prefs.getString('token');
      final userId = prefs.getString('userId');
      final role = prefs.getString('role');

      _logger.i(
        "📊 Current state - Token: ${token != null ? 'exists' : 'null'}, UserId: $userId, Role: $role",
      );

      // Step 1: Clean up FCM tokens using the enhanced FCM service
      try {
        final fcmService = FCMService();
        await fcmService.cleanupFCMBeforeLogout();
      } catch (e) {
        _logger.e("❌ Error during FCM cleanup: $e");
        // Continue with logout even if FCM cleanup fails
      }

      // Step 2: Clear ALL SharedPreferences
      await prefs.clear();
      _logger.i(
        "🧹 All SharedPreferences cleared (including interface preference)",
      );

      // Verify cleanup
      final verifyToken = prefs.getString('token');
      final verifyUserId = prefs.getString('userId');
      _logger.i(
        "✅ Verification - Token: ${verifyToken ?? 'null'}, UserId: ${verifyUserId ?? 'null'}",
      );

      if (context.mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Logged out successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to appropriate startup page
        _logger.i("🏠 Navigating to startup page...");
        try {
          if (kIsWeb) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const WebStartupPage()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const StartupPage()),
              (route) => false,
            );
          }
          _logger.i("✅ Navigation completed successfully");
        } catch (navError) {
          _logger.e("❌ Navigation error: $navError");
          // Fallback navigation for mobile
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      }

      _logger.i("🎉 Complete logout process finished successfully");
    } catch (e) {
      _logger.e("❌ Error during complete logout: $e");

      // Emergency cleanup
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // Emergency FCM cleanup
        try {
          await FirebaseMessaging.instance.deleteToken();
        } catch (fcmError) {
          _logger.w("⚠️ Emergency FCM cleanup failed: $fcmError");
        }

        _logger.i("🆘 Emergency cleanup completed");
      } catch (cleanupError) {
        _logger.e("💥 Emergency cleanup failed: $cleanupError");
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Logout completed with some errors'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );

        // Still navigate even if there were errors
        try {
          if (kIsWeb) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const WebStartupPage()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const StartupPage()),
              (route) => false,
            );
          }
        } catch (navError) {
          _logger.e("❌ Emergency navigation error: $navError");
          // Last resort - use named route
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      }
    }
  }

  /// Setup FCM after successful login
  static Future<void> setupFCMAfterLogin() async {
    try {
      _logger.i("🔧 Setting up FCM after login...");
      final fcmService = FCMService();
      await fcmService.setupFCMAfterLogin();
    } catch (e) {
      _logger.e("❌ Error setting up FCM after login: $e");
    }
  }

  /// Check if user is currently logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getString('userId');

      final hasValidData =
          token != null &&
          token.isNotEmpty &&
          userId != null &&
          userId.isNotEmpty;

      _logger.i("🔍 Login check - Has valid data: $hasValidData");
      return hasValidData;
    } catch (e) {
      _logger.e("❌ Error checking login status: $e");
      return false;
    }
  }

  /// Get current user data
  static Future<Map<String, String?>> getCurrentUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'token': prefs.getString('token'),
        'userId': prefs.getString('userId'),
        'username': prefs.getString('username'),
        'role': prefs.getString('role'),
      };
    } catch (e) {
      _logger.e("❌ Error getting user data: $e");
      return {'token': null, 'userId': null, 'username': null, 'role': null};
    }
  }

  /// Clear all authentication data without navigation
  static Future<void> clearAuthData() async {
    try {
      _logger.i("🧹 Clearing authentication data...");

      // Use enhanced FCM service for cleanup
      final fcmService = FCMService();
      await fcmService.cleanupFCMBeforeLogout();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      _logger.i("✅ Authentication data cleared");
    } catch (e) {
      _logger.e("❌ Error clearing auth data: $e");
    }
  }

  /// Switch user's interface preference
  static Future<void> switchInterfacePreference(String preference) async {
    try {
      _logger.i("🔄 Switching interface preference to: $preference");
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_interface', preference);
      _logger.i("✅ Interface preference updated to: $preference");
    } catch (e) {
      _logger.e("❌ Error switching interface preference: $e");
    }
  }

  /// Get current interface preference
  static Future<String?> getInterfacePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('preferred_interface');
    } catch (e) {
      _logger.e("❌ Error getting interface preference: $e");
      return null;
    }
  }

  /// Check if user prefers web interface
  static Future<bool> prefersWebInterface() async {
    final preference = await getInterfacePreference();
    return preference == 'web';
  }
}
