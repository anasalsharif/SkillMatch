import 'package:flutter/material.dart';
import 'package:skillmatch_platform/services/notification_service.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/notifications/notification_navigator.dart';
import 'package:logger/logger.dart';

class OrgNotificationsPage extends StatefulWidget {
  const OrgNotificationsPage({super.key});

  @override
  OrgNotificationsPageState createState() => OrgNotificationsPageState();
}

class OrgNotificationsPageState extends State<OrgNotificationsPage>
    with TickerProviderStateMixin {
  List communityNotifications = [];
  List jobNotifications = [];
  bool isLoading = true;
  late AnimationController _animationController;
  late TabController _tabController;
  late NotificationService _notificationService;
  final _logger = Logger();

  Future<void> _fetchNotifications() async {
    try {
      List communityNotifs = [];
      List jobNotifs = [];

      // Fetch community notifications
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

      // Fetch job notifications
      final jobNotifsFromApi =
          await _notificationService.fetchApplyForJobNotifications();
      if (mounted) {
        final jobNotificationsList =
            jobNotifsFromApi.map((notification) {
              return {
                'id': notification.id,
                'title': notification.title,
                'body': notification.body,
                'timestamp': notification.timestamp,
                'type': 'applyjob',
                'jobId': notification.jobId,
                'sender': notification.sender,
                'postId': notification.postId,
                'read': notification.read ?? false,
                'applicationId': notification.applicationId,
              };
            }).toList();
        _logger.d('Job notifications list:', error: jobNotificationsList);

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
      _logger.e("Error fetching notifications", error: e);
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
        return Icons.favorite;
      case 'comment':
        return Icons.comment_bank_rounded;
      case 'reply':
        return Icons.reply;
      case 'friend':
        return Icons.person_add;
      case 'system':
        return Icons.system_update;
      case 'event':
        return Icons.event;
      case 'applyjob':
        return Icons.work;
      case 'post':
        return Icons.post_add;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type, bool read) {
    if (read) return Colors.grey;

    switch (type) {
      case 'message':
        return Colors.blue;
      case 'friend':
        return Colors.green;
      case 'system':
        return Colors.purple;
      case 'payment':
        return Colors.amber;
      case 'event':
        return Colors.red;
      case 'applyjob':
        return Colors.teal;
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

  Future<void> _markAsRead(int index, bool isCommunityTab) async {
    final notification =
        isCommunityTab
            ? communityNotifications[index]
            : jobNotifications[index];
    final notificationId = notification['id'];

    setState(() {
      if (isCommunityTab) {
        communityNotifications[index]['read'] = true;
      } else {
        jobNotifications[index]['read'] = true;
      }
    });

    try {
      await _notificationService.markAsRead(notificationId);
    } catch (e) {
      setState(() {
        if (isCommunityTab) {
          communityNotifications[index]['read'] = false;
        } else {
          jobNotifications[index]['read'] = false;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to mark notification as read')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Community'), Tab(text: 'Jobs')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              setState(() {
                for (var notification in communityNotifications) {
                  notification['read'] = true;
                }
                for (var notification in jobNotifications) {
                  notification['read'] = true;
                }
              });
            },
            tooltip: 'Mark all as read',
          ),
        ],
        elevation: 0,
      ),
      body:
          isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 60,
                      width: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Loading notifications...',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  // Community Tab
                  _buildNotificationList(true),
                  // Jobs Tab
                  _buildNotificationList(false),
                ],
              ),
    );
  }

  Widget _buildNotificationList(bool isCommunityTab) {
    final notifications =
        isCommunityTab ? communityNotifications : jobNotifications;

    return notifications.isEmpty
        ? _buildEmptyState()
        : RefreshIndicator(
          onRefresh: _handleRefresh,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
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

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 500 + (index * 100)),
          curve: Curves.easeOutQuint,
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Dismissible(
            key: Key(notification['id']),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              setState(() {
                if (isCommunityTab) {
                  communityNotifications.removeAt(index);
                } else {
                  jobNotifications.removeAt(index);
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Notification dismissed'),
                  action: SnackBarAction(
                    label: 'UNDO',
                    onPressed: () {
                      setState(() {
                        if (isCommunityTab) {
                          communityNotifications.insert(index, notification);
                        } else {
                          jobNotifications.insert(index, notification);
                        }
                      });
                    },
                  ),
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: isRead ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isRead ? Colors.transparent : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              color: isRead ? Colors.white : Colors.white,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  _markAsRead(index, isCommunityTab);
                  NotificationNavigator(
                    context,
                  ).navigateBasedOnType(notification);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _getNotificationColor(type, isRead).withOpacity(0.1),
                  ),
                  child: Stack(
                    children: [
                      if (!isRead)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getNotificationColor(type, false),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _getNotificationColor(
                                  type,
                                  isRead,
                                ).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getNotificationIcon(type),
                                color: _getNotificationColor(type, isRead),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notification['title'],
                                    style: TextStyle(
                                      fontWeight:
                                          isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification['body'],
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        notification['timestamp'],
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (!isRead)
                                        TextButton(
                                          onPressed:
                                              () => _markAsRead(
                                                index,
                                                isCommunityTab,
                                              ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 0,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          child: Text(
                                            'Mark as Read',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontSize: 12,
                                            ),
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
}
