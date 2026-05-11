import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/mesage_profile.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/post_sections/profile_widget_for_another_users.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab.dart'; // <-- Add this import

class FreelancePostCard extends StatelessWidget {
  final String username;
  final String content;
  final String date;
  final String userId;

  const FreelancePostCard({
    required this.username,
    required this.content,
    required this.date,
    required this.userId,
    super.key,
  });

  Future<String> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? 'defaultUsername';
  }

  Future<String> getCurrentUserid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? 'defaultUserId';
  }

  Future<String> getCurrentUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? 'defaulttoken';
  }

  Future<String> getCurrentUserAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('avatarUrl') ?? 'defaulttoken';
  }

  Future<void> _goToUserProfile(BuildContext context) async {
    final currentUsername = await getCurrentUsername();
    final token = await getCurrentUserToken();

    if (username == currentUsername) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileTab(onLogout: () {}, token: token),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ProfileWidgetForAnotherUsers(
                username: username,
                token: token,
              ),
        ),
      );
    }
  }

  Future<void> _goToChatPage(BuildContext context) async {
    final userid = await getCurrentUserid();
    final token = await getCurrentUserToken();
    final currentUserAvatarUrl = await getCurrentUserAvatar();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ChatPage(
              currentUserId: userid,
              peerUserId: userId,
              peerUsername: username,
              currentuserAvatarUrl: currentUserAvatarUrl,
              token: token,
              onChatClosed: () => Navigator.pop(context),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<String>(
      future: getCurrentUsername(),
      builder: (context, snapshot) {
        final isSelf = snapshot.data == username;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: theme.cardColor,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        child: Text(
                          username[0].toUpperCase(),
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _goToUserProfile(context),
                          child: Text(
                            username,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        date,
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    content,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  if (!isSelf)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => _goToChatPage(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(
                          Icons.message_outlined,
                          size: 20,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Contact",
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
