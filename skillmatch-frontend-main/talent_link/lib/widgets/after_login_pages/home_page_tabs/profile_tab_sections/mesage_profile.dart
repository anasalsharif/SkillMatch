//new api all fixed i used api.env

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:skillmatch_platform/services/socket_service.dart';
import 'package:skillmatch_platform/services/message_service.dart';
import 'package:skillmatch_platform/services/search_page_services.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/messageBlocking.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/post_sections/profile_widget_for_another_users.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/videoCalling/call_notification.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/videoCalling/video_widget.dart';

final String baseUrl = dotenv.env['BASE_URL']!;

class SearchUserPage extends StatefulWidget {
  final String currentUserId;
  final String avatarUrl;
  final String token;

  const SearchUserPage({
    super.key,
    required this.currentUserId,
    required this.avatarUrl,
    required this.token,
  });

  @override
  SearchUserPageState createState() => SearchUserPageState();
}

class SearchUserPageState extends State<SearchUserPage> {
  TextEditingController searchController = TextEditingController();
  List<dynamic> searchResults = [];
  List<dynamic> chatHistory = [];

  String? uploadedImageUrl;
  final SearchPageService _service = SearchPageService();

  bool isSearching = false;
  Timer? timer;

  int finalcount = 0;

  @override
  void initState() {
    super.initState();
    fetchChatHistory();
    startTimerForRealTimeUpdate();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startTimerForRealTimeUpdate() {
    timer = Timer.periodic(Duration(seconds: 30), (Timer t) {
      setState(() {});
    });
  }

  Future<void> fetchChatHistory() async {
    final history = await _service.fetchChatHistory(widget.currentUserId);

    // Get unread counts for each conversation
    final updatedHistory = await Future.wait(
      history.map((user) async {
        finalcount = await _service.getUnreadCount(
          widget.currentUserId,
          user['_id'],
        );
        return {...user, 'unreadCount': finalcount};
      }),
    );

    setState(() {
      chatHistory = updatedHistory;
    });
  }

  Future<void> searchUsers(String query) async {
    final results = await _service.searchUsers(query);
    setState(() {
      searchResults = results;
    });
  }

  Future<void> deleteChatHistory(String userId) async {
    bool success = await _service.deleteChatHistory(
      widget.currentUserId,
      userId,
    );
    if (success) {
      setState(() {
        chatHistory =
            chatHistory.where((user) => user['_id'] != userId).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Messages",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.of(context).pop(),
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.05),
              Colors.white,
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search users...",
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).primaryColor,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (query) {
                    if (query.isNotEmpty) {
                      setState(() {
                        isSearching = true;
                      });
                      searchUsers(query);
                    } else {
                      setState(() {
                        isSearching = false;
                      });
                      searchResults = [];
                    }
                  },
                ),
              ),
            ),
            // Content
            if (!isSearching) Expanded(child: buildChatHistory()),
            if (isSearching) Expanded(child: buildSearchResults()),
          ],
        ),
      ),
    );
  }

  Widget buildChatHistory() {
    if (chatHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              "No conversations yet",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Start chatting with other users",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: chatHistory.length,
      itemBuilder: (context, index) {
        final user = chatHistory[index];
        final lastChatTime = DateTime.parse(user['lastMessageTimestamp']);
        final timeDifference = DateTime.now().difference(lastChatTime);

        String timeDisplay;
        if (timeDifference.inMinutes < 1) {
          timeDisplay = 'Just now';
        } else if (timeDifference.inMinutes < 60) {
          timeDisplay = '${timeDifference.inMinutes}m ago';
        } else if (timeDifference.inHours < 24) {
          timeDisplay = '${timeDifference.inHours}h ago';
        } else {
          timeDisplay = '${timeDifference.inDays}d ago';
        }

        return Dismissible(
          key: Key(user['_id']),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            deleteChatHistory(user['_id']);
          },
          background: Container(
            margin: EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Icon(Icons.delete_outline, color: Colors.white, size: 28),
          ),
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (_) => ChatPage(
                            currentUserId: widget.currentUserId,
                            peerUserId: user['_id'],
                            peerUsername: user['username'],
                            currentuserAvatarUrl: widget.avatarUrl,
                            token: widget.token,
                            onChatClosed: () {
                              fetchChatHistory();
                            },
                          ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 22,
                                backgroundImage:
                                    user['avatarUrl'] != null &&
                                            user['avatarUrl'].isNotEmpty
                                        ? NetworkImage(user['avatarUrl'])
                                        : AssetImage(
                                              'assets/images/avatarPlaceholder.jpg',
                                            )
                                            as ImageProvider,
                              ),
                            ),
                          ),
                          //TODO: when user1 send a message to user2 i need the Count of notification (finalcount or unReadCount) to be in realTime that dont need to refresh the page to show the notifications
                          if ((user['unreadCount'] ?? 0) > 0) // here's
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  '${user['unreadCount']}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['username'],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Last active: $timeDisplay',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildSearchResults() {
    if (searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              "No users found",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Try searching with different keywords",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final user = searchResults[index];
        return Container(
          margin: EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (_) => ChatPage(
                          currentUserId: widget.currentUserId,
                          peerUserId: user['_id'],
                          peerUsername: user['username'],
                          token: widget.token,
                          currentuserAvatarUrl: widget.avatarUrl,
                          onChatClosed: () {
                            fetchChatHistory();
                          },
                        ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 22,
                          backgroundImage:
                              user['avatarUrl'] != null &&
                                      user['avatarUrl'].isNotEmpty
                                  ? NetworkImage(user['avatarUrl'])
                                  : AssetImage(
                                        'assets/images/avatarPlaceholder.jpg',
                                      )
                                      as ImageProvider,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['username'],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            user['email'],
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Chat",
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// chatPage
class ChatPage extends StatefulWidget {
  final String currentUserId;
  final String peerUserId;
  final String peerUsername;
  final VoidCallback onChatClosed;
  final String currentuserAvatarUrl;
  final String token;

  const ChatPage({
    super.key,
    required this.currentUserId,
    required this.peerUserId,
    required this.peerUsername,
    required this.onChatClosed,
    required this.currentuserAvatarUrl,
    required this.token,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final _logger = Logger();
  bool showCallNotification = false;
  Map<String, dynamic>? incomingCallData;
  TextEditingController messageController = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  bool show = true;
  bool isOnline = false;
  DateTime? lastSeen;

  late final SocketService socketService;
  late final MessageService2 messageService;
  String peerUsername = '';
  String peerAvatar = '';

  bool canMessage = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground - mark as online
        socketService.updatePresence(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App is in background - mark as offline
        socketService.updatePresence(false);
        break;
      case AppLifecycleState.hidden:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    socketService = SocketService();
    messageService = MessageService2();
    socketService.startHealthChecks();

    fetchPeerInfo();
    fetchMessages();
    initSocket();

    // Initialize status tracking
    _initializePresence();

    _markMessagesAsRead();
  }

  void _initializePresence() {
    // Listen for status updates
    socketService.listenForStatusUpdates((userId, onlineStatus) {
      if (userId == widget.peerUserId) {
        setState(() {
          isOnline = onlineStatus;
          if (!onlineStatus) {
            lastSeen = DateTime.now();
          }
        });
      }
    });

    // Fetch initial status
    _fetchInitialStatus();
  }

  Future<void> initSocket() async {
    final socketUrl = baseUrl.replaceAll('/api', '');
    if (socketService.isChatConnected) {
      socketService.chatSocket?.disconnect();
    }
    await socketService.connect(
      url: socketUrl,
      userId: widget.currentUserId,
      onMessage: (data) {
        final isDuplicate = messages.any(
          (msg) =>
              msg['message'] == data['message'] &&
              msg['senderId'] == data['senderId'] &&
              (msg['timestamp'] == data['timestamp'] ||
                  DateTime.parse(msg['timestamp'])
                          .difference(DateTime.parse(data['timestamp']))
                          .inSeconds
                          .abs() <
                      5),
        );

        if (!isDuplicate) {
          _handleIncomingMessage(data);
        }
      },

      onCallRequest: (data) {
        if (data['receiverId'] == widget.currentUserId) {
          setState(() {
            showCallNotification = true;
            incomingCallData = {
              'callerId': data['callerId'],
              'receiverId': data['receiverId'],
              'callerName': data['callerName'] ?? 'Unknown Caller',
              'conferenceId': data['conferenceId'] ?? 'default_conference',
              'timestamp':
                  data['timestamp'] ?? DateTime.now().toIso8601String(),
            };
          });
        }
      },
      onCallEnded: () {
        setState(() {
          showCallNotification = false;
          incomingCallData = null;
        });
      },
      onCallFailed: (reason) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Call failed: $reason"),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  Future<void> _fetchInitialStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/${widget.peerUserId}/status'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          isOnline = data['online'] ?? false;
          lastSeen =
              data['lastSeen'] != null
                  ? DateTime.parse(data['lastSeen'])
                  : null;
        });
      }
    } catch (e) {
      _logger.e('Error fetching initial status', error: e);
    }
  }

  Future<void> fetchPeerInfo() async {
    final data = await messageService.fetchPeerInfo(widget.peerUsername);
    if (data != null) {
      setState(() {
        peerUsername = data['name'] ?? 'Unknown';
        peerAvatar = data['avatarUrl'] ?? '';
      });
    } else {
      _logger.w('Failed to fetch peer info');
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    if (!mounted) return;

    // Check if this message is already in our list
    final isDuplicate = messages.any(
      (msg) =>
          msg['message'] == data['message'] &&
          msg['senderId'] == data['senderId'] &&
          (msg['timestamp'] == data['timestamp'] ||
              DateTime.parse(msg['timestamp'])
                      .difference(DateTime.parse(data['timestamp']))
                      .inSeconds
                      .abs() <
                  5),
    );

    if (!isDuplicate) {
      setState(() {
        messages.add({
          "senderId": data["senderId"],
          "receiverId": data["receiverId"],
          "message": data["message"],
          "timestamp": data["timestamp"] ?? DateTime.now().toIso8601String(),
        });
      });

      // If the message is from the peer, mark it as read
      if (data["senderId"] == widget.peerUserId) {
        _markMessagesAsRead();
      }
    }
  }

  Future<void> fetchMessages() async {
    final msgs = await messageService.fetchMessages(
      widget.currentUserId,
      widget.peerUserId,
    );
    setState(() {
      messages = msgs;
    });
  }

  bool isSending = false;

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    setState(() {
      isSending = true;
    });

    final text = messageController.text.trim();
    messageController.clear();

    try {
      if (!socketService.isChatConnected) {
        await initSocket();
      }

      final messageData = {
        'senderId': widget.currentUserId,
        'receiverId': widget.peerUserId,
        'message': text,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Add message to UI immediately (optimistic update)
      _handleIncomingMessage(messageData);

      // Send via socket
      socketService.emitChat("sendMessage", messageData);

      // Also save to database
      await messageService.sendMessage(messageData);
    } catch (e) {
      _logger.e("Error sending message", error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send message. Please try again.")),
      );
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    socketService.dispose();
    super.dispose();
  }

  void _initiateVideoCall() async {
    if (!socketService.isCallConnected) {
      _logger.w("⚠️ Call socket not connected, attempting to reconnect...");
      socketService.callSocket?.connect();
      await Future.delayed(Duration(seconds: 1));

      if (!socketService.isCallConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to connect to call service")),
        );
        return;
      }
    }

    final conferenceID =
        "${widget.currentUserId}_${widget.peerUserId}_${DateTime.now().millisecondsSinceEpoch}";

    final callData = {
      'callerId': widget.currentUserId,
      'receiverId': widget.peerUserId,
      'callerName': peerUsername,
      'conferenceId': conferenceID,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _logger.i("Initiating video call with data: $callData");

    socketService.emitCall('callRequest', callData);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => VideoWidget(
              currentUserId: widget.currentUserId,
              peerUserId: widget.peerUserId,
              peerUsername: peerUsername,
              socket: socketService.callSocket!, // ✅ Call namespace socket
              isInitiator: true,
              conferenceID: conferenceID,
            ),
      ),
    );
  }

  void _acceptCall() {
    _logger.d("Accepting call with data: $incomingCallData");

    try {
      if (incomingCallData == null) {
        _logger.e("No incoming call data available");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No active call to accept"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final callerId = incomingCallData?['callerId'];
      final callerName = incomingCallData?['callerName'] ?? 'Unknown Caller';
      final conferenceId =
          incomingCallData?['conferenceId'] ?? 'default_conference';

      if (callerId == null) {
        throw Exception("Caller ID is missing from call data");
      }

      setState(() {
        showCallNotification = false;
        incomingCallData = null;
      });

      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => VideoWidget(
                currentUserId: widget.currentUserId,
                peerUserId: callerId,
                peerUsername: callerName,
                socket: socketService.callSocket!, // ✅ Call namespace socket
                isInitiator: false,
                conferenceID: conferenceId,
              ),
        ),
      );
    } catch (e, stackTrace) {
      _logger.e("Error in _acceptCall", error: e, stackTrace: stackTrace);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error accepting call: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        showCallNotification = false;
        incomingCallData = null;
      });
    }
  }

  void _rejectCall() {
    if (incomingCallData != null) {
      final callData = {
        'callerId': incomingCallData!['callerId'],
        'receiverId': widget.currentUserId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      socketService.emitCall('callRejected', callData);
      _logger.i("Call rejected with data: $callData");
    }
  }

  void _markMessagesAsRead() async {
    bool success = await messageService.markMessagesAsRead(
      widget.currentUserId,
      widget.peerUserId,
    );

    if (success) {
      // Update local state to reflect read status
      setState(() {
        messages =
            messages.map((msg) {
              if (msg['receiverId'] == widget.currentUserId) {
                return {...msg, 'isRead': true};
              }
              return msg;
            }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => ProfileWidgetForAnotherUsers(
                        username: widget.peerUsername,
                        token: widget.token,
                      ),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Hero(
                  tag: 'avatar-$peerUsername',
                  child: Container(
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundImage:
                            peerAvatar.isNotEmpty
                                ? NetworkImage(peerAvatar)
                                : AssetImage(
                                      'assets/images/avatarPlaceholder.jpg',
                                    )
                                    as ImageProvider,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        peerUsername.isNotEmpty ? peerUsername : 'Loading...',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color:
                                  isOnline
                                      ? Colors.greenAccent
                                      : Colors.white.withOpacity(0.6),
                              shape: BoxShape.circle,
                              boxShadow:
                                  isOnline
                                      ? [
                                        BoxShadow(
                                          color: Colors.greenAccent.withOpacity(
                                            0.4,
                                          ),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                      : null,
                            ),
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              isOnline
                                  ? 'Online'
                                  : lastSeen != null
                                  ? 'Last seen ${DateFormat.jm().format(lastSeen!)}'
                                  : 'Offline',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.2,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
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
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              widget.onChatClosed();
              Navigator.of(context).pop();
            },
            color: Colors.white,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.videocam),
              onPressed: _initiateVideoCall,
              color: Colors.white,
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showChatOptions(context),
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.05),
              Colors.white,
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Chat Content
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Date indicator
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 16),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Today',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Messages List
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        var msg = messages[messages.length - 1 - index];
                        var isMe = msg['senderId'] == widget.currentUserId;
                        var time =
                            msg['timestamp'] != null
                                ? DateFormat(
                                  'hh:mm a',
                                ).format(DateTime.parse(msg['timestamp']))
                                : "";
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment:
                                isMe
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isMe)
                                Container(
                                  padding: EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).primaryColor,
                                        Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.7),
                                      ],
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundImage:
                                          peerAvatar.isNotEmpty
                                              ? NetworkImage(peerAvatar)
                                              : AssetImage(
                                                    'assets/images/avatarPlaceholder.jpg',
                                                  )
                                                  as ImageProvider,
                                    ),
                                  ),
                                ),
                              if (!isMe) SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isMe
                                            ? Theme.of(context).primaryColor
                                            : Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                      bottomLeft:
                                          isMe
                                              ? Radius.circular(20)
                                              : Radius.circular(4),
                                      bottomRight:
                                          isMe
                                              ? Radius.circular(4)
                                              : Radius.circular(20),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            isMe
                                                ? Theme.of(
                                                  context,
                                                ).primaryColor.withOpacity(0.3)
                                                : Colors.grey.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg['message'],
                                        style: TextStyle(
                                          color:
                                              isMe
                                                  ? Colors.white
                                                  : Colors.grey[800],
                                          fontSize: 15,
                                          height: 1.4,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            time,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  isMe
                                                      ? Colors.white
                                                          .withOpacity(0.8)
                                                      : Colors.grey[500],
                                            ),
                                          ),
                                          if (isMe)
                                            // TODO: when user1 send message to user2 and user2 is in chat i need to show for user 1 that user2 seen the message, i do that but i need it in realTime
                                            Padding(
                                              padding: EdgeInsets.only(left: 6),
                                              child: Icon(
                                                msg['isRead'] == true
                                                    ? Icons.done_all
                                                    : Icons.done,
                                                size: 14,
                                                color:
                                                    msg['isRead'] == true
                                                        ? Colors.white
                                                        : Colors.white
                                                            .withOpacity(0.6),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isMe) SizedBox(width: 8),
                              if (isMe)
                                Container(
                                  padding: EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).primaryColor,
                                        Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.7),
                                      ],
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundImage:
                                          widget.currentuserAvatarUrl != null &&
                                                  widget
                                                      .currentuserAvatarUrl
                                                      .isNotEmpty
                                              ? NetworkImage(
                                                widget.currentuserAvatarUrl,
                                              )
                                              : AssetImage(
                                                    'assets/images/avatarPlaceholder.jpg',
                                                  )
                                                  as ImageProvider,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Input Area
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: messageController,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                              ),
                              maxLines: null,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withOpacity(0.8),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.send_rounded, color: Colors.white),
                            onPressed: sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Call notification overlay
            if (showCallNotification && incomingCallData != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: CallNotification(
                    callerName:
                        incomingCallData!['callerName'] ?? 'Unknown Caller',
                    onDismiss: () {
                      setState(() {
                        showCallNotification = false;
                        incomingCallData = null;
                      });
                    },
                    onReject: _rejectCall,
                    onAccept: _acceptCall,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Add these helper methods to your class
void _showChatOptions(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder:
        (context) => Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.search,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                title: Text(
                  'Search in conversation',
                  style: TextStyle(color: Colors.grey[800]),
                ),
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.notifications, color: Colors.orange),
                ),
                title: Text(
                  'Mute notifications',
                  style: TextStyle(color: Colors.grey[800]),
                ),
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.delete_outline, color: Colors.red),
                ),
                title: Text('Clear chat', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
  );
}
