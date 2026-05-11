// login_page.dart
//new api all fixed i used api.env

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:skillmatch_platform/services/fcm_service.dart';
import 'package:skillmatch_platform/utils/app_lifecycle_manager.dart';
import 'package:skillmatch_platform/utils/network_debug.dart';
import 'package:skillmatch_platform/widgets/admin/adminDashboard.dart';
import 'package:skillmatch_platform/widgets/base_widgets/button.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/organization_home_page.dart';
import 'package:skillmatch_platform/widgets/forget_account_widgets/forgot_account_screen.dart';
import 'package:skillmatch_platform/widgets/sign_up_widgets/sign_up_choose_positions.dart';
import 'package:skillmatch_platform/widgets/base_widgets/text_field.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

final String baseUrl = dotenv.env['BASE_URL']!;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final logger = Logger();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _obscurePassword = true;
  String? errorMessage;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleFcmRecovery() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      logger.i('FCM token is $token');

      if (token != null) {
        final fcmService = FCMService();
        await fcmService.sendTokenToServer(token);
      } else {
        logger.e('FCM token is null');
      }
    } catch (e) {
      logger.e('FCM recovery failed', error: e);
    }
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      logger.i("Starting login process...");
      logger.i("Base URL: $baseUrl");
      logger.i("Email: ${emailController.text}");

      var url = Uri.parse('$baseUrl/auth/login');
      logger.i("Making request to: $url");

      // Create HTTP client with timeout
      final client = http.Client();

      var response = await client
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": emailController.text,
              "password": passwordController.text,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              logger.e("Request timed out after 30 seconds");
              throw Exception(
                "Request timed out. Please check your internet connection.",
              );
            },
          );

      logger.i("Response status code: ${response.statusCode}");
      logger.i("Response body: ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        logger.i("Login successful");

        if (!mounted) return;

        final decodedToken = JwtDecoder.decode(data["token"]);
        final role = decodedToken['role'];
        String userId = decodedToken['id'];
        String username = decodedToken['username'];
        String currentUserAvatarUrl = decodedToken['avatarUrl'] ?? '';

        logger.i(
          "Decoded token - Role: $role, UserId: $userId, Username: $username, Avatar URL: $currentUserAvatarUrl",
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('username');
        await prefs.remove('role');
        await prefs.remove('userId');
        await prefs.remove('avatarUrl');
        await prefs.remove('fcmToken');
        await prefs.setString('token', data['token']);
        await prefs.setString('username', username);
        await prefs.setString('role', role);
        await prefs.setString('userId', userId);
        await prefs.setString('avatarUrl', currentUserAvatarUrl);

        logger.i("Saved user data to SharedPreferences");

        // Handle FCM with timeout and error handling
        try {
          logger.i("Starting FCM recovery...");
          await _handleFcmRecovery().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              logger.w("FCM recovery timed out, continuing without FCM");
              return;
            },
          );
          logger.i("FCM recovery completed");
        } catch (fcmError) {
          logger.w("FCM recovery failed, continuing without FCM: $fcmError");
          // Continue with login even if FCM fails
        }

        logger.i("Navigating to home page...");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => AppLifecycleManager(
                  userId: userId,
                  token: data["token"],
                  child:
                      role == 'admin'
                          ? AdminDashboard(token: data["token"])
                          : role == 'Organization'
                          ? OrganizationHomePage(token: data["token"])
                          : HomePage(
                            data: data["token"],
                            onTokenChanged: (newToken) async {
                              // Handle token change
                            },
                          ),
                ),
          ),
        );
      } else {
        var data = jsonDecode(response.body);
        setState(() {
          errorMessage = data["message"] ?? "Login failed";
        });
        logger.e(
          "Login failed with status ${response.statusCode}: ${response.body}",
        );
      }
    } catch (e) {
      logger.e("Login error: $e");
      setState(() {
        if (e.toString().contains("timeout") ||
            e.toString().contains("Timeout")) {
          errorMessage =
              "Request timed out. Please check your internet connection and try again.";
        } else if (e.toString().contains("SocketException") ||
            e.toString().contains("Connection")) {
          errorMessage =
              "Cannot connect to server. Please check your internet connection.";
        } else {
          errorMessage = "Login failed: ${e.toString()}";
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      logger.i("Login process completed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 60),

                      // Logo or Brand Image
                      Center(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                            ),
                            child: Icon(
                              Icons.person_outline,
                              size: 60,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Welcome Text with Animation
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Welcome Back!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Sign in to continue your journey',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Error Message
                      if (errorMessage != null)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: TextStyle(color: Colors.red[700]),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Email Field with Animation
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'Enter your email',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: Theme.of(context).primaryColor,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ),

                      // Password Field with Animation
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: Theme.of(context).primaryColor,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Forgot Password Button with Animation
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const ForgotAccountScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Login Button with Animation
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (!isLoading) {
                                login();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child:
                                    isLoading
                                        ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Sign Up Link with Animation
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const ChoosePositions(),
                                  ),
                                );
                              },
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Debug Button (only show in debug mode)
                      if (dotenv.env['DEBUG_MODE'] == 'true')
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Center(
                            child: TextButton.icon(
                              onPressed: () async {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Running network diagnostics...',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                await NetworkDebug.printDiagnostics();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Check console for diagnostics results',
                                    ),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.bug_report, size: 16),
                              label: const Text('Debug Network'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
