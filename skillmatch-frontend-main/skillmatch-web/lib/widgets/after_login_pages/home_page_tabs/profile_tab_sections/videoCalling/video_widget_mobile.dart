import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_video_conference/zego_uikit_prebuilt_video_conference.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoWidget extends StatefulWidget {
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
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  final _logger = Logger();
  bool isCallAccepted = false;
  bool isCallRejected = false;
  bool isCallEnded = false;
  Timer? callTimer;
  String callStatus = 'Calling...';
  bool _permissionsGranted = false;

  // Generate a unique conference ID for the call
  String get conferenceID => widget.conferenceID;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    try {
      // Request camera and microphone permissions
      Map<Permission, PermissionStatus> statuses =
          await [Permission.camera, Permission.microphone].request();

      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          allGranted = false;
        }
      });

      if (allGranted) {
        setState(() {
          _permissionsGranted = true;
        });

        _logger.i("Permissions granted, initializing call");

        // Register the user's socket connection
        widget.socket.emit('register', widget.currentUserId);

        if (widget.isInitiator) {
          _sendCallRequest();
          callStatus = 'Calling...';
        } else {
          _sendCallAccepted();
          setState(() {
            isCallAccepted = true;
            callStatus = 'Connected';
          });
        }

        _setupSocketListeners();
      } else {
        _logger.e("Permissions not granted");
        setState(() {
          callStatus = 'Permissions Required';
        });
        // Show error message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Camera and microphone permissions are required for video calls',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      _logger.e("Error requesting permissions", error: e);
    }
  }

  void _setupSocketListeners() {
    // Listen for call accepted event
    widget.socket.on('callAccepted', (data) {
      _logger.i("Call accepted event received: $data");

      // Check if this event is for our call
      if (data != null &&
          ((data['callerId'] == widget.currentUserId &&
                  data['receiverId'] == widget.peerUserId) ||
              (data['callerId'] == widget.peerUserId &&
                  data['receiverId'] == widget.currentUserId))) {
        _logger.i("Call accepted by peer, joining conference");

        setState(() {
          isCallAccepted = true;
          callStatus = 'Connected';
        });
      }
    });

    // Listen for call rejected event
    widget.socket.on('callRejected', (data) {
      if (data['callerId'] == widget.currentUserId &&
          data['receiverId'] == widget.peerUserId) {
        setState(() {
          isCallRejected = true;
          callStatus = 'Call Rejected';
        });
        // Navigate back after a short delay
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pop(context);
        });
      }
    });

    // Listen for call ended event
    widget.socket.on('callEnded', (data) {
      if (!mounted) return;

      if ((data['callerId'] == widget.currentUserId &&
              data['receiverId'] == widget.peerUserId) ||
          (data['callerId'] == widget.peerUserId &&
              data['receiverId'] == widget.currentUserId)) {
        if (!isCallEnded) {
          // Prevent duplicate handling
          setState(() {
            isCallEnded = true;
            callStatus = 'Call Ended';
          });

          Future.delayed(Duration(seconds: 1), () {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
        }
      }
    });
  }

  void _sendCallRequest() {
    final callData = {
      'callerId': widget.currentUserId,
      'receiverId': widget.peerUserId,
      'callerName': 'User_${widget.currentUserId}', // Make sure this is set
      'conferenceId': widget.conferenceID, // Use the passed conferenceID
      'timestamp': DateTime.now().toIso8601String(),
    };

    _logger.i("Sending call request with data: $callData"); // Add logging
    widget.socket.emit('callRequest', callData);
  }

  void _sendCallAccepted() {
    final callData = {
      'callerId': widget.peerUserId,
      'receiverId': widget.currentUserId,
      'conferenceId': widget.conferenceID,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _logger.i("Sending call accepted: $callData");
    widget.socket.emit('callAccepted', callData);
  }

  void _sendCallRejected() {
    final callData = {
      'callerId': widget.peerUserId,
      'receiverId': widget.currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    widget.socket.emit('callRejected', callData);
  }

  void _sendCallEnded() async {
    if (isCallEnded) return;

    try {
      if (mounted) {
        setState(() {
          isCallEnded = true;
          callStatus = 'Call Ended';
        });
      }

      final callData = {
        'callerId': widget.currentUserId,
        'receiverId': widget.peerUserId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Add retry logic
      bool sentSuccessfully = false;
      int attempts = 0;

      while (!sentSuccessfully && attempts < 3) {
        try {
          if (widget.socket.connected) {
            widget.socket.emit('callEnded', callData);
            _logger.i("Call ended event emitted successfully");
            sentSuccessfully = true;
          } else {
            _logger.w(
              "Attempt ${attempts + 1}: Socket not connected, trying to reconnect",
            );
            widget.socket.connect();
            await Future.delayed(Duration(milliseconds: 500 * (attempts + 1)));
          }
        } catch (e) {
          _logger.e("Attempt ${attempts + 1} failed", error: e);
          attempts++;
          await Future.delayed(Duration(milliseconds: 500 * (attempts + 1)));
        }
      }

      if (!sentSuccessfully) {
        _logger.e("Failed to send call ended event after 3 attempts");
      }

      if (mounted) {
        await Future.delayed(Duration(milliseconds: 300));
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (e, stackTrace) {
      _logger.e("Error in _sendCallEnded", error: e, stackTrace: stackTrace);
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  void _startCallTimeoutTimer() {
    callTimer = Timer(Duration(seconds: 30), () {
      if (!isCallAccepted && !isCallRejected && !isCallEnded) {
        setState(() {
          callStatus = 'No Answer';
        });
        _sendCallEnded();
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pop(context);
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel any pending timers
    callTimer?.cancel();

    // Remove socket listeners to prevent duplicate calls
    widget.socket.off('callAccepted');
    widget.socket.off('callRejected');
    widget.socket.off('callEnded');

    // Ensure call is properly ended if widget disposes
    if (!isCallEnded) {
      _sendCallEnded();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionsGranted) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 60),
              SizedBox(height: 20),
              Text(
                'Camera and microphone permissions are required',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _requestPermissions,
                child: Text('Grant Permissions'),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        _sendCallEnded();
        await Future.delayed(const Duration(milliseconds: 300));
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            if (isCallAccepted)
              ZegoUIKitPrebuiltVideoConference(
                appID: 871480527,
                appSign:
                    'eb6aebf3c532a731f17deb12859b8a25790b9d8fdff4ffc5e9bc009e1fa42435',
                userID: widget.currentUserId,
                userName: widget.peerUsername,
                conferenceID: widget.conferenceID,
                config: ZegoUIKitPrebuiltVideoConferenceConfig(
                  onLeaveConfirmation: (context) async {
                    try {
                      setState(() {
                        isCallEnded = true;
                        callStatus = 'Call Ended';
                      });

                      if (widget.socket.connected) {
                        final callData = {
                          'callerId': widget.currentUserId,
                          'receiverId': widget.peerUserId,
                          'timestamp': DateTime.now().toIso8601String(),
                        };
                        widget.socket.emit('callEnded', callData);
                      }
                      return true;
                    } catch (e) {
                      _logger.e("Error in onLeaveConfirmation", error: e);
                      return true;
                    }
                  },
                  audioVideoViewConfig: ZegoPrebuiltAudioVideoViewConfig(
                    foregroundBuilder: (
                      BuildContext context,
                      Size size,
                      ZegoUIKitUser? user,
                      Map extraInfo,
                    ) {
                      return Positioned(
                        bottom: 5,
                        left: 5,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(0, 0, 0, 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user?.name ?? '',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      );
                    },
                  ),
                  turnOnMicrophoneWhenJoining: true,
                  turnOnCameraWhenJoining: true,
                  useSpeakerWhenJoining: true,
                ),
              ),

            if (!isCallAccepted && !isCallRejected && !isCallEnded)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        size: 80,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      widget.peerUsername,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      callStatus,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    SizedBox(height: 40),
                    if (widget.isInitiator)
                      GestureDetector(
                        onTap: () {
                          try {
                            _sendCallEnded();
                          } catch (e) {
                            _logger.e("Error ending call", error: e);
                            // Ensure we still navigate back
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            if (isCallRejected || isCallEnded)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      callStatus,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
