//new api all fixed i used api.env

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/post_sections/profile_widget_for_another_users.dart';
import 'comment_sections/comments_modal.dart';
import 'comment_sections/comments_section.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final String baseUrl = dotenv.env['BASE_URL']!;

class PostCard extends StatefulWidget {
  final String postId;
  final String postText;
  final String authorName;
  final DateTime timestamp;
  final String authorAvatarUrl;
  final VoidCallback? onDelete;
  final Function(String)? onUpdate;
  final bool isOwner;
  final bool isLiked;
  final int likeCount;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final List<Map<String, dynamic>> initialComments;
  final String currentUserAvatar;
  final String currentUserName;
  final String token;
  final String username;
  final GlobalKey<_PostCardState> _key;

  void handleLike() {
    _key.currentState?.handleLike();
  }

  PostCard({
    super.key,
    required this.postText,
    required this.authorName,
    required this.timestamp,
    required this.authorAvatarUrl,
    required this.postId,
    this.onDelete,
    this.onUpdate,
    required this.isOwner,
    required this.isLiked,
    required this.likeCount,
    required this.onLike,
    required this.onComment,
    required this.currentUserAvatar,
    required this.currentUserName,
    required this.token,
    this.initialComments = const [],
    required this.username,
  }) : _key = GlobalKey<_PostCardState>();

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  final _logger = Logger();
  late List<Map<String, dynamic>> comments;
  final TextEditingController _commentController = TextEditingController();
  late AnimationController _likeController;
  late Animation<double> _likeAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    comments = widget.initialComments;
    _likeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _likeController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _likeController.dispose();
    super.dispose();
  }

  Future<void> _showCommentModal() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => CommentsModal(
            comments: comments,
            currentUserAvatar: widget.currentUserAvatar,
            currentUserName: widget.currentUserName,
            postId: widget.postId,
            token: widget.token,
          ),
    );

    if (mounted) setState(() {});
  }

  Future<String> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? 'defaultUsername';
  }

  void _showPostOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isOwner)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Post'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog();
                  },
                ),
              if (widget.isOwner)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete Post',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete();
                  },
                ),
            ],
          ),
    );
  }

  void _showEditDialog() {
    final controller = TextEditingController(text: widget.postText);
    String currentText = controller.text;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: const Text('Edit Post'),
                content: TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    setState(() {
                      currentText = val;
                    });
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        widget.onUpdate != null && currentText.trim().isNotEmpty
                            ? () => widget.onUpdate!(currentText)
                            : null,
                    child: const Text('Save'),
                  ),
                ],
              ),
        );
      },
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Post?'),
            content: const Text('This action cannot be undone'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.onDelete!();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> handleLike() async {
    _likeController.forward().then((_) => _likeController.reverse());
    final url = Uri.parse('$baseUrl/posts/${widget.postId}/like-post');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'isLiked': !widget.isLiked}),
      );

      if (response.statusCode == 200) {
        widget.onLike();
      } else {
        _logger.e('Failed to like the post: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error while liking the post', error: e);
    }
  }

  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  _isHovered
                      ? Colors.grey.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
              spreadRadius: _isHovered ? 3 : 2,
              blurRadius: _isHovered ? 15 : 10,
              offset: Offset(0, _isHovered ? 4 : 3),
            ),
          ],
          border: Border.all(
            color:
                _isHovered
                    ? Colors.grey.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                        Theme.of(context).primaryColor.withOpacity(0.5),
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(widget.authorAvatarUrl),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final username = await getCurrentUsername();

                          if (widget.username == username) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ProfileTab(
                                      onLogout: () {},
                                      token: widget.token,
                                    ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ProfileWidgetForAnotherUsers(
                                      username: widget.username,
                                      token: widget.token,
                                    ),
                              ),
                            );
                          }
                        },
                        child: Text(
                          widget.authorName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E3E5C),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat(
                          'MMM d, y • h:mm a',
                        ).format(widget.timestamp),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (widget.isOwner)
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Color(0xFF8D9BB5)),
                    onPressed: _showPostOptions,
                  ),
              ],
            ),
            // Content
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.postText,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Color(0xFF2E3E5C),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Like count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          widget.isLiked
                              ? Colors.red.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 16,
                          color: widget.isLiked ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.likeCount}',
                          style: TextStyle(
                            color: widget.isLiked ? Colors.red : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    icon:
                        widget.isLiked ? Icons.favorite : Icons.favorite_border,
                    label: widget.isLiked ? 'Loved' : 'Love',
                    color: widget.isLiked ? Colors.red : Colors.grey[600]!,
                    onTap: handleLike,
                  ),
                  _buildActionButton(
                    icon: Icons.comment_outlined,
                    label: 'Comment',
                    color: Colors.grey[600]!,
                    onTap: _showCommentModal,
                  ),
                  _buildActionButton(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    color: Colors.grey[600]!,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            // Comments section
            if (comments.isNotEmpty) ...[
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CommentsSection(
                  comments: comments.take(2).toList(),
                  currentUserAvatar: widget.currentUserAvatar,
                  currentUserName: widget.currentUserName,
                  postId: widget.postId,
                  token: widget.token,
                  onCommentAdded: (newComment) async {
                    setState(() => comments.add(newComment));
                  },
                  onReplyAdded: (commentIndex, newReply) async {
                    setState(() {
                      comments[commentIndex]['replies'] ??= [];
                      comments[commentIndex]['replies'].add(newReply);
                    });
                  },
                ),
              ),
              if (comments.length > 2)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextButton(
                    onPressed: _showCommentModal,
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'View all ${comments.length} comments',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
