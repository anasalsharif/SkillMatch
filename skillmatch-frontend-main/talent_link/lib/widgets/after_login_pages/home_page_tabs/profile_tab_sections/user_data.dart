import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillmatch_platform/services/application_service.dart';
import 'package:skillmatch_platform/utils/pdfViewr.dart';

class UserData extends StatelessWidget {
  const UserData({super.key});
  Future<String> getCurrentUserid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? 'defaultUsername';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          children: [
            SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final userId = await getCurrentUserid();

                if (userId != null) {
                  final cvUrl = await ApplicationService.getUserCV(userId);
                  if (cvUrl != null && cvUrl.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PDFViewerPage(url: cvUrl),
                      ),
                    );
                  } else {
                    print('No CV URL found');
                  }
                } else {
                  print("application.userId is null!");
                }
              },
              icon: Icon(Icons.picture_as_pdf, color: Colors.white),
              label: const Text(
                "View CV",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
