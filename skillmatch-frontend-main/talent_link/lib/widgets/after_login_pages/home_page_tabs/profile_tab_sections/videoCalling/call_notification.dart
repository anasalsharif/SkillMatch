import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class CallNotification extends StatefulWidget {
  final String callerName;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onDismiss;

  const CallNotification({
    super.key,
    required this.callerName,
    required this.onAccept,
    required this.onReject,
    required this.onDismiss,
  });

  @override
  State<CallNotification> createState() => _CallNotificationState();
}

class _CallNotificationState extends State<CallNotification> {
  final logger = Logger();

  Future<void> _handleDecline() async {
    try {
      widget.onReject();
      widget.onDismiss();
    } catch (e) {
      logger.e("Error in decline button", error: e);
    }
  }

  Future<void> _handleAccept() async {
    try {
      widget.onAccept();
      widget.onDismiss();
    } catch (e) {
      logger.e("Error in accept button", error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Incoming call from ${widget.callerName}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _handleDecline,
                  child: const Text("Decline"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: _handleAccept,
                  child: const Text("Accept"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
