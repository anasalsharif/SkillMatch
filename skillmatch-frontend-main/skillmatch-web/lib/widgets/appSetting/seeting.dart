import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillmatch_platform/widgets/appSetting/logout.dart';
import 'package:skillmatch_platform/widgets/appSetting/theremeProv.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Static values for demonstration - these would be dynamic in the future
  bool pushNotifications = true;
  bool emailNotifications = false;
  bool profileVisible = true;
  bool twoFactorAuth = false;
  bool autoPlayVideos = false;
  bool jobSearchActive = true;
  String selectedLanguage = 'English';
  String selectedRegion = 'United States';
  String notificationFrequency = 'Instant';

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Coming Soon'),
          content: const Text(
            'This feature will be available in a future update.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap ?? _showComingSoonDialog,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Account Settings Section
            _buildSectionHeader('Account Settings', Icons.person_outline),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'Profile Visible to Public',
                    subtitle: 'Allow others to find your profile',
                    icon: Icons.visibility_outlined,
                    value: profileVisible,
                    onChanged:
                        (value) => setState(() => profileVisible = value),
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Edit Profile',
                    subtitle: 'Update your personal information',
                    icon: Icons.edit_outlined,
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Privacy Settings',
                    subtitle: 'Control who can see your information',
                    icon: Icons.lock_outline,
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Data Export',
                    subtitle: 'Download your data',
                    icon: Icons.download_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notification Settings Section
            _buildSectionHeader('Notifications', Icons.notifications_outlined),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'Push Notifications',
                    subtitle: 'Receive notifications on your device',
                    icon: Icons.notifications_active_outlined,
                    value: pushNotifications,
                    onChanged:
                        (value) => setState(() => pushNotifications = value),
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: 'Email Notifications',
                    subtitle: 'Receive notifications via email',
                    icon: Icons.email_outlined,
                    value: emailNotifications,
                    onChanged:
                        (value) => setState(() => emailNotifications = value),
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Notification Frequency',
                    subtitle: notificationFrequency,
                    icon: Icons.schedule_outlined,
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Customize Notifications',
                    subtitle: 'Choose what you want to be notified about',
                    icon: Icons.tune_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Privacy & Security Section
            _buildSectionHeader('Privacy & Security', Icons.security_outlined),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'Two-Factor Authentication',
                    subtitle: 'Add an extra layer of security',
                    icon: Icons.security_outlined,
                    value: twoFactorAuth,
                    onChanged: (value) => setState(() => twoFactorAuth = value),
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    icon: Icons.lock_reset_outlined,
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Login History',
                    subtitle: 'View recent login activity',
                    icon: Icons.history_outlined,
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Connected Apps',
                    subtitle: 'Manage third-party app connections',
                    icon: Icons.apps_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Communication Settings Section
            _buildSectionHeader('Communication', Icons.chat_outlined),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildSettingTile(
                    title: 'Message Settings',
                    subtitle: 'Control who can message you',
                    icon: Icons.message_outlined,
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Video Call Preferences',
                    subtitle: 'Set your video calling preferences',
                    icon: Icons.videocam_outlined,
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Contact Preferences',
                    subtitle: 'Manage how others can reach you',
                    icon: Icons.contact_phone_outlined,
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Blocked Users',
                    subtitle: 'Manage your blocked users list',
                    icon: Icons.block_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // App Preferences Section
            _buildSectionHeader('App Preferences', Icons.settings_outlined),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.dark_mode_outlined,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Switch between light and dark theme'),
                    value: themeProvider.isDarkMode,
                    onChanged: (_) {
                      themeProvider.toggleTheme();
                    },
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    title: 'Auto-play Videos',
                    subtitle: 'Automatically play videos in feed',
                    icon: Icons.play_circle_outline,
                    value: autoPlayVideos,
                    onChanged:
                        (value) => setState(() => autoPlayVideos = value),
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Language',
                    subtitle: selectedLanguage,
                    icon: Icons.language_outlined,
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Region',
                    subtitle: selectedRegion,
                    icon: Icons.location_on_outlined,
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Time Zone',
                    subtitle: 'Set your local time zone',
                    icon: Icons.access_time_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Professional Settings Section
            _buildSectionHeader('Professional', Icons.work_outline),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'Job Search Active',
                    subtitle:
                        'Let recruiters know you\'re open to opportunities',
                    icon: Icons.work_outline,
                    value: jobSearchActive,
                    onChanged:
                        (value) => setState(() => jobSearchActive = value),
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Job Preferences',
                    subtitle: 'Set your job search criteria',
                    icon: Icons.tune_outlined,
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Industry Preferences',
                    subtitle: 'Select your preferred industries',
                    icon: Icons.business_outlined,
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Salary Expectations',
                    subtitle: 'Set your salary preferences',
                    icon: Icons.attach_money_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Help & Support Section
            _buildSectionHeader('Help & Support', Icons.help_outline),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildSettingTile(
                    title: 'Help Center',
                    subtitle: 'Find answers to common questions',
                    icon: Icons.help_center_outlined,
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Contact Support',
                    subtitle: 'Get help from our support team',
                    icon: Icons.support_agent_outlined,
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Report a Problem',
                    subtitle: 'Report bugs or issues',
                    icon: Icons.bug_report_outlined,
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Send Feedback',
                    subtitle: 'Help us improve the app',
                    icon: Icons.feedback_outlined,
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Terms & Privacy',
                    subtitle: 'Read our terms and privacy policy',
                    icon: Icons.article_outlined,
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'About',
                    subtitle: 'App version and information',
                    icon: Icons.info_outline,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Account Actions Section
            _buildSectionHeader('Account Actions', Icons.exit_to_app_outlined),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  LogoutButton(),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Deactivate Account',
                    subtitle: 'Temporarily disable your account',
                    icon: Icons.pause_circle_outline,
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.orange,
                    ),
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account',
                    icon: Icons.delete_forever_outlined,
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
