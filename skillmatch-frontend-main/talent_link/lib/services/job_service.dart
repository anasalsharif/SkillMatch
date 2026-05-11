//new api all fixed i used api.env
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:skillmatch_platform/models/job.dart';
import 'package:logger/logger.dart';

class JobService {
  final String token;
  //192.168.1.7     static const String baseUrl = 'http://10.0.2.2:5000/api/job';

  //static const String baseUrl = 'http://192.168.1.7:5000/api/job';
  static final String baseUrl = dotenv.env['BASE_URL']!;
  final _logger = Logger();

  JobService({required this.token});
  Future<Job> fetchJobById(String jobId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/job/job/$jobId'),
            // headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Request timeout - check your network connection',
              );
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Job.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Job not found');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed - token may be expired');
      } else {
        throw Exception(
          'Failed to load job - Server returned ${response.statusCode}',
        );
      }
    } on http.ClientException catch (e) {
      _logger.e("Network error fetching job:", error: e);
      throw Exception('Network error - check your internet connection');
    } on FormatException catch (e) {
      _logger.e("Invalid response format:", error: e);
      throw Exception('Invalid server response');
    } catch (e) {
      _logger.e("Error fetching job:", error: e);
      rethrow;
    }
  }

  Future<List<Job>> fetchJobs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/job/getorgjobs'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Job.fromJson(json)).toList();
      } else {
        print(
          'JobService: status=${response.statusCode}, body=${response.body}',
        );
        throw Exception('Failed to load jobs');
      }
    } catch (e) {
      _logger.e("Error fetching jobs:", error: e);
      rethrow;
    }
  }

  Future<void> deleteJob(String jobId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/job/deletejob?jobId=$jobId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Request timeout - check your network connection',
              );
            },
          );

      if (response.statusCode == 401) {
        throw Exception('Authentication failed - token may be expired');
      } else if (response.statusCode == 404) {
        throw Exception('Job not found');
      } else if (response.statusCode != 200) {
        throw Exception(
          'Failed to delete job - Server returned ${response.statusCode}',
        );
      }
    } on http.ClientException catch (e) {
      _logger.e("Network error deleting job:", error: e);
      throw Exception('Network error - check your internet connection');
    } on FormatException catch (e) {
      _logger.e("Invalid response format:", error: e);
      throw Exception('Invalid server response');
    } catch (e) {
      _logger.e("Error deleting job:", error: e);
      rethrow;
    }
  }

  Future<List<Job>> fetchUserJobs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/job/getAllJobsUser'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Job.fromJson(json)).toList();
      } else if (response.statusCode == 204) {
        return []; // No available jobs
      } else {
        throw Exception('Failed to load jobs');
      }
    } catch (e) {
      _logger.e("Error fetching user jobs:", error: e);
      return [];
    }
  }

  Future<List<dynamic>> fetchMatchedUsers(
    String jobId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await http.post(
      //192.168.1.7          Uri.parse('http://10.0.2.2:5000/api/jobMatch/getMatchSortedByScore'),
      Uri.parse('$baseUrl/jobMatch/getMatchSortedByScore'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'jobId': jobId, 'page': page, 'pageSize': pageSize}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load matched users');
    }
  }
}
