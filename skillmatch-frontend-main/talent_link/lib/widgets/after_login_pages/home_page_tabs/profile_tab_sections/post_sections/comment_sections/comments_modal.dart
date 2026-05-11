//new api all fixed i used api.env

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'comments_section.dart';
import 'comment_service.dart';

final String baseUrl = dotenv.env['BASE_URL']!;

class CommentsModal extends StatefulWidget {
  final List<Map<String, dynamic>> comments;
  final String currentUserAvatar;
  final String currentUserName;
  final String postId;
  final String token;

  const CommentsModal({
    super.key,
    required this.comments,
    required this.currentUserAvatar,
    required this.currentUserName,
    required this.postId,
    required this.token,
  });

  @override
  State<CommentsModal> createState() => _CommentsModalState();
}

class _CommentsModalState extends State<CommentsModal>
    with SingleTickerProviderStateMixin {
  late CommentService _commentService;
  late CommentService _replyService;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final TextEditingController _commentController = TextEditingController();
  String? _replyingToId;
  String? _replyingToAuthor;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _commentService = CommentService(
      baseUrl: baseUrl,
      token: widget.token,
      postId: widget.postId,
    );
    _replyService = CommentService(
      baseUrl: baseUrl,
      token: widget.token,
      postId: widget.postId,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleCommentAdded(String text) async {
    if (text.trim().isEmpty) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _commentService.addComment(text);
      if (mounted) {
        setState(() {
          widget.comments.add({
            '_id': result['_id'] ?? result['comment']?['_id'],
            'text': result['text'] ?? result['comment']?['text'] ?? text,
            'author': widget.currentUserName,
            'avatarUrl': widget.currentUserAvatar,
            'replies': [],
          });
          _commentController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add comment: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReplyAdded(
    int commentIndex,
    Map<String, dynamic> newReply,
  ) async {
    final text = newReply['text']?.toString().trim();
    if (text == null || text.isEmpty) {
      throw Exception('Reply text cannot be empty');
    }

    final commentId = widget.comments[commentIndex]['_id'];
    setState(() => _isLoading = true);
    try {
      final result = await _replyService.addReply(commentId, text);

      if (mounted) {
        setState(() {
          widget.comments[commentIndex]['replies'] ??= [];
          widget.comments[commentIndex]['replies'].add({
            '_id': result['_id'] ?? result['reply']?['_id'],
            'text': result['text'] ?? result['reply']?['text'] ?? text,
            'author': widget.currentUserName,
            'avatarUrl': widget.currentUserAvatar,
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add reply: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startReply(String commentId, String author) {
    setState(() {
      _replyingToId = commentId;
      _replyingToAuthor = author;
      _commentController.text = '';
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToId = null;
      _replyingToAuthor = null;
      _commentController.text = '';
    });
  }

  Future<void> _handleSubmit() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    if (_replyingToId != null) {
      // Handle reply
      final commentIndex = widget.comments.indexWhere(
        (c) => c['_id'] == _replyingToId,
      );
      if (commentIndex != -1) {
        await _handleReplyAdded(commentIndex, {'text': text});
        _cancelReply();
      }
    } else {
      // Handle new comment
      await _handleCommentAdded(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Main content with DraggableScrollableSheet
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0.0, 50.0 * (1.0 - _animation.value)),
              child: Opacity(
                opacity: _animation.value,
                child: DraggableScrollableSheet(
                  initialChildSize: 0.9,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Handle bar
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.dividerColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          // Header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.comment_outlined,
                                    color: theme.primaryColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Comments',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${widget.comments.length}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          // Comments section
                          Expanded(
                            child: Stack(
                              children: [
                                ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.only(
                                    bottom: 80,
                                  ), // Add padding for input field
                                  itemCount: widget.comments.length,
                                  itemBuilder: (context, index) {
                                    final comment = widget.comments[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                backgroundImage: NetworkImage(
                                                  comment['avatarUrl'] ?? '',
                                                ),
                                                radius: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      comment['author'] ?? '',
                                                      style: theme
                                                          .textTheme
                                                          .titleSmall
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      comment['text'] ?? '',
                                                      style:
                                                          theme
                                                              .textTheme
                                                              .bodyMedium,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    TextButton.icon(
                                                      onPressed:
                                                          () => _startReply(
                                                            comment['_id'],
                                                            comment['author'],
                                                          ),
                                                      icon: Icon(
                                                        Icons.reply,
                                                        size: 16,
                                                        color:
                                                            theme.primaryColor,
                                                      ),
                                                      label: Text(
                                                        'Reply',
                                                        style: TextStyle(
                                                          color:
                                                              theme
                                                                  .primaryColor,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      style: TextButton.styleFrom(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        minimumSize: Size.zero,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          if ((comment['replies'] as List?)
                                                  ?.isNotEmpty ??
                                              false)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 32,
                                                top: 8,
                                              ),
                                              child: Column(
                                                children: [
                                                  for (var reply
                                                      in comment['replies'])
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 4,
                                                          ),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          CircleAvatar(
                                                            backgroundImage:
                                                                NetworkImage(
                                                                  reply['avatarUrl'] ??
                                                                      '',
                                                                ),
                                                            radius: 16,
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  reply['author'] ??
                                                                      '',
                                                                  style: theme
                                                                      .textTheme
                                                                      .titleSmall
                                                                      ?.copyWith(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 2,
                                                                ),
                                                                Text(
                                                                  reply['text'] ??
                                                                      '',
                                                                  style:
                                                                      theme
                                                                          .textTheme
                                                                          .bodyMedium,
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
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                if (_isLoading)
                                  Container(
                                    color: theme.scaffoldBackgroundColor
                                        .withOpacity(0.7),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              theme.primaryColor,
                                            ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
        // Fixed bottom comment input
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyingToId != null)
                  Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          'Replying to ${_replyingToAuthor}',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _cancelReply,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 18,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText:
                              _replyingToId != null
                                  ? 'Write a reply...'
                                  : 'Write a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded),
                        color: Colors.white,
                        onPressed: _handleSubmit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
