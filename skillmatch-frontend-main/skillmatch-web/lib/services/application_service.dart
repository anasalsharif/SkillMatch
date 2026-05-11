//new api all fixed i used api.env

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

final String baseUrl = dotenv.env['BASE_URL']!;

class Application {
  final String id;
  final String userName;
  final String jobTitle;
  final double matchScore;
  final DateTime appliedDate;
  final String status;
  final String userId;
  final String username;

  Application({
    required this.id,
    required this.userName,
    required this.jobTitle,
    required this.matchScore,
    required this.appliedDate,
    required this.status,
    required this.userId,
    required this.username,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['_id'] ?? '',
      userName: json['userName'] ?? 'Unknown User',
      jobTitle: json['jobTitle'] ?? 'Unknown Job',
      matchScore: (json['matchScore'] ?? 0).toDouble(),
      appliedDate:
          DateTime.tryParse(json['appliedDate'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'pending',
      userId: json['userId'] ?? '',
      username: json['username'] ?? 'Unknown User',
    );
  }
}

class ApplicationService {
  static final _logger = Logger();

  static Future<void> applyForJob({
    required String token,
    required String jobId,
    required String jobTitle,
    required double matchScore,
    String? organizationId,
  }) async {
    try {
      final response = await http.post(
        //192.168.1.7         Uri.parse('http://10.0.2.2:5000/api/applications/data'),
        Uri.parse('$baseUrl/applications/data'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'jobId': jobId,
          'jobTitle': jobTitle,
          'matchScore': matchScore,
          'organizationId': organizationId,
        }),
      );
      // print(
      //   "📦 Payload sent to backend: ${jsonEncode({'jobId': jobId, 'jobTitle': jobTitle, 'matchScore': matchScore, 'organizationId': organizationId})}",
      // );
      // print('Response status: ${response.statusCode}');
      // print('Response body: ${response.body}');

      if (response.statusCode != 201) {
        throw Exception('Failed to apply for job: ${response.body}');
      }
    } catch (e) {
      _logger.e('Exception during API call:', error: e);
      rethrow;
    }
  }

  static Future<List<Application>> getOrganizationApplications(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/applications/organization'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Application.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load applications: ${response.body}');
    }
  }

  static Future<String?> getUserCV(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/getUserCV/$userId'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['cvUrl'];
    }
    return null;
  }

  static Future<String?> getUserCvByUsername(String username) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/getUserCvByUsername/$username'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['cvUrl'];
    }
    return null;
  }

  static Future<Application> getApplicationById(
    String token,
    String applicationId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/applications/getAppbyId/$applicationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Application.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Application not found');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch application');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: Unable to fetch application');
    }
  }
}
