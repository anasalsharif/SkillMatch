//new api all fixed i used api.env

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:skillmatch_platform/models/notfification_model.dart';
import 'package:logger/logger.dart';

final String baseUrl = dotenv.env['BASE_URL']!;

class NotificationService {
  //192.168.1.7     static const String _baseUrl = 'http://10.0.2.2:5000/api';

  // static const String _baseUrl = 'http://192.168.1.7:5000/api';
  late String token;
  final _logger = Logger();

  Future<String> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? 'defaultUsername';
  }

  Future<String> getCurrentUserid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? 'defaultUsername';
  }

  Future<List<NotificationModel>> fetchApplyForJobNotifications() async {
    try {
      final username = await getCurrentUsername();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/getAppliedJob/$username'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load job notifications: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Error fetching job notifications:', error: e);
      return [];
    }
  }

  Future<List<NotificationModel>> fetchJobNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/getGlobalJobNotification'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load job notifications: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Error fetching job notifications:', error: e);
      return [];
    }
  }

  Future<List<NotificationModel>> fetchMeetingNotifications() async {
    try {
      final userid = await getCurrentUserid();
      _logger.d('User ID: $userid');

      final response = await http.get(
        Uri.parse('$baseUrl/notifications/getMeetingNotification/$userid'),
      );

      _logger.d('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _logger.d('Response data: $data');

        final notifications =
            data.map((json) {
              try {
                return NotificationModel.fromJson(json);
              } catch (e) {
                _logger.e('Error parsing notification: $json', error: e);
                // Return a default notification to avoid breaking the app
                return NotificationModel();
              }
            }).toList();

        return notifications;
      } else {
        throw Exception(
          'Failed to load Meeting notifications: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      _logger.e('Error fetching meeting notifications:', error: e);
      return [];
    }
  }

  Future<List<NotificationModel>>
  fetchUserNotificationsLikeCommentReply() async {
    try {
      String username = await getCurrentUsername();
      _logger.i('Fetching notifications for: $username');
      _logger.i(
        'Full URL: $baseUrl/notifications/getPrivateNotificationsLikeCommentReply',
      );

      final response = await http.get(
        Uri.parse(
          '$baseUrl/notifications/getPrivateNotificationsLikeCommentReply/$username',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _logger.i('Notifications fetched successfully:', error: data);
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load job notifications: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Error in _fetchNotifications:', error: e);
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/notifications/markAsRead/$notificationId'),
      );

      if (response.statusCode == 200) {
        _logger.i('Notification marked as read');
      } else {
        _logger.w('Failed to mark as read:', error: response.statusCode);
      }
    } catch (e) {
      _logger.e('Error marking notification as read:', error: e);
    }
  }
}
