import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class VideoWidget extends StatelessWidget {
  final String currentUserId;
  final String peerUserId;
  final String peerUsername;
  final io.Socket socket;
  final bool isInitiator;
  final String conferenceID;

  const VideoWidget({
    super.key,
    required this.currentUserId,
    required this.peerUserId,
    required this.peerUsername,
    required this.socket,
    this.isInitiator = true,
    required this.conferenceID,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Call')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                'Video calling is available on the mobile app.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please run SkillMatch Platform on Android to use the live call screen.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
