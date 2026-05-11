import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

final String baseUrl = dotenv.env['BASE_URL']!;

class Rating {
  final double rating;
  final int count;
  final List<String> users;
  final String userId;
  final String userName;
  final double? userRating;

  Rating({
    required this.rating,
    required this.count,
    required this.users,
    required this.userId,
    required this.userName,
    this.userRating,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      rating: (json['rating'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
      users: List<String>.from(json['users'] ?? []),
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userRating:
          json['userRating'] != null
              ? (json['userRating'] as num).toDouble()
              : null,
    );
  }
}

class RatingService {
  final String token;
  final _logger = Logger();

  RatingService({required this.token});

  /// Get rating by username
  Future<Rating> getRatingByUsername(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ratings/username?username=$username'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Backend rating response: $data');
        return Rating.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Rating not found');
      } else if (response.statusCode == 400) {
        throw Exception('Username is required');
      } else {
        _logger.e('Failed to get rating by username:', error: response.body);
        throw Exception('Failed to get rating: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error getting rating by username:', error: e);
      rethrow;
    }
  }

  /// Get rating by user ID
  Future<Rating> getRatingByUserId(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ratings/user?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return Rating.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Rating not found');
      } else if (response.statusCode == 400) {
        throw Exception('User ID is required');
      } else {
        _logger.e('Failed to get rating by user ID:', error: response.body);
        throw Exception('Failed to get rating: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error getting rating by user ID:', error: e);
      rethrow;
    }
  }

  /// Get rating for the authenticated user
  Future<Rating> getMyRating() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ratings/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return Rating.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Rating not found');
      } else {
        _logger.e('Failed to get my rating:', error: response.body);
        throw Exception('Failed to get rating: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error getting my rating:', error: e);
      rethrow;
    }
  }

  /// Update rating for a user
  Future<Map<String, dynamic>> updateRating({
    required String targetUsername,
    required double ratingValue,
  }) async {
    try {
      if (ratingValue < 1 || ratingValue > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/ratings/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'targetUsername': targetUsername,
          'ratingValue': ratingValue,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to update rating');
      } else if (response.statusCode == 404) {
        throw Exception('Target user not found');
      } else {
        _logger.e('Failed to update rating:', error: response.body);
        throw Exception('Failed to update rating: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error updating rating:', error: e);
      rethrow;
    }
  }
}
