//new api all fixed i used api.env

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

final String baseUrl = dotenv.env['BASE_URL']!;

class OrganizationService {
  final String token;

  OrganizationService({required this.token});

  Future<Map<String, dynamic>> getOrganizationProfile({
    String? organizationId,
  }) async {
    final uri = Uri.parse('$baseUrl/organization/getOrgData');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(organizationId != null ? {'id': organizationId} : {}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch organization data: ${response.body}');
    }
  }
}
