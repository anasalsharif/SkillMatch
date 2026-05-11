//new api all fixed i used api.env

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:logger/logger.dart';

class PostService {
  final String token;
  final String baseUrl = dotenv.env['BASE_URL']!;

  final _logger = Logger();

  PostService(this.token);
  //organization
  Future<Map<String, dynamic>> fetchOrganizationData() async {
    final decodedToken = JwtDecoder.decode(token);
    final username = decodedToken['username'];
    _logger.i('🏢 Fetching org data for $username');

    try {
      final uri = Uri.parse(
        '$baseUrl/organization/getOrgDataWithuserName?userName=${Uri.encodeComponent(username)}',
      );
      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': token,
            },
          )
          .timeout(const Duration(seconds: 10));

      _logger.i('📦 Response status: ${response.statusCode}');

      // Perform JSON decoding in an isolate
      final jsonData = await compute(_parseJsonIsolate, response.body);

      // Just get the avatar URL without trying to precache it
      final avatarUrl = jsonData['avatarUrl']?.toString() ?? '';

      return {
        'name': jsonData['name']?.toString() ?? 'Organization',
        'avatarUrl': avatarUrl,
      };
    } catch (e) {
      _logger.e('❌ Org data error:', error: e);
      return {'name': 'Organization', 'avatarUrl': 'assets/default_org.png'};
    }
  }

  Future<Map<String, dynamic>> fetchOrganizationDataByuserName(
    String username,
  ) async {
    _logger.i('🏢 Fetching org data by username for $username');
    try {
      final uri = Uri.parse(
        '$baseUrl/organization/getOrgDataByuserName?userName=${Uri.encodeComponent(username)}',
      );
      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': token,
            },
          )
          .timeout(const Duration(seconds: 10));

      _logger.i('📦 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Perform JSON decoding in an isolate
        final jsonData = await compute(_parseJsonIsolate, response.body);

        // Return all organization data
        return jsonData;
      } else {
        _logger.e(
          '❌ Failed to fetch org data: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Failed to fetch organization data: ${response.body}');
      }
    } catch (e) {
      _logger.e('❌ Org data error:', error: e);
      rethrow;
    }
  }

  // Helper function to run in isolate
  static Map<String, dynamic> _parseJsonIsolate(String body) {
    return json.decode(body);
  }

  // User Data
  Future<Map<String, dynamic>> fetchUserData() async {
    final decodedToken = JwtDecoder.decode(token);
    final username = decodedToken['username'];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/getUserData?userName=$username'),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to fetch user data: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching user data: $e');
    }
  }

  // Posts
  Future<Map<String, dynamic>> fetchPosts(int page, int limit) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts/get-posts?page=$page&limit=$limit'),
        headers: {'Authorization': token},
      );

      if (response.statusCode == 200) {
        _logger.d('Posts response:', error: response.body);
        return jsonDecode(response.body);
      }
      throw Exception('Failed to load posts: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching posts: $e');
    }
  }

  Future<bool> createPost(String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/createPost'),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
        body: jsonEncode({"content": content}),
      );
      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Error creating post: $e');
    }
  }

  Future<bool> updatePost(String postId, String newContent) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/posts/updatePost/$postId'),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
        body: jsonEncode({"content": newContent}),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating post: $e');
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/posts/deletePost/$postId'),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting post: $e');
    }
  }

  Future<Map<String, dynamic>> fetchPostById(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts/getPostById/$postId'),
        headers: {'Authorization': token},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to fetch post: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching post: $e');
    }
  }

  // Comments
  Future<List<Map<String, dynamic>>> fetchComments(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts/$postId/comments'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(responseData['comments'] ?? []);
      }
      throw Exception('Failed to fetch comments: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching comments: $e');
    }
  }

  Future<Map<String, dynamic>> addComment(String postId, String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/comments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to add comment: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error adding comment: $e');
    }
  }

  Future<Map<String, dynamic>> addReply(String commentId, String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/comments/$commentId/replies'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to add reply: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error adding reply: $e');
    }
  }

  Future<Map<String, dynamic>> fetchUserByUsername(String username) async {
    _logger.i('Fetching user with username: $username');

    if (username.isEmpty) {
      throw Exception('Username is null or empty');
    }

    final url = Uri.parse('$baseUrl/users/byusername/$username');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': token},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Fetch posts by username
  Future<List<Map<String, dynamic>>> fetchPostsByUsername(
    String username,
    int page,
    int limit,
  ) async {
    final url = Uri.parse(
      '$baseUrl/posts/getuser-posts-byusername/$username?page=$page&limit=$limit',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['posts']);
    } else {
      throw Exception('Failed to load posts: ${response.statusCode}');
    }
  }
}
