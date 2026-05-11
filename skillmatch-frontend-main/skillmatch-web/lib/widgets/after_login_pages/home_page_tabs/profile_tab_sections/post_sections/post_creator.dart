import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/post_sections/comment_sections/comments_modal.dart';

import './post_card.dart';
import './post_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:skillmatch_platform/services/post_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class PostCreator extends StatefulWidget {
  final String token;

  const PostCreator({super.key, required this.token});

  @override
  State<PostCreator> createState() => _PostCreatorState();
}

class _PostCreatorState extends State<PostCreator> {
  final TextEditingController _postController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late PostService _postService;
  String? uploadedImageUrl;
  String? fullName;
  String? username;
  List<Map<String, dynamic>> posts = [];
  int _page = 1;
  final int _limit = 10;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _postService = PostService(widget.token);
      fetchUserData();
      fetchPosts();
      _scrollController.addListener(_scrollListener);
      _hasInitialized = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      fetchPosts();
    }
  }

  Future<void> fetchPosts() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final response = await _postService.fetchPosts(_page, _limit);
      final List<dynamic> data = response['posts'];

      setState(() {
        _page++;
        _hasMore = data.length == _limit;

        posts.addAll(
          data.map(
            (post) => {
              'text': post['content'],
              'author': post['author'],
              'time': DateTime.parse(post['createdAt']),
              'avatarUrl': post['avatarUrl'] ?? '',
              'id': post['_id'],
              'isLiked': post['isLiked'] ?? false,
              'likeCount': post['likeCount'] ?? 0,
              'isOwner': post['isOwner'] ?? false,
              'comments': List<Map<String, dynamic>>.from(
                post['comments']?.map(
                      (c) => {
                        '_id': c['_id'],
                        'text': c['text'],
                        'author': c['author'],
                        'avatarUrl': c['avatarUrl'],
                        'replies': List<Map<String, dynamic>>.from(
                          c['replies'] ?? [],
                        ),
                      },
                    ) ??
                    [],
              ),
            },
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching posts: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> fetchUserData() async {
    try {
      final decodedToken = JwtDecoder.decode(widget.token);
      final role = decodedToken['role'];
      username = decodedToken['username'];

      late Map<String, dynamic> data;

      if (role == 'Job Seeker' || role == 'Freelancer') {
        data = await _postService.fetchUserData();
      } else if (role == 'Organization') {
        data = await _postService.fetchOrganizationData();
      }

      if (!mounted) return;

      setState(() {
        uploadedImageUrl = data['avatarUrl'];
        fullName = data['name'] ?? 'Unknown $role';
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile load error: ${e.toString()}')),
      );
    }
  }

  Future<void> createPost() async {
    final text = _postController.text.trim();
    if (text.isEmpty || fullName == null) return;

    try {
      final success = await _postService.createPost(text);
      if (success) {
        _postController.clear();
        setState(() {
          _page = 1;
          posts.clear();
          _hasMore = true;
        });
        await fetchPosts();
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating post: $e')));
    }
  }

  Future<void> _handlePostUpdated(int index, String newText) async {
    final postId = posts[index]['id'];
    try {
      final success = await _postService.updatePost(postId, newText);
      if (success) {
        setState(() {
          posts[index]['text'] = newText;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update post: $e')));
    }
  }

  Future<void> _handlePostDeleted(int index) async {
    final postId = posts[index]['id'];
    try {
      final success = await _postService.deletePost(postId);
      if (success) {
        setState(() {
          posts.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete post: $e')));
    }
  }

  void _handlePostLiked(int index) {
    setState(() {
      posts[index]['isLiked'] = !posts[index]['isLiked'];
      if (posts[index]['isLiked']) {
        posts[index]['likeCount']++;
      } else {
        posts[index]['likeCount']--;
      }
    });
  }

  void _handleShowComments(int postIndex) async {
    final post = posts[postIndex];
    final String postId = post['id'];

    if (post['comments'] == null) {
      post['comments'] = [];
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => CommentsModal(
            comments: List<Map<String, dynamic>>.from(post['comments']),
            currentUserAvatar: uploadedImageUrl ?? '',
            currentUserName: fullName ?? 'Anonymous',
            postId: postId,
            token: widget.token,
          ),
    );

    if (mounted) setState(() {});
  }

  Future<void> fetchPostAuthors() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final response = await _postService.fetchPosts(_page, _limit);
      final List<dynamic> data = response['posts'];

      setState(() {
        _page++;
        _hasMore = data.length == _limit;

        posts.addAll(
          data.map(
            (post) => {
              'authorUsername': post['author']['username'],
              'avatarUrl': post['author']['avatarUrl'],
            },
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching post authors: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.only(left: 20, top: 20, bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(128, 128, 128, 0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              PostInputWidget(
                controller: _postController,
                onPost: createPost,
                fullName: fullName,
                avatarUrl: uploadedImageUrl,
              ),
              const SizedBox(height: 10),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                ),
              ...posts.asMap().entries.map((entry) {
                final post = entry.value;
                return PostCard(
                  postText: post['text'],
                  authorName:
                      post['author'] is Map<String, dynamic>
                          ? post['author']['fullName'] ?? 'Unknown'
                          : post['author'],
                  timestamp: post['time'],
                  authorAvatarUrl: post['avatarUrl'] ?? '',
                  postId: post['id'],
                  onDelete: () => _handlePostDeleted(entry.key),
                  onUpdate: (newText) => _handlePostUpdated(entry.key, newText),
                  isOwner: post['isOwner'],
                  isLiked: post['isLiked'],
                  likeCount: post['likeCount'],
                  onLike: () => _handlePostLiked(entry.key),
                  onComment: () => _handleShowComments(entry.key),
                  currentUserAvatar: uploadedImageUrl ?? '',
                  currentUserName: fullName ?? 'Anonymous',
                  token: widget.token,
                  username: post['author'] ?? '',

                  initialComments: List<Map<String, dynamic>>.from(
                    post['comments']?.map(
                          (c) => {
                            '_id': c['_id'],
                            'text': c['text'],
                            'author': c['author'],
                            'avatarUrl': c['avatarUrl'],
                            'replies': List<Map<String, dynamic>>.from(
                              c['replies'] ?? [],
                            ),
                          },
                        ) ??
                        [],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
