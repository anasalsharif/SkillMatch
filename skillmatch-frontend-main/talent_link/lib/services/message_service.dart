//new api all fixed i used api.env

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/mesage_profile.dart';
import 'package:logger/logger.dart';

final String baseUrl = dotenv.env['BASE_URL']!;

class MessageService {
  final String token;
  //192.168.1.7    final String baseUrl = 'http://10.0.2.2:5000/api';

  // final String baseUrl = 'http://192.168.1.7:5000/api';
  final _logger = Logger();

  MessageService(this.token);

  Future<Map<String, dynamic>?> getUserId() async {
    final decodedToken = JwtDecoder.decode(token);
    final role = decodedToken['role'];
    final username = decodedToken['username'];
    //IM HERE
    String userApiUrl;
    if (role == 'Job Seeker' || role == 'Freelancer') {
      userApiUrl = '$baseUrl/users/get-user-id';
    } else if (role == 'Organization') {
      userApiUrl =
          '$baseUrl/organization/getOrgDataWithuserName?userName=${Uri.encodeComponent(username)}';
      //        '$baseUrl/organization/getOrgDataWithuserName?userName=${Uri.encodeComponent(username)}',
    } else {
      debugPrint("no role !!!!: $role");
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse(userApiUrl),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        return {
          'userId': userData['userId'],
          'avatarUrl': userData['avatarUrl'],
        };
      } else {
        debugPrint("Failed to fetch user ID: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching user ID: $e");
      return null;
    }
  }

  Future<void> navigateToSearchPage(BuildContext context) async {
    final userInfo = await getUserId(); // Now returns a Map

    if (userInfo != null && userInfo['userId'] != null) {
      _logger.i(
        'User Info:',
        error: {
          'userId': userInfo['userId'],
          'avatarUrl': userInfo['avatarUrl'] ?? '',
        },
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => SearchUserPage(
                currentUserId: userInfo['userId'],
                avatarUrl: userInfo['avatarUrl'] ?? '',
                token: token,
              ),
        ),
      );
    }
  }
}

class MessageService2 {
  Future<Map<String, dynamic>?> fetchPeerInfo(String username) async {
    final res = await http.get(
      Uri.parse('$baseUrl/users/getUserData?userName=$username'),
    );
    if (res.statusCode == 200) {
      return json.decode(res.body);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchMessages(
    String currentUserId,
    String peerUserId,
  ) async {
    final res = await http.get(
      Uri.parse('$baseUrl/messages/$currentUserId/$peerUserId'),
    );
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    }
    return [];
  }

  Future<void> sendMessage(Map<String, dynamic> message) async {
    await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(message),
    );
  }

  Future<bool> markMessagesAsRead(
    String currentUserId,
    String peerUserId,
  ) async {
    final url = '$baseUrl/messages/mark-as-read';
    print('Attempting to mark messages as read. URL: $url');
    print('Request data: senderId=$peerUserId, receiverId=$currentUserId');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'senderId': peerUserId,
          'receiverId': currentUserId,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        print(
          'Failed to mark messages as read. Status: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      print('Exception in markMessagesAsRead: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> checkMutualFollow(
    String currentUserId,
    String peerUserId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/checkfollow/$currentUserId/$peerUserId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {
        'canMessage': false,
        'user1FollowsUser2': false,
        'user2FollowsUser1': false,
      };
    } catch (e) {
      return {
        'canMessage': false,
        'user1FollowsUser2': false,
        'user2FollowsUser1': false,
      };
    }
  }
}
