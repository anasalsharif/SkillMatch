//new api all fixed i used api.env

import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

final String baseUrl = dotenv.env['BASE_URL']!;

class SearchPageService {
  //192.168.1.7    final String baseUrl = 'http://10.0.2.2:5000/api';
  //  final String baseUrl = 'http://192.168.1.7:5000/api';

  final _logger = Logger();

  Future<List<dynamic>> fetchChatHistory(String currentUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat-history/$currentUserId'),
      );

      if (response.statusCode == 200) {
        List<dynamic> fetchedHistory = json.decode(response.body);

        fetchedHistory.sort((a, b) {
          DateTime timeA = DateTime.parse(a['lastMessageTimestamp']);
          DateTime timeB = DateTime.parse(b['lastMessageTimestamp']);
          return timeB.compareTo(timeA);
        });

        return fetchedHistory;
      } else {
        _logger.w(
          'Failed to fetch chat history. Status code: ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      _logger.e('Error fetching chat history:', error: e);
      return [];
    }
  }

  Future<List<dynamic>> searchUsers(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/search?q=$query'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        _logger.w(
          'Failed to fetch search results. Status code: ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      _logger.e('Error searching users:', error: e);
      return [];
    }
  }

  Future<bool> deleteChatHistory(String currentUserId, String userId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/delete-message/$currentUserId/$userId'),
      );

      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Error hiding chat:', error: e);
      return false;
    }
  }

  Future<int> getUnreadCount(String userId, String peerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/messages/unread-count/$userId/$peerId'),
      // headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['count'];
    }
    return 0;
  }
}
