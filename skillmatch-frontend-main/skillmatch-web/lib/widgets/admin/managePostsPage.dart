import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final String baseUrl = dotenv.env['BASE_URL']!;

class ManagePostsPage extends StatefulWidget {
  final String token;
  const ManagePostsPage({super.key, required this.token});

  @override
  State<ManagePostsPage> createState() => _ManagePostsPageState();
}

class _ManagePostsPageState extends State<ManagePostsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> posts = [];
  bool isLoading = false;
  String currentUsername = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> searchPosts(String username) async {
    if (username.isEmpty) return;

    setState(() {
      isLoading = true;
      currentUsername = username;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/posts?ownerId=$username'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          posts = data.cast<Map<String, dynamic>>();
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to fetch posts')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error connecting to server')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/posts/$postId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        setState(() {
          posts.removeWhere((post) => post['_id'] == postId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete post')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error deleting post')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Posts'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Enter username to search...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onSubmitted: searchPosts,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => searchPosts(_searchController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Search'),
                ),
              ],
            ),
          ),

          // Content
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (posts.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      currentUsername.isEmpty
                          ? 'Enter a username to search posts'
                          : 'No posts found for @$currentUsername',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Author info
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(
                                  post['avatarUrl'] ??
                                      'https://via.placeholder.com/150',
                                ),
                                onBackgroundImageError: (_, __) {},
                                child:
                                    post['avatarUrl'] == null
                                        ? Text(
                                          post['username'][0].toUpperCase(),
                                        )
                                        : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post['username'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      DateTime.parse(
                                        post['createdAt'],
                                      ).toString().split('.')[0],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => deletePost(post['_id']),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Post content
                          if (post['content'] != null &&
                              post['content'].isNotEmpty)
                            Text(
                              post['content'],
                              style: const TextStyle(fontSize: 14),
                            ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              _buildStat(
                                Icons.favorite,
                                '${(post['likes'] as List?)?.length ?? 0}',
                              ),
                              const SizedBox(width: 16),
                              _buildStat(
                                Icons.comment,
                                '${(post['comments'] as List?)?.length ?? 0}',
                              ),
                            ],
                          ),

                          if (post['comments'] != null &&
                              post['comments'].isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                const Text(
                                  'Comments:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ...List.generate(
                                  (post['comments'] as List).length,
                                  (cIndex) {
                                    final comment = post['comments'][cIndex];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4.0,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${comment['author'] ?? 'Unknown'}: ${comment['text']}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (comment['replies'] != null &&
                                              (comment['replies'] as List)
                                                  .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 16.0,
                                                top: 4.0,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: List.generate(
                                                  (comment['replies'] as List)
                                                      .length,
                                                  (rIndex) {
                                                    final reply =
                                                        (comment['replies']
                                                            as List)[rIndex];
                                                    return Text(
                                                      '↳ ${reply['author'] ?? 'Unknown'}: ${reply['text']}',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey[700],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(count, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }
}
