import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillmatch_platform/widgets/freeLancing/freelancePostCard.dart';
import 'package:skillmatch_platform/widgets/freeLancing/freelancePostCreator.dart';

final String baseUrl = dotenv.env['BASE_URL']!;

class FreelanceFeed extends StatefulWidget {
  const FreelanceFeed({super.key});
  @override
  _FreelanceFeedState createState() => _FreelanceFeedState();
}

class _FreelanceFeedState extends State<FreelanceFeed> {
  List<Map<String, String>> _freelancePosts = [];
  final String backendUrl = '$baseUrl/freelance/post';

  @override
  void initState() {
    super.initState();
    _fetchPostsFromBackend();
  }

  Future<String> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? 'defaultUsername';
  }

  Future<String> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? 'defaultUserId';
  }

  Future<void> _addNewPost(String content) async {
    final username = await getCurrentUsername();
    final userId = await getCurrentUserId();

    final date = DateTime.now().toIso8601String().substring(0, 10);

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'content': content,
          'date': date,
          'userId': userId,
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          _freelancePosts.insert(0, {
            'username': username,
            'content': content,
            'date': date,
            'userId': userId,
          });
        });
      } else {
        debugPrint('Failed to post: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error posting freelance job: $e');
    }
  }

  Future<void> _fetchPostsFromBackend() async {
    try {
      final response = await http.get(Uri.parse(backendUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          _freelancePosts =
              data
                  .map((item) {
                    return {
                      'username': (item['username'] ?? '').toString(),
                      'content': (item['content'] ?? '').toString(),
                      'date': (item['date'] ?? '').toString(),
                      'userId': (item['userId'] ?? '').toString(),
                    };
                  })
                  .toList()
                  .cast<Map<String, String>>();
        });
      } else {
        debugPrint('Failed to fetch posts: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching freelance posts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        FreelancePostCreator(onPost: _addNewPost),
        ..._freelancePosts.map(
          (post) => FreelancePostCard(
            username: post['username']!,
            content: post['content']!,
            date: post['date']!,
            userId: post['userId']!,
          ),
        ),
      ],
    );
  }
}
