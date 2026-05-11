//new api all fixed i used api.env

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

final String baseUrl = dotenv.env['BASE_URL']!;

class LocationService {
  final String token;
  final _logger = Logger();

  LocationService({required this.token});

  Future<bool> setLocation({required double lat, required double lng}) async {
    final url = Uri.parse('$baseUrl/location/set');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'lat': lat, 'lng': lng}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      _logger.e('Failed to set location:', error: response.body);
      return false;
    }
  }

  Future<Map<String, double>> getLocationByUsername(String username) async {
    final url = Uri.parse('$baseUrl/location/get');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'username': username}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'lat': (data['lat'] as num).toDouble(),
        'lng': (data['lng'] as num).toDouble(),
      };
    } else {
      _logger.e('Failed to get location:', error: response.body);
      return {'lat': 0.0, 'lng': 0.0}; // fallback
    }
  }

  Future<List<Map<String, dynamic>>> getAllCompaniesLocations() async {
    final url = Uri.parse('$baseUrl/location/all');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      _logger.e(
        'Failed to fetch all companies locations:',
        error: response.body,
      );
      return [];
    }
  }
}
