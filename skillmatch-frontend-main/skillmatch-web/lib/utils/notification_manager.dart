// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:skillmatch_platform/services/SocketService.dart';
// import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/videoCalling/videoWidget.dart';

// class NotificationManager extends StatefulWidget {
//   final Widget child;
//   final String? userId;

//   const NotificationManager({required this.child, this.userId, Key? key})
//     : super(key: key);

//   @override
//   State<NotificationManager> createState() => _NotificationManagerState();
// }

// class _NotificationManagerState extends State<NotificationManager> {
//   final SocketService _socketService = SocketService();

//   @override
//   void initState() {
//     super.initState();
//     _checkPendingNotifications();
//     _setupSocketListeners();
//   }

//   Future<void> _checkPendingNotifications() async {
//     final prefs = await SharedPreferences.getInstance();

//     // Check for pending calls
//     final pendingCall = prefs.getString('pending_call');
//     if (pendingCall != null) {
//       final callData = jsonDecode(pendingCall);
//       // Clear the pending call
//       await prefs.remove('pending_call');
//       // Show call notification
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _showCallNotification(callData);
//       });
//     }

//     // Check for pending messages
//     final pendingMessages = prefs.getStringList('pending_messages') ?? [];
//     if (pendingMessages.isNotEmpty) {
//       for (final messageJson in pendingMessages) {
//         final message = jsonDecode(messageJson);
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           _showMessageNotification(message);
//         });
//       }
//       // Clear pending messages
//       await prefs.setStringList('pending_messages', []);
//     }
//   }

//   void _setupSocketListeners() {
//     if (widget.userId == null) return;

//     // Listen for incoming calls
//     _socketService.onCallEvent('incomingCall', (data) {
//       _showCallNotification(data);
//     });

//     // Listen for new messages
//     _socketService.onChatEvent('newMessage', (data) {
//       _showMessageNotification(data);
//     });
//   }

//   void _showCallNotification(Map<String, dynamic> callData) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder:
//           (context) => AlertDialog(
//             title: Text("Incoming Call from ${callData['callerName']}"),
//             content: Text("Would you like to accept this call?"),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   // Emit call rejected event
//                   _socketService.emitCall('rejectCall', {
//                     'callerId': callData['callerId'],
//                     'receiverId': widget.userId,
//                     'conferenceId': callData['conferenceId'],
//                   });
//                 },
//                 child: Text("Reject"),
//               ),
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   // Navigate to call screen
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder:
//                           (context) => VideoWidget(
//                             currentUserId: widget.userId!,
//                             peerUserId: callData['callerId'],
//                             peerUsername: callData['callerName'],
//                             isInitiator: false,
//                             conferenceID: callData['conferenceId'],
//                             socket: _socketService.getCallSocket(),
//                           ),
//                     ),
//                   );
//                 },
//                 child: Text("Accept"),
//               ),
//             ],
//           ),
//     );
//   }

//   void _showMessageNotification(Map<String, dynamic> message) {
//     // Show message notification if not already in chat with this user
//     final currentRoute = ModalRoute.of(context)?.settings.name;
//     final currentChatId =
//         ModalRoute.of(context)?.settings.arguments is Map
//             ? (ModalRoute.of(context)?.settings.arguments as Map)['peerId']
//             : null;

//     if (currentRoute != '/chat' || currentChatId != message['senderId']) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("New message from ${message['senderName']}"),
//           action: SnackBarAction(
//             label: "View",
//             onPressed: () {
//               // Navigate to chat screen
//               Navigator.pushNamed(
//                 context,
//                 '/chat',
//                 arguments: {
//                   'peerId': message['senderId'],
//                   'peerName': message['senderName'],
//                 },
//               );
//             },
//           ),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return widget.child;
//   }
// }
