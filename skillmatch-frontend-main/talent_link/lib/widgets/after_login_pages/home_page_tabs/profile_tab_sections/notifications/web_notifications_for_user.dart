import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:skillmatch_platform/services/notification_service.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/notifications/notification_navigator.dart';
import 'package:skillmatch_platform/widgets/web_layouts/web_form_components.dart';

class WebNotificationsPage extends StatefulWidget {
  const WebNotificationsPage({super.key});

  @override
  WebNotificationsPageState createState() => WebNotificationsPageState();
}

class WebNotificationsPageState extends State<WebNotificationsPage>
    with TickerProviderStateMixin {
  List communityNotifications = [];
  List jobNotifications = [];
  bool isLoading = true;
  late AnimationController _animationController;
  late NotificationService _notificationService;
  final logger = Logger();
  late TabController _tabController;

  Future<void> _fetchNotifications() async {
    try {
      List communityNotifs = [];
      List jobNotifs = [];

      final userNotifications =
          await _notificationService.fetchUserNotificationsLikeCommentReply();
      if (mounted) {
        final userNotificationsList =
            userNotifications.map((notification) {
              String notificationType = 'post';
              final title = notification.title?.toLowerCase() ?? '';
              final body = notification.body?.toLowerCase() ?? '';

              if (title.contains('like') || body.contains('like')) {
                notificationType = 'like';
              } else if (title.contains('comment') ||
                  body.contains('comment')) {
                notificationType = 'comment';
              } else if (title.contains('reply') || body.contains('reply')) {
                notificationType = 'reply';
              }

              return {
                'id': notification.id,
                'title': notification.title,
                'body': notification.body,
                'timestamp': notification.timestamp,
                'read': notification.read ?? false,
                'type': notificationType,
                'jobId': notification.jobId,
                'sender': notification.sender,
                'postId': notification.postId,
              };
            }).toList();

        communityNotifs.addAll(userNotificationsList);
        communityNotifs.sort((a, b) {
          final aTime = DateTime.tryParse(a['timestamp']) ?? DateTime.now();
          final bTime = DateTime.tryParse(b['timestamp']) ?? DateTime.now();
          return bTime.compareTo(aTime);
        });
      }

      final jobNotifsFromApi =
          await _notificationService.fetchJobNotifications();
      if (mounted) {
        final jobNotificationsList =
            jobNotifsFromApi.map((notification) {
              return {
                'id': notification.id,
                'title': notification.title,
                'body': notification.body,
                'timestamp': notification.timestamp,
                'type': 'job',
                'jobId': notification.jobId,
                'sender': notification.sender,
                'postId': notification.postId,
                'read': notification.read ?? false,
              };
            }).toList();

        jobNotifs.addAll(jobNotificationsList);
      }

      if (mounted) {
        setState(() {
          communityNotifications = communityNotifs;
          jobNotifications = jobNotifs;
          isLoading = false;
        });
      }
    } catch (e) {
      logger.e("Error fetching notifications", error: e);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _tabController = TabController(length: 2, vsync: this);
    _fetchNotifications();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite_rounded;
      case 'comment':
        return Icons.comment_rounded;
      case 'reply':
        return Icons.reply_rounded;
      case 'follower':
        return Icons.person_add_rounded;
      case 'system':
        return Icons.system_update_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'job':
        return Icons.work_rounded;
      case 'post':
        return Icons.post_add_rounded;
      case 'meeting':
        return Icons.meeting_room;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String type, bool read) {
    if (read) return Colors.grey;

    switch (type) {
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.blue;
      case 'reply':
        return Colors.green;
      case 'follower':
        return Colors.purple;
      case 'system':
        return Colors.orange;
      case 'job':
        return Colors.teal;
      case 'meeting':
        return Colors.indigo;
      default:
        return Colors.blue;
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      isLoading = true;
    });
    await _fetchNotifications();
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tab Navigation
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Colors.grey[600],
                        indicatorColor: Theme.of(context).primaryColor,
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 16,
                        ),
                        tabs: [
                          Tab(
                            text:
                                'Community (${communityNotifications.length})',
                            icon: const Icon(Icons.people_outline, size: 20),
                          ),
                          Tab(
                            text: 'Jobs (${jobNotifications.length})',
                            icon: const Icon(Icons.work_outline, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLoading)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: _handleRefresh,
                        tooltip: 'Refresh Notifications',
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tab Content
            Expanded(
              child:
                  isLoading
                      ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Loading notifications...',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      )
                      : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildNotificationList(true),
                          _buildNotificationList(false),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(bool isCommunityTab) {
    final notifications =
        isCommunityTab ? communityNotifications : jobNotifications;

    return notifications.isEmpty
        ? _buildEmptyState(isCommunityTab)
        : RefreshIndicator(
          onRefresh: _handleRefresh,
          color: Theme.of(context).primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(
                notification,
                index,
                isCommunityTab,
              );
            },
          ),
        );
  }

  Widget _buildEmptyState(bool isCommunityTab) {
    return Center(
      child: WebCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCommunityTab ? Icons.people_outline : Icons.work_outline,
              size: 80,
              color: Theme.of(context).primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isCommunityTab
                  ? 'No community notifications'
                  : 'No job notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull down to refresh',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    Map notification,
    int index,
    bool isCommunityTab,
  ) {
    final bool isRead = notification['read'];
    final String type = notification['type'];
    final Color notificationColor = _getNotificationColor(type, isRead);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: WebCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final navigator = NotificationNavigator(context);
            navigator.navigateBasedOnType(notification);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: notificationColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getNotificationIcon(type),
                    color: notificationColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'],
                              style: TextStyle(
                                fontWeight:
                                    isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: notificationColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['body'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTimestamp(notification['timestamp']),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  onSelected: (value) {
                    if (value == 'delete') {
                      setState(() {
                        if (isCommunityTab) {
                          communityNotifications.removeAt(index);
                        } else {
                          jobNotifications.removeAt(index);
                        }
                      });
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
