//   runApp(DevicePreview(enabled: !kReleaseMode, builder: (context) => MyApp()));

// main.dart
//TODO: notfication fillter
//TODO: application meeting
// TODO: like view extra

// TODO : sort notitification  time

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillmatch_platform/firebase_options.dart';
import 'package:skillmatch_platform/services/fcm_service.dart';
import 'package:skillmatch_platform/utils/app_lifecycle_manager.dart';
import 'package:skillmatch_platform/utils/push_notifications_firebase.dart';
import 'package:skillmatch_platform/utils/theme/app_theme.dart';
import 'package:skillmatch_platform/widgets/admin/adminDashboard.dart';
import 'package:skillmatch_platform/widgets/admin/web_admin_dashboard.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/web_home_page.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/organization_home_page.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/web_organization_home_page.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/jobs_screen_tabs/job_details_screen.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/mesage_profile.dart';
import 'package:skillmatch_platform/widgets/appSetting/theremeProv.dart';
import 'package:skillmatch_platform/widgets/sign_up_widgets/account_created_screen.dart';
import 'package:skillmatch_platform/widgets/applicatin_startup/startup_page.dart';
import 'package:skillmatch_platform/widgets/applicatin_startup/web_startup_page.dart';
import 'package:skillmatch_platform/widgets/sign_up_widgets/signup_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:io';

final logger = Logger();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Future _firebaseBackgroundMessage(RemoteMessage message) async {
//   if (message.notification != null) {
//     logger.i('Notification receivedaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
//   }
// }
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  PushNotificationsFirebase.handleBackgroundMessage(message);
}

Future<void> requestPermissions() async {
  if (kIsWeb) return;
  await [Permission.microphone, Permission.camera].request();
}

Future<bool> validateToken(String token) async {
  try {
    // Check if token is empty or null
    if (token.isEmpty) {
      logger.w("Empty token provided");
      return false;
    }

    // Basic JWT structure validation
    final parts = token.split('.');
    if (parts.length != 3) {
      logger.w("Invalid JWT structure - parts: ${parts.length}");
      return false;
    }

    // Try to decode the token to check if it's valid
    try {
      final payload = parts[1];
      // Add padding if needed
      String normalizedPayload = payload;
      switch (payload.length % 4) {
        case 1:
          normalizedPayload += '===';
          break;
        case 2:
          normalizedPayload += '==';
          break;
        case 3:
          normalizedPayload += '=';
          break;
      }

      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      final Map<String, dynamic> payloadMap = jsonDecode(decoded);

      // Check if token has expired
      if (payloadMap.containsKey('exp')) {
        final exp = payloadMap['exp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (exp < now) {
          logger.w("Token has expired - exp: $exp, now: $now");
          return false;
        }
      }

      // For mobile compatibility: Try server validation but don't fail if it doesn't work
      final baseUrl = dotenv.env['BASE_URL'];
      if (baseUrl != null && baseUrl.isNotEmpty) {
        try {
          final response = await http
              .get(
                Uri.parse("$baseUrl/auth/validate-token"),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              )
              .timeout(const Duration(seconds: 5)); // Shorter timeout

          if (response.statusCode == 200) {
            logger.i("✅ Token validated successfully with server");
            return true;
          } else if (response.statusCode == 404) {
            // Endpoint doesn't exist - fall back to local validation
            logger.i(
              "🔄 Server validation endpoint not found, using local validation",
            );
            return true; // Token structure is valid
          } else {
            logger.w(
              "⚠️ Server token validation failed: ${response.statusCode}",
            );
            return false;
          }
        } catch (e) {
          // Network error or timeout - fall back to local validation for mobile compatibility
          logger.i(
            "🔄 Server validation failed (${e.toString().substring(0, 50)}...), using local validation",
          );
          return true; // Token structure is valid, assume it's good
        }
      }

      // If no server validation available, token structure is valid
      logger.i("✅ Token structure valid, no server validation available");
      return true;
    } catch (e) {
      logger.e("❌ Token decoding failed: $e");
      return false;
    }
  } catch (e) {
    logger.e("❌ Token validation error: $e");
    return false;
  }
}

