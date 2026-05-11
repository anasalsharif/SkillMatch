//new api all fixed i used api.env

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

final String baseUrl = dotenv.env['BASE_URL']!;

class AddJobOrPostCard extends StatefulWidget {
  final String token;
  final String text;
  final VoidCallback onPressed;
  const AddJobOrPostCard({
    super.key,
    required this.token,
    required this.text,
    required this.onPressed,
  });

  @override
  State<AddJobOrPostCard> createState() => _AddJobOrPostCardState();
}

class _AddJobOrPostCardState extends State<AddJobOrPostCard> {
  final logger = Logger();
  String? uploadedImageUrl;
  String name = '';
  String industry = '';

  @override
  void initState() {
    super.initState();
    fetchOrgData();
  }

  Future<void> fetchOrgData() async {
    try {
      //192.168.1.7         final uri = Uri.parse("http://10.0.2.2:5000/api/organization/getOrgData");

      final uri = Uri.parse("$baseUrl/organization/getOrgData");

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          uploadedImageUrl = jsonResponse['avatarUrl'];
          name = jsonResponse['name'];
          industry = jsonResponse['industry'];
        });
      } else {
        logger.e(
          "Failed to fetch user data",
          error: {"status": response.statusCode},
        );
      }
    } catch (e) {
      logger.e("Error fetching user data", error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          backgroundImage:
                              uploadedImageUrl != null
                                  ? NetworkImage(uploadedImageUrl!)
                                  : AssetImage(
                                        'assets/images/avatarPlaceholder.jpg',
                                      )
                                      as ImageProvider,
                          radius: 999999,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(name),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 150,
                    height: 40,
                    child: FloatingActionButton(
                      heroTag: '${widget.text.split(' ')[0]}Btn',
                      onPressed: widget.onPressed,
                      backgroundColor: const Color(0xFF0C9E91),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.text,
                            style: TextStyle(color: Colors.white),
                          ),
                          Icon(Icons.add, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
