//new api all fixed i used api.env

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/user_profile_data.dart';
import 'package:logger/logger.dart';
import 'dart:typed_data';

final String baseUrl = dotenv.env['BASE_URL']!;

class ProfileService {
  static final _logger = Logger();

  static Future<UserProfileData> getProfileData(
    String token, {
    String? username,
  }) async {
    //192.168.1.7      final uri = Uri.parse('http://10.0.2.2:5000/api/skills/get-all');

    final uri = Uri.parse('$baseUrl/skills/get-all');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = username != null ? json.encode({'username': username}) : null;

    final response = await http.post(uri, headers: headers, body: body);

    if (response.statusCode == 200) {
      return UserProfileData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load profile data: ${response.body}');
    }
  }

  static Future<void> deleteItem(
    String field,
    String value,
    String token,
  ) async {
    _logger.i('Deleting item:', error: {'field': field, 'value': value});
    final response = await http.delete(
      Uri.parse('$baseUrl/skills/delete-$field'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({field: value}),
    );

    if (response.statusCode != 200) {
      _logger.e('Delete failed:', error: response.statusCode);
      throw Exception('Failed to delete $field');
    }
  }

  static Future<void> addItem(String field, String value, String token) async {
    _logger.i('Adding item:', error: {'field': field, 'value': value});
    final response = await http.post(
      Uri.parse('$baseUrl/skills/add-$field'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'item': value}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add $field');
    }
  }

  static Future<void> updateItem(
    String field,
    String oldValue,
    String newValue,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/skills/update-$field'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'oldItem': oldValue, 'newItem': newValue}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update $field');
    }
  }

  static Future<String> uploadAvatar(Uint8List bytes, String token) async {
    try {
      final uri = Uri.parse("$baseUrl/users/upload-avatar");
      final request = http.MultipartRequest("POST", uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes('avatar', bytes, filename: 'avatar.jpg'),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        final resBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(resBody);
        return jsonResponse['avatarUrl'];
      } else {
        _logger.e('Failed to upload avatar:', error: response.statusCode);
        throw Exception('Failed to upload avatar');
      }
    } catch (e) {
      _logger.e('Upload error:', error: e);
      throw Exception('Error uploading avatar: $e');
    }
  }
}