void main() async {
  await dotenv.load(fileName: "api.env");

  WidgetsFlutterBinding.ensureInitialized();
  await requestPermissions();
  try {
    if (DefaultFirebaseOptions.isConfigured) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      logger.i("Firebase initialized successfully");
    } else {
      logger.i(
        "Firebase skipped: configure lib/firebase_options.dart with your project values.",
      );
    }

    if (!kIsWeb && DefaultFirebaseOptions.isConfigured) {
      await PushNotificationsFirebase.init();
      logger.i("Push Notifications initialized");
    } else {
      logger.i("Push Notifications skipped on web");
    }
  } catch (e) {
    logger.e("Error initializing Firebase", error: e);
  }

  if (!kIsWeb && DefaultFirebaseOptions.isConfigured) {
    FirebaseMessaging.instance.getToken().then((token) async {
      logger.i("Current FCM Token: $token");
    });
  }

  if (!kIsWeb && DefaultFirebaseOptions.isConfigured) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  final prefs = await SharedPreferences.getInstance();
  final storedToken = prefs.getString('token');
  final storedRole = prefs.getString('role');
  final storedUserId = prefs.getString('userId');
  final storedUsername = prefs.getString('username');

  bool isValidToken = false;

  logger.i("🔍 Checking stored authentication data...");
  logger.i("Token exists: ${storedToken != null && storedToken.isNotEmpty}");
  logger.i("UserId: $storedUserId");
  logger.i("Role: $storedRole");

  if (storedToken != null && storedToken.isNotEmpty) {
    try {
      logger.i("🔐 Validating stored token...");
      isValidToken = await validateToken(storedToken);
      logger.i("Token validation result: $isValidToken");
    } catch (e) {
      logger.e("Token validation failed: $e");
      isValidToken = false;
    }

    // If token is invalid, clear all stored data
    if (!isValidToken) {
      logger.w("🧹 Invalid token detected, clearing all stored data...");
      await prefs.clear();
      logger.i("✅ Stored data cleared due to invalid token");
    }
  } else {
    logger.i("ℹ️ No stored token found");
  }

  logger.i("🚀 Starting app with login status: $isValidToken");

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(
        isLoggedIn: isValidToken,
        userToken: isValidToken ? storedToken : null,
        userRole: isValidToken ? storedRole : null,
        userId: isValidToken ? storedUserId : null,
        username: isValidToken ? storedUsername : null,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? userId;
  final String? token;
  final bool isLoggedIn;
  final String? userToken;
  final String? userRole;
  final String? username;

  const MyApp({
    this.userId,
    this.token,
    super.key,
    required this.isLoggedIn,
    this.userToken,
    this.userRole,
    this.username,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(
      context,
    ); // <-- Add this line

    return MaterialApp(
      title: 'SkillMatch Platform',
      navigatorKey: navigatorKey,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: AppLifecycleManager(
            userId: userId,
            token: token,
            child: child!,
          ),
        );
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/signup') {
          final args = settings.arguments as Map<String, String>?;

          if (args == null ||
              !args.containsKey('country') ||
              !args.containsKey('date') ||
              !args.containsKey('city') ||
              !args.containsKey('gender') ||
              !args.containsKey('role')) {
            throw ArgumentError("Missing required arguments for SignUpScreen.");
          }

          return MaterialPageRoute(
            builder:
                (context) => SignUpScreen(
                  country: args['country']!,
                  date: args['date']!,
                  city: args['city']!,
                  gender: args['gender']!,
                  userRole: args['role']!,
                ),
          );
        } else if (settings.name == '/account-created') {
          return MaterialPageRoute(
            builder: (context) => AccountCreatedScreen(),
          );
        } else if (settings.name == '/job') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder:
                (context) =>
                    JobDetailsScreen(job: args['job'], token: args['token']),
          );
        }
        return null;
      },
      routes: {
        '/':
            (context) =>
                isLoggedIn
                    ? (userRole == 'admin'
                        ? (kIsWeb
                            ? WebAdminDashboard(token: userToken ?? '')
                            : AdminDashboard(token: userToken ?? ''))
                        : userRole == 'Organization' ||
                            userRole == 'organization'
                        ? (kIsWeb
                            ? WebOrganizationHomePage(token: userToken ?? '')
                            : OrganizationHomePage(token: userToken ?? ''))
                        : (kIsWeb
                            ? WebHomePage(
                              data: userToken ?? '',
                              onTokenChanged: (String userToken) => userToken,
                            )
                            : HomePage(
                              data: userToken ?? '',
                              onTokenChanged: (String userToken) => userToken,
                            )))
                    : (kIsWeb ? const WebStartupPage() : const StartupPage()),
        '/chat': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments as Map<String, String>;
          return ChatPage(
            currentUserId: args['currentUserId'] ?? '',
            peerUserId: args['peerUserId'] ?? '',
            peerUsername: args['peerUsername'] ?? '',
            currentuserAvatarUrl: args['currentuserAvatarUrl'] ?? '',
            token: args['token'] ?? '',
            onChatClosed: () {},
          );
        },
      },
    );
  }
}
