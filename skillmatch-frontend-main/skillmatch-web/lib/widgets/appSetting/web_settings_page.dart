import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillmatch_platform/widgets/appSetting/logout.dart';
import 'package:skillmatch_platform/widgets/appSetting/theremeProv.dart';
import 'package:skillmatch_platform/widgets/web_layouts/web_form_components.dart';
import 'package:skillmatch_platform/utils/responsive/responsive_layout.dart';
import 'package:skillmatch_platform/utils/auth_utils.dart';

class WebSettingsPage extends StatefulWidget {
  const WebSettingsPage({super.key});

  @override
  State<WebSettingsPage> createState() => _WebSettingsPageState();
}

class _WebSettingsPageState extends State<WebSettingsPage> {
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              const Text('Logout'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to logout?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will securely remove your FCM tokens and clear all session data.',
                        style: TextStyle(color: Colors.blue[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await AuthUtils.performCompleteLogout(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error during logout: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(context),
      desktop: _buildWebLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
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
            _buildMobileSectionHeader('Account Settings', Icons.person_outline),
            _buildMobileCard([
              _buildMobileSwitchTile(
                title: 'Profile Visible to Public',
                subtitle: 'Allow others to find your profile',
                icon: Icons.visibility_outlined,
                value: profileVisible,
                onChanged: (value) => setState(() => profileVisible = value),
              ),
              _buildMobileSettingTile(
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                icon: Icons.edit_outlined,
              ),
              _buildMobileSettingTile(
                title: 'Privacy Settings',
                subtitle: 'Control who can see your information',
                icon: Icons.lock_outline,
              ),
            ]),
            // Continue with other mobile sections...
          ],
        ),
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your account preferences and privacy settings',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Settings Grid
            Expanded(
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column
                    Expanded(
                      child: Column(
                        children: [
                          _buildWebSettingsSection(
                            'Account Settings',
                            Icons.person_outline,
                            [
                              _buildWebSwitchSetting(
                                'Profile Visibility',
                                'Allow others to find your profile in search',
                                Icons.visibility_outlined,
                                profileVisible,
                                (value) =>
                                    setState(() => profileVisible = value),
                              ),
                              _buildWebClickableSetting(
                                'Edit Profile',
                                'Update your personal information and bio',
                                Icons.edit_outlined,
                                _showComingSoonDialog,
                              ),
                              _buildWebClickableSetting(
                                'Privacy Settings',
                                'Control who can see your information',
                                Icons.lock_outline,
                                _showComingSoonDialog,
                              ),
                              _buildWebClickableSetting(
                                'Data Export',
                                'Download a copy of your data',
                                Icons.download_outlined,
                                _showComingSoonDialog,
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          _buildWebSettingsSection(
                            'Notifications',
                            Icons.notifications_outlined,
                            [
                              _buildWebSwitchSetting(
                                'Push Notifications',
                                'Receive notifications on your device',
                                Icons.notifications_active_outlined,
                                pushNotifications,
                                (value) =>
                                    setState(() => pushNotifications = value),
                              ),
                              _buildWebSwitchSetting(
                                'Email Notifications',
                                'Receive notifications via email',
                                Icons.email_outlined,
                                emailNotifications,
                                (value) =>
                                    setState(() => emailNotifications = value),
                              ),
                              _buildWebDropdownSetting(
                                'Notification Frequency',
                                'How often you receive notifications',
                                Icons.schedule_outlined,
                                notificationFrequency,
                                ['Instant', 'Hourly', 'Daily', 'Weekly'],
                                (value) => setState(
                                  () => notificationFrequency = value!,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          _buildWebSettingsSection(
                            'Professional',
                            Icons.work_outline,
                            [
                              _buildWebSwitchSetting(
                                'Job Search Active',
                                'Let recruiters know you\'re open to opportunities',
                                Icons.work_outline,
                                jobSearchActive,
                                (value) =>
                                    setState(() => jobSearchActive = value),
                              ),
                              _buildWebClickableSetting(
                                'Job Preferences',
                                'Set your job search criteria',
                                Icons.tune_outlined,
                                _showComingSoonDialog,
                              ),
                              _buildWebClickableSetting(
                                'Industry Preferences',
                                'Select your preferred industries',
                                Icons.business_outlined,
                                _showComingSoonDialog,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Right Column
                    Expanded(
                      child: Column(
                        children: [
                          _buildWebSettingsSection(
                            'Privacy & Security',
                            Icons.security_outlined,
                            [
                              _buildWebSwitchSetting(
                                'Two-Factor Authentication',
                                'Add an extra layer of security to your account',
                                Icons.security_outlined,
                                twoFactorAuth,
                                (value) =>
                                    setState(() => twoFactorAuth = value),
                              ),
                              _buildWebClickableSetting(
                                'Change Password',
                                'Update your account password',
                                Icons.lock_reset_outlined,
                                _showComingSoonDialog,
                              ),
                              _buildWebClickableSetting(
                                'Login History',
                                'View recent login activity',
                                Icons.history_outlined,
                                _showComingSoonDialog,
                              ),
                              _buildWebClickableSetting(
                                'Connected Apps',
                                'Manage third-party app connections',
                                Icons.apps_outlined,
                                _showComingSoonDialog,
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          _buildWebSettingsSection(
                            'App Preferences',
                            Icons.settings_outlined,
                            [
                              _buildWebSwitchSetting(
                                'Dark Mode',
                                'Switch between light and dark theme',
                                Icons.dark_mode_outlined,
                                themeProvider.isDarkMode,
                                (_) => themeProvider.toggleTheme(),
                              ),
                              _buildWebSwitchSetting(
                                'Auto-play Videos',
                                'Automatically play videos in feed',
                                Icons.play_circle_outline,
                                autoPlayVideos,
                                (value) =>
                                    setState(() => autoPlayVideos = value),
                              ),
                              _buildWebDropdownSetting(
                                'Language',
                                'Choose your preferred language',
                                Icons.language_outlined,
                                selectedLanguage,
                                ['English', 'Spanish', 'French', 'German'],
                                (value) =>
                                    setState(() => selectedLanguage = value!),
                              ),
                              _buildWebDropdownSetting(
                                'Region',
                                'Set your location preferences',
                                Icons.location_on_outlined,
                                selectedRegion,
                                [
                                  'United States',
                                  'Canada',
                                  'United Kingdom',
                                  'Australia',
                                ],
                                (value) =>
                                    setState(() => selectedRegion = value!),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          _buildWebSettingsSection(
                            'Help & Support',
                            Icons.help_outline,
                            [
                              _buildWebClickableSetting(
                                'Help Center',
                                'Find answers to common questions',
                                Icons.help_center_outlined,
                                _showComingSoonDialog,
                              ),
                              _buildWebClickableSetting(
                                'Contact Support',
                                'Get help from our support team',
                                Icons.support_agent_outlined,
                                _showComingSoonDialog,
                              ),
                              _buildWebClickableSetting(
                                'Send Feedback',
                                'Help us improve the app',
                                Icons.feedback_outlined,
                                _showComingSoonDialog,
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          _buildWebSettingsSection(
                            'Account Actions',
                            Icons.exit_to_app_outlined,
                            [
                              _buildWebDangerSetting(
                                'Sign Out',
                                'Sign out of your account',
                                Icons.logout_outlined,
                                () {
                                  _showLogoutDialog();
                                },
                              ),
                              _buildWebDangerSetting(
                                'Delete Account',
                                'Permanently delete your account',
                                Icons.delete_forever_outlined,
                                _showComingSoonDialog,
                                isDestructive: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebSettingsSection(
    String title,
    IconData icon,
    List<Widget> settings,
  ) {
    return WebCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...settings,
        ],
      ),
    );
  }

  Widget _buildWebSwitchSetting(
    String title,
    String description,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildWebClickableSetting(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildWebDropdownSetting(
    String title,
    String description,
    IconData icon,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            underline: Container(),
            items:
                options.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWebDangerSetting(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red[600] : Colors.orange[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color:
                          isDestructive ? Colors.red[600] : Colors.orange[600],
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: isDestructive ? Colors.red[400] : Colors.orange[400],
            ),
          ],
        ),
      ),
    );
  }

  // Mobile layout helper methods
  Widget _buildMobileSectionHeader(String title, IconData icon) {
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

  Widget _buildMobileCard(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: children),
    );
  }

  Widget _buildMobileSwitchTile({
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

  Widget _buildMobileSettingTile({
    required String title,
    String? subtitle,
    required IconData icon,
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
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap ?? _showComingSoonDialog,
    );
  }
}
