//new api all fixed i used api.env

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillmatch_platform/models/job.dart';
import 'package:skillmatch_platform/services/job_service.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/jobs_screen_tabs/job_details_screen.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/notifications/nofitifcationForOrg/applicationShowOneCard.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/notifications/single_post_piew_for_notification.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/post_sections/post_card.dart';
import 'package:logger/logger.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/post_sections/profile_widget_for_another_users.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/organization_hom_tabs/applications_tab.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/organization_hom_tabs/meeting/joinMeeting.dart';

final String baseUrl = dotenv.env['BASE_URL']!;

class NotificationNavigator {
  final BuildContext context;
  final _logger = Logger();

  NotificationNavigator(this.context);
  //192.168.1.7
  // final String baseUrl = 'http://192.168.1.7:5000/api';
  List<Map<String, dynamic>> posts = [];

  void navigateBasedOnType(Map notification) async {
    debugPrint('Notification received: ${notification.toString()}');

    final String type = notification['type'] ?? 'unknown';
    final String myJobId = notification['jobId'] ?? '';
    final String postId = notification['postId'] ?? '';

    final String meetingId = notification['meetingId'] ?? '';
    final String meetingLink = notification['meetingLink'] ?? '';
    final String scheduledDateTime = notification['scheduledDateTime'] ?? '';
    final sender = notification['sender'] ?? '';
    final String applicationId = notification['applicationId'] ?? '';
    // final String applicationId = "682bd851ce530c79f046df7d";
    switch (type) {
      case 'job':
        _navigateToJobDetails(myJobId);
        break;

      case 'like':
        _navigateToPost(postId, type);
        break;

      case 'comment':
        _navigateToPost(postId, type);
        break;

      case 'reply':
        _navigateToPost(postId, type);
        break;

      case 'post':
        _navigateToPost(postId, type);
        break;

      case 'follower': // Changed to lowercase to match
        _navigateToFollower(sender, type);
        break;
      case 'meeting':
        _navigateToMeeting(meetingId, meetingLink, scheduledDateTime);
        break;

      case 'applyjob':
        _navigateToJobDetailsForOrg(applicationId);
        break;

      default:
        _showUnsupportedTypeMessage(type);
        break;
    }
  }

  Future<void> _navigateToJobDetailsForOrg(String applicationId) async {
    try {
      _showLoadingDialog();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ApplicationDetailPage(
                token: token,
                applicationId: applicationId,
              ),
        ),
      );
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showErrorMessage('error loading application: $e');
    }
  }

  Future<void> _navigateToFollower(String sender, String type) async {
    try {
      _showLoadingDialog();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // Fetch the follower's username first
      // final userResponse = await http.get(
      //   Uri.parse('$baseUrl/users/$senderId'),
      //   headers: {'Authorization': 'Bearer $token'},
      // );
      final userData = sender;

      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Dismiss loading dialog
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ProfileWidgetForAnotherUsers(
                username: userData,
                token: token,
              ),
        ),
      );
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      _logger.e("Error in _navigateToFollower", error: e);
      _showErrorMessage('Error loading profile: ${e.toString()}');
    }
  }

  Future<void> _navigateToMeeting(
    String meetingId,
    String meetingLink,
    String scheduledDateTime,
  ) async {
    print('haaaaaaaaaaaaaaaaaaaaaaaa: $meetingId');
    print('meetingLink: $meetingLink');
    print('scheduledDateTime: $scheduledDateTime');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => JoinMeetingPage(
              meetingId: meetingId,
              meetingLink: meetingLink,
              scheduledDateTime: scheduledDateTime,
            ),
      ),
    );
  }

  //done100%
  Future<void> _navigateToJobDetails(String jobId) async {
    try {
      _showLoadingDialog();
      _showPlaceholderMessage('check jobId: $jobId');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final jobService = JobService(token: token);

      final Job job = await jobService.fetchJobById(
        jobId,
      ); //error here need to make fetchJob by id

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JobDetailsScreen(job: job, token: token),
        ),
      );
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      _showErrorMessage('error loading job: $e');
    }
  }

  Future<void> _navigateToPost(String postId, String type) async {
    try {
      _showPlaceholderMessage('check postid: $postId');

      if (type == 'like' || type == 'comment' || type == 'reply') {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token') ?? '';
        String apiUrl = '$baseUrl/posts/$postId';

        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          final post = data;
          final comments = List<Map<String, dynamic>>.from(
            post['comments']?.map(
                  (c) => {
                    '_id': c['_id'],
                    'text': c['text'],
                    'author':
                        c['author'] is Map<String, dynamic>
                            ? c['author']['fullName'] ?? 'Unknown'
                            : c['author'],
                    'avatarUrl': c['avatarUrl'] ?? '',
                    'replies': List<Map<String, dynamic>>.from(
                      c['replies']?.map(
                            (r) => {
                              '_id': r['_id'],
                              'text': r['text'],
                              'author': r['author'],
                              'avatarUrl': r['avatarUrl'] ?? '',
                            },
                          ) ??
                          [],
                    ),
                  },
                ) ??
                [],
          );

          void handlePostLiked(int index) {
            post['isLiked'] = !post['isLiked'];
            if (post['isLiked']) {
              post['likeCount']++;
            } else {
              post['likeCount']--;
            }
          }

          void handleShowComments(int postIndex) async {
            if (post['comments'] == null) {
              post['comments'] = [];
            }
          }

          _logger.d(
            'Post details:',
            error: {
              'postId': post['_id'],
              'content': post['content'],
              'author': post['author'],
              'username': post['username'],
              'avatar': post['avatarUrl'],
            },
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ViewSinglePostCard(
                    postCard: PostCard(
                      postId: post['_id'] ?? '',
                      postText: post['content'] ?? '',
                      authorName: post['author'] ?? 'Unknown',
                      timestamp:
                          DateTime.tryParse(post['createdAt']) ??
                          DateTime.now(),
                      authorAvatarUrl: post['avatarUrl'] ?? '',
                      isOwner: true,
                      isLiked: (post['likes'] as List).contains('username'),
                      likeCount: (post['likes'] as List).length,
                      onLike: () => handlePostLiked(0),
                      onComment: () => handleShowComments(0),
                      currentUserAvatar: post['avatarUrl'] ?? '',
                      currentUserName: post['author'] ?? 'Anonymous',
                      token: token,
                      username: post['username'] ?? 'unknown',
                      initialComments: comments,
                    ),
                  ),
            ),
          );
        } else {
          _logger.e(
            "Failed to fetch $type:",
            error: "Status code: ${response.statusCode}",
          );
        }
      } else {
        _logger.w('Invalid type: $type');
      }
    } catch (e) {
      _logger.e("Error navigating to $type:", error: e);
    }
  } //   _showPlaceholderMessage('Navigate to post with like: $postId');
  // }

  // Future<void> _navigateToPostWithComment(String postId) async {
  //   _showPlaceholderMessage('Navigate to post with comment: $postId');
  // }

  // Future<void> _navigateToCommentWithReply(String commentId) async {
  //   _showPlaceholderMessage('Navigate to comment with reply: $commentId');
  // }

  // Future<void> _navigateToPost(String postId) async {
  //   _showPlaceholderMessage('Navigate to post: $postId');
  // }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showPlaceholderMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 2)),
    );
  }

  /// Show message for unsupported notification types
  void _showUnsupportedTypeMessage(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification type not supported: $type')),
    );
  }
}
