import 'package:flutter/material.dart';

class CommentWidget extends StatefulWidget {
  final String author;
  final String text;
  final String avatarUrl;
  final bool isMainComment;
  final VoidCallback? onReply;

  const CommentWidget({
    super.key,
    required this.author,
    required this.text,
    required this.avatarUrl,
    this.isMainComment = true,
    this.onReply,
  });

  @override
  State<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
      if (isHovered) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: widget.isMainComment ? 0 : 32, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              radius: widget.isMainComment ? 16 : 14,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: widget.isMainComment ? 14 : 12,
                backgroundImage: NetworkImage(
                  widget.avatarUrl.isNotEmpty
                      ? widget.avatarUrl
                      : 'https://randomuser.me/api/portraits/men/1.jpg',
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MouseRegion(
                  onEnter: (_) => _handleHover(true),
                  onExit: (_) => _handleHover(false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            _isHovered
                                ? Colors.grey.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                      ),
                      boxShadow:
                          _isHovered
                              ? [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                              : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.author,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: widget.isMainComment ? 14 : 13,
                            color: const Color(0xFF2E3E5C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.text,
                          style: TextStyle(
                            fontSize: widget.isMainComment ? 13 : 12,
                            color: const Color(0xFF2E3E5C),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.onReply != null && widget.isMainComment)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: TextButton(
                        onPressed: widget.onReply,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                        child: const Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
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
  }
}
