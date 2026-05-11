// import 'package:flutter/material.dart';
// import 'package:skillmatch_platform/utils/AppLifecycleManager.dart';
// import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/videoCalling/videoWidget.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;

// class GlobalNotificationHandler extends StatelessWidget {
//   final Widget child;

//   const GlobalNotificationHandler({required this.child, super.key});

//   @override
//   Widget build(BuildContext context) {
//     final appProvider = AppLifecycleProvider.of(context);

//     if (appProvider == null) {
//       return child;
//     }

//     return StreamBuilder<Map<String, dynamic>>(
//       stream: appProvider.callStream,
//       builder: (context, snapshot) {
//         if (snapshot.hasData) {
//           final callData = snapshot.data!;
//           _showCallNotification(context, callData);
//         }

//         return StreamBuilder<Map<String, dynamic>>(
//           stream: appProvider.messageStream,
//           builder: (context, snapshot) {
//             if (snapshot.hasData) {
//               final message = snapshot.data!;
//               _showMessageNotification(context, message);
//             }

//             return child;
//           },
//         );
//       },
//     );
//   }

//   void _showCallNotification(
//     BuildContext context,
//     Map<String, dynamic> callData,
//   ) {
//     // Get the socket from your service or provider
//     // This is a placeholder - you need to get the actual socket instance
//     final socketService =
//         SocketService(); // Replace with your actual socket access method
//     final socket = socketService.getSocket();

//     // Show call notification regardless of current screen
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder:
//           (context) => AlertDialog(
//             title: Text("Incoming Call from ${callData['callerName']}"),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
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
//                             currentUserId: callData['receiverId'],
//                             peerUserId: callData['callerId'],
//                             peerUsername: callData['callerName'],
//                             isInitiator: false,
//                             conferenceID: callData['conferenceId'],
//                             socket: socket, // Pass the socket instance
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

//   void _showMessageNotification(
//     BuildContext context,
//     Map<String, dynamic> message,
//   ) {
//     // Show message notification if not already in chat
//     if (ModalRoute.of(context)?.settings.name != '/chat') {
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
// }

// // This is a placeholder - you should use your actual SocketService implementation
// class SocketService {
//   IO.Socket getSocket() {
//     // Return your socket instance
//     // This is just a placeholder
//     throw UnimplementedError(
//       'You need to implement this method to return your actual socket',
//     );
//   }
// }
