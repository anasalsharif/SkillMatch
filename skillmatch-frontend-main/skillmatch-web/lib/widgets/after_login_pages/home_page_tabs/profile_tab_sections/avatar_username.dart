//new api all fixed i used api.env

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:logger/logger.dart';
import 'package:skillmatch_platform/widgets/appSetting/seeting.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:skillmatch_platform/services/profile_service.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/image_picker_interface.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/web_image_picker.dart';

final String baseUrl = dotenv.env['BASE_URL']!;

class AvatarUsername extends StatefulWidget {
  final String token;
  const AvatarUsername({super.key, required this.token});

  @override
  State<AvatarUsername> createState() => _AvatarUsernameState();
}

class _AvatarUsernameState extends State<AvatarUsername> {
  String? uploadedImageUrl;
  final _logger = Logger();
  bool isLoading = false;
  late final ImagePickerInterface _imagePicker;

  @override
  void initState() {
    super.initState();
    _imagePicker = WebImagePicker;
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    Map<String, dynamic> decodedToken = JwtDecoder.decode(widget.token);
    String username = decodedToken['username'];

    try {
      final response = await http.get(
        Uri.parse(
          //192.168.1.7
          '$baseUrl/users/getUserData?userName=$username',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      _logger.i('Fetching data for user: $username');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          uploadedImageUrl = data['avatarUrl'];
        });
      } else {
        _logger.e('Failed to fetch user data:', error: response.statusCode);
      }
    } catch (e) {
      _logger.e('Error fetching user data:', error: e);
    }
  }

  Future<void> _pickImage() async {
    try {
      final bytes = await _imagePicker.pickImage();
      if (bytes != null) {
        await _uploadImage(bytes);
      }
    } catch (e) {
      _logger.e("Error picking image", error: e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _uploadImage(Uint8List bytes) async {
    try {
      setState(() {
        isLoading = true;
      });

      final result = await ProfileService.uploadAvatar(bytes, widget.token);

      setState(() {
        uploadedImageUrl = result;
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully')),
        );
      }
    } catch (e) {
      _logger.e("Error uploading image", error: e);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    }
  }

  void showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.remove_red_eye),
                title: Text('View Profile Picture'),
                onTap: () {
                  Navigator.pop(context);
                  if (uploadedImageUrl != null) {
                    showDialog(
                      context: context,
                      builder:
                          (_) =>
                              Dialog(child: Image.network(uploadedImageUrl!)),
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.update),
                title: Text('Update Profile Picture'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Remove Profile Picture'),
                onTap: () async {
                  Navigator.pop(context);
                  await removeAvatarFromBackend();
                },
              ),
            ],
          ),
    );
  }

  Future<void> removeAvatarFromBackend() async {
    final uri = Uri.parse("$baseUrl/users/remove-avatar");

    try {
      final response = await http.delete(
        uri,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        setState(() {
          uploadedImageUrl = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Profile picture removed')));
      } else {
        _logger.e('Failed to delete avatar:', error: response.statusCode);
      }
    } catch (e) {
      _logger.e('Delete avatar error:', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> decodedToken = JwtDecoder.decode(widget.token);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: SizedBox(
                height: 110,
                width: 110,
                child: FloatingActionButton(
                  heroTag: "avatar_fab",
                  onPressed: showAvatarOptions,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  shape: const CircleBorder(),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      backgroundImage:
                          uploadedImageUrl != null
                              ? NetworkImage(uploadedImageUrl!)
                              : null,
                      radius: 50,
                      child:
                          uploadedImageUrl == null
                              ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              )
                              : null,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon:
                      isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: isLoading ? null : _pickImage,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          decodedToken['username'],
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black38,
              ),
              Shadow(
                offset: Offset(0, 2),
                blurRadius: 6,
                color: Colors.black26,
              ),
            ],
          ),

          //here
        ),
      ],
    );
  }
}
