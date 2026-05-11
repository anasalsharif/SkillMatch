import 'package:flutter/material.dart';

class UserOptionsSheet extends StatelessWidget {
  final VoidCallback onViewProfile;
  final VoidCallback onMute;
  final VoidCallback onBlock;
  final VoidCallback onReport;

  const UserOptionsSheet({
    super.key,
    required this.onViewProfile,
    required this.onMute,
    required this.onBlock,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        _buildOptionTile(
          icon: Icons.person,
          title: 'View Profile',
          onTap: onViewProfile,
          color: Colors.blueAccent,
        ),
        _buildOptionTile(
          icon: Icons.volume_off,
          title: 'Mute',
          onTap: onMute,
          color: Colors.blueAccent,
        ),
        _buildOptionTile(
          icon: Icons.block,
          title: 'Block',
          onTap: onBlock,
          color: Colors.redAccent,
        ),
        _buildOptionTile(
          icon: Icons.report,
          title: 'Report',
          onTap: onReport,
          color: Colors.orangeAccent,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  ListTile _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      onTap: onTap,
    );
  }
}
