import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class NetworkDebug {
  static final Logger _logger = Logger();
  static final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  /// Test network connectivity and API endpoint
  static Future<Map<String, dynamic>> testConnection() async {
    final results = <String, dynamic>{};

    try {
      _logger.i("🔍 Starting network diagnostics...");

      // Test 1: Check if BASE_URL is configured
      results['base_url'] = baseUrl;
      results['base_url_configured'] = baseUrl.isNotEmpty;
      _logger.i("📍 Base URL: $baseUrl");

      if (baseUrl.isEmpty) {
        results['error'] = 'BASE_URL not configured in api.env';
        return results;
      }

      // Test 2: Test basic connectivity
      try {
        final uri = Uri.parse(baseUrl);
        results['host'] = uri.host;
        results['port'] = uri.port;
        results['scheme'] = uri.scheme;

        _logger.i("🌐 Testing connectivity to ${uri.host}:${uri.port}");

        // Test socket connection
        final socket = await Socket.connect(
          uri.host,
          uri.port,
          timeout: Duration(seconds: 5),
        );
        socket.destroy();
        results['socket_connection'] = true;
        _logger.i("✅ Socket connection successful");
      } catch (e) {
        results['socket_connection'] = false;
        results['socket_error'] = e.toString();
        _logger.e("❌ Socket connection failed: $e");
      }

      // Test 3: Test HTTP request to health endpoint
      try {
        _logger.i("🏥 Testing health endpoint...");
        final healthUrl = baseUrl.replaceAll('/api', '/health');
        final response = await http
            .get(
              Uri.parse(healthUrl),
              headers: {"Content-Type": "application/json"},
            )
            .timeout(Duration(seconds: 10));

        results['health_check'] = {
          'status_code': response.statusCode,
          'response_time': DateTime.now().millisecondsSinceEpoch,
          'body': response.body,
        };
        _logger.i("🏥 Health check response: ${response.statusCode}");
      } catch (e) {
        results['health_check_error'] = e.toString();
        _logger.e("❌ Health check failed: $e");
      }

      // Test 4: Test login endpoint structure
      try {
        _logger.i("🔐 Testing login endpoint...");
        final loginUrl = '$baseUrl/auth/login';
        final response = await http
            .post(
              Uri.parse(loginUrl),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({"email": "test@test.com", "password": "test"}),
            )
            .timeout(Duration(seconds: 10));

        results['login_endpoint'] = {
          'status_code': response.statusCode,
          'response_time': DateTime.now().millisecondsSinceEpoch,
          'body':
              response.body.length > 200
                  ? response.body.substring(0, 200) + '...'
                  : response.body,
        };
        _logger.i("🔐 Login endpoint response: ${response.statusCode}");
      } catch (e) {
        results['login_endpoint_error'] = e.toString();
        _logger.e("❌ Login endpoint test failed: $e");
      }

      // Test 5: Platform-specific checks
      results['platform'] = Platform.operatingSystem;
      results['is_web'] = identical(0, 0.0); // Web detection trick

      _logger.i("📱 Platform: ${results['platform']}");
      _logger.i("🌐 Is Web: ${results['is_web']}");
    } catch (e) {
      results['general_error'] = e.toString();
      _logger.e("❌ Network diagnostics failed: $e");
    }

    _logger.i("🔍 Network diagnostics completed");
    return results;
  }

  /// Get recommended BASE_URL based on platform
  static String getRecommendedBaseUrl() {
    if (Platform.isAndroid) {
      return "http://10.0.2.2:5000/api"; // Android emulator
    } else if (Platform.isIOS) {
      return "http://localhost:5000/api"; // iOS simulator
    } else {
      return "http://localhost:5000/api"; // Web and others
    }
  }

  /// Print network diagnostics to console
  static Future<void> printDiagnostics() async {
    final results = await testConnection();

    print("\n" + "=" * 50);
    print("🔍 TALENTLINK NETWORK DIAGNOSTICS");
    print("=" * 50);

    results.forEach((key, value) {
      print("$key: $value");
    });

    print("=" * 50);
    print("💡 RECOMMENDATIONS:");

    if (!(results['base_url_configured'] ?? false)) {
      print("❌ Configure BASE_URL in api.env file");
    }

    if (!(results['socket_connection'] ?? false)) {
      print("❌ Cannot connect to server. Check if:");
      print("   - Backend server is running");
      print("   - Correct IP address/port in BASE_URL");
      print("   - Firewall allows connection");
      print("   - For web: Use localhost instead of 10.0.2.2");
    }

    if (results['platform'] == 'android' && baseUrl.contains('localhost')) {
      print(
        "⚠️  Android detected but using localhost. Consider using 10.0.2.2",
      );
    }

    if (results['is_web'] == true && baseUrl.contains('10.0.2.2')) {
      print("⚠️  Web detected but using 10.0.2.2. Use localhost instead");
    }

    print("=" * 50 + "\n");
  }
}
