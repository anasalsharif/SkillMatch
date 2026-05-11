//new api all fixed i used api.env

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import './comment_widget.dart';
import 'reply/comment_input_widget.dart';
import './comment_service.dart';

final String baseUrl = dotenv.env['BASE_URL']!;

class CommentsSection extends StatefulWidget {
  final List<Map<String, dynamic>> comments;
  final String currentUserAvatar;
  final String currentUserName;
  final Future<void> Function(Map<String, dynamic>) onCommentAdded;
  final Future<void> Function(int, Map<String, dynamic>) onReplyAdded;
  final String postId;
  final String token;

  const CommentsSection({
    super.key,
    required this.comments,
    required this.currentUserAvatar,
    required this.currentUserName,
    required this.onCommentAdded,
    required this.onReplyAdded,
    required this.postId,
    required this.token,
  });

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final TextEditingController _commentController = TextEditingController();
  int? _replyingToCommentIndex;
  late CommentService _commentService;

  @override
  void initState() {
    super.initState();
    _commentService = CommentService(
      baseUrl: baseUrl,
      token: widget.token,
      postId: widget.postId,
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSend(String text) async {
    if (text.trim().isEmpty) return;

    try {
      if (_replyingToCommentIndex != null) {
        final comment = widget.comments[_replyingToCommentIndex!];
        final commentId = comment['_id'];
        await _commentService.addReply(commentId, text);

        final newReply = {
          'text': text,
          'author': widget.currentUserName,
          'avatarUrl': widget.currentUserAvatar,
        };

        if (mounted) {
          setState(() {
            comment['replies'].add(newReply);
          });
        }
      } else {
        await _commentService.addComment(text);

        final newComment = {
          'text': text,
          'author': widget.currentUserName,
          'avatarUrl': widget.currentUserAvatar,
          'replies': [],
        };

        if (mounted) {
          setState(() {
            widget.comments.add(newComment);
          });
        }
      }

      if (mounted) {
        setState(() {
          _commentController.clear();
          _replyingToCommentIndex = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.comments.asMap().entries.map((entry) {
          final index = entry.key;
          final comment = entry.value;
          final isReplying = _replyingToCommentIndex == index;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommentWidget(
                author: comment['author'],
                text: comment['text'],
                avatarUrl: comment['avatarUrl'] ?? widget.currentUserAvatar,
                onReply: () {
                  setState(() {
                    _replyingToCommentIndex = index;
                    _commentController.clear();
                  });
                },
              ),
              if (comment['replies'] != null && comment['replies'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 40.0),
                  child: Column(
                    children:
                        (comment['replies'] as List).map<Widget>((reply) {
                          return CommentWidget(
                            author: reply['author'],
                            text: reply['text'],
                            avatarUrl:
                                reply['avatarUrl'] ?? widget.currentUserAvatar,
                            isMainComment: false,
                          );
                        }).toList(),
                  ),
                ),
              if (isReplying)
                CommentInputWidget(
                  controller: _commentController,
                  onSubmit: _handleSend,
                  isReplyingToComment: true,
                  hintText: "Write your reply...",
                  onTap: () {},
                ),
            ],
          );
        }),

        // Global comment box
        if (_replyingToCommentIndex == null)
          CommentInputWidget(
            controller: _commentController,
            onSubmit: _handleSend,
            hintText: "Write a comment...",
            onTap: () {
              if (_replyingToCommentIndex != null) {
                setState(() {
                  _replyingToCommentIndex = null;
                });
              }
            },
          ),
      ],
    );
  }
}
