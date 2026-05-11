import 'dart:convert';
import 'package:http/http.dart' as http;

class CommentService {
  final String baseUrl;
  final String token;
  final String? postId;

  CommentService({required this.baseUrl, required this.token, this.postId});

  Future<Map<String, dynamic>> addComment(String text) async {
    if (postId == null) throw Exception('Post ID is required for comments');

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
    throw Exception('Failed to add comment: ${response.body}');
  }

  Future<Map<String, dynamic>> addReply(String commentId, String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/comments/$commentId/replies'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to add reply: ${response.body}');
  }
}
