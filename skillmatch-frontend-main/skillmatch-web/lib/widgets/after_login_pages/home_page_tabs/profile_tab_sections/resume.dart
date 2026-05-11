//new api all fixed i used api.env

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:skillmatch_platform/widgets/base_widgets/button.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

final String baseUrl = dotenv.env['BASE_URL']!;

class ResumeWidget extends StatefulWidget {
  final String token;
  final VoidCallback onSkillsExtracted;

  const ResumeWidget({
    super.key,
    required this.token,
    required this.onSkillsExtracted,
  });

  @override
  State<ResumeWidget> createState() => _ResumeWidgetState();
}

class _ResumeWidgetState extends State<ResumeWidget> {
  String? uploadedCVUrl;
  bool _isUploading = false;

  Future<void> pickAndUploadPDF() async {
    setState(() {
      _isUploading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final uri = Uri.parse("$baseUrl/users/upload-cv");

        if (kIsWeb) {
          // Web platform
          if (result.files.single.bytes != null) {
            final request = http.Request("POST", uri);
            request.headers['Authorization'] = 'Bearer ${widget.token}';

            final formData = http.MultipartRequest("POST", uri);
            formData.headers['Authorization'] = 'Bearer ${widget.token}';
            formData.files.add(
              http.MultipartFile.fromBytes(
                'cv',
                result.files.single.bytes!,
                filename: result.files.single.name,
              ),
            );

            final streamedResponse = await formData.send();
            final response = await http.Response.fromStream(streamedResponse);

            if (response.statusCode == 200) {
              final jsonResponse = json.decode(response.body);
              setState(() {
                uploadedCVUrl = jsonResponse['cvUrl'];
              });

              await Future.delayed(Duration(seconds: 1));
              widget.onSkillsExtracted();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'CV uploaded successfully. Extracting skills...',
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Failed to upload CV')));
            }
          }
        } else {
          // Mobile platform
          if (result.files.single.path != null) {
            final request = http.MultipartRequest("POST", uri);
            request.headers['Authorization'] = 'Bearer ${widget.token}';

            File pdfFile = File(result.files.single.path!);
            request.files.add(
              await http.MultipartFile.fromPath('cv', pdfFile.path),
            );

            final streamedResponse = await request.send();
            final response = await http.Response.fromStream(streamedResponse);

            if (response.statusCode == 200) {
              final jsonResponse = json.decode(response.body);
              setState(() {
                uploadedCVUrl = jsonResponse['cvUrl'];
              });

              await Future.delayed(Duration(seconds: 1));
              widget.onSkillsExtracted();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'CV uploaded successfully. Extracting skills...',
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Failed to upload CV')));
            }
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload error: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'CV / Resume',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),

          if (_isUploading) const LinearProgressIndicator(),

          const SizedBox(height: 10),

          if (uploadedCVUrl != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('CV.pdf', style: TextStyle(fontSize: 16)),
                  ),
                  IconButton(
                    icon: Icon(Icons.remove_red_eye, color: Colors.blue),
                    onPressed: () async {
                      final url = Uri.parse(uploadedCVUrl!);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not open CV')),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        uploadedCVUrl = null;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('CV removed locally')),
                      );
                    },
                  ),
                ],
              ),
            )
          else
            BaseButton(
              text: "Upload CV (PDF)",
              onPressed:
                  _isUploading
                      ? () {}
                      : () {
                        pickAndUploadPDF();
                      },
            ),
        ],
      ),
    );
  }
}
