import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'package:skillmatch_platform/services/notification_service.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/notifications/notification_navigator.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  NotificationsPageState createState() => NotificationsPageState();
}

class NotificationsPageState extends State<NotificationsPage>
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
              String notificationType = 'post'; // Default type
              final title = notification.title?.toLowerCase() ?? '';
              final body = notification.body?.toLowerCase() ?? '';

              if (title.contains('follower') ||
                  body.contains('follower') ||
                  title.contains('following') ||
                  body.contains('following') ||
                  title.contains('started following')) {
                notificationType = 'follower';
              } else if (title.contains('like') || body.contains('like')) {
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
                'jobId': notification.jobId ?? 'No jobId',
                'postId': notification.postId ?? 'No postId',

                'sender': notification.sender ?? 'No sender',
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
                'postId': notification.postId,
                'read': notification.read ?? false,
              };
            }).toList();
        logger.d("Job notifications list", error: jobNotificationsList);

        jobNotifs.addAll(jobNotificationsList);
      }

      // Fetch meeting notifications (added to job notifications)
      final meetingNotifs =
          await _notificationService.fetchMeetingNotifications();
      if (mounted) {
        final meetingNotificationsList =
            meetingNotifs.map((notification) {
              return {
                'id': notification.id,
                'title': notification.title,
                'body': notification.body,
                'meetingId': notification.meetingId,
                'applicantId': notification.applicantId,
                'scheduledDateTime': notification.scheduledDateTime,
                'organizationId': notification.organizationId,
                'meetingLink': notification.meetingLink,
                'type': 'meeting',
                'read': notification.read ?? false,
                'timestamp': notification.scheduledDateTime ?? 'No date',
              };
            }).toList();
        logger.d("Meeting notifications list", error: meetingNotificationsList);

        jobNotifs.addAll(meetingNotificationsList);
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

    final primaryColor = Theme.of(context).primaryColor;
    switch (type) {
      case 'like':
        return Colors.pink;
      case 'comment':
        return Colors.blue;
      case 'reply':
        return Colors.green;
      case 'follower':
        return const Color.fromARGB(255, 175, 173, 76);
      case 'job':
        return primaryColor;
      case 'meeting':
        return primaryColor;
      default:
        return primaryColor;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark notification as read'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'Notifications',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.done_all_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: () {
                              setState(() {
                                for (var notification
                                    in communityNotifications) {
                                  notification['read'] = true;
                                }
                                for (var notification in jobNotifications) {
                                  notification['read'] = true;
                                }
                              });
                            },
                            tooltip: 'Mark all as read',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      controller: _tabController,
                      tabs: const [Tab(text: 'Community'), Tab(text: 'Jobs')],
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withOpacity(0.7),
                      indicatorColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child:
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
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
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
        ? _buildEmptyState()
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 80,
            color: Theme.of(context).primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete_rounded, color: Colors.white),
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
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).primaryColor,
            ),
          );
        },
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: isRead ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isRead ? Colors.transparent : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              _markAsRead(index, isCommunityTab);
              NotificationNavigator(context).navigateBasedOnType(notification);
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color:
                    isRead ? Colors.white : notificationColor.withOpacity(0.05),
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
                          color: notificationColor,
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
                              Text(
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
                              const SizedBox(height: 4),
                              Text(
                                notification['body'],
                                style: TextStyle(
                                  color: Colors.grey[600],
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
                                      fontWeight: FontWeight.w500,
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
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Mark as Read',
                                        style: TextStyle(
                                          color: notificationColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
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
  }
}
