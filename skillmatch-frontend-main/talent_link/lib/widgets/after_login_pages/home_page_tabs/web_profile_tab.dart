import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:skillmatch_platform/services/post_service.dart';
import 'package:skillmatch_platform/services/profile_service.dart';
import 'package:skillmatch_platform/services/rating_service.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/avatar_username.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/post_sections/post_card.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/resume.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/user_data.dart';
import 'package:skillmatch_platform/widgets/appSetting/web_settings_page.dart';
import 'package:skillmatch_platform/widgets/appSetting/seeting.dart';
import 'package:skillmatch_platform/widgets/web_layouts/web_form_components.dart';
import 'package:skillmatch_platform/models/user_profile_data.dart';
import 'package:logger/logger.dart';
import 'package:skillmatch_platform/widgets/shared/rating_display.dart';

class WebProfileTab extends StatefulWidget {
  final VoidCallback onLogout;
  final String token;

  const WebProfileTab({super.key, required this.onLogout, required this.token});

  @override
  State<WebProfileTab> createState() => _WebProfileTabState();
}

class _WebProfileTabState extends State<WebProfileTab>
    with SingleTickerProviderStateMixin {
  final _logger = Logger();
  late PostService _postService;
  late RatingService _ratingService;
  UserProfileData? userProfileData;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  Map<String, bool> expandedSections = {};
  Map<String, bool> collapsedSections = {};
  List<Map<String, dynamic>> userPosts = [];
  String? fullName;
  final int _page = 1;
  final int _limit = 10;
  String? uploadedImageUrl;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  double currentRating = 0;
  int ratingCount = 0;
  double? myRating;
  bool isRatingLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    fetchProfileData();
    _postService = PostService(widget.token);
    _ratingService = RatingService(token: widget.token);
    fetchUserDataAndPosts();
    _animationController.forward();
    _loadMyRating();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchProfileData() async {
    try {
      final data = await ProfileService.getProfileData(widget.token);
      setState(() {
        userProfileData = data;
      });
    } catch (e) {
      _logger.e("Error fetching profile", error: e);
      setState(() {
        userProfileData = UserProfileData(
          summary: '',
          education: [],
          skills: [],
          experience: [],
          certifications: [],
          languages: [],
        );
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteItem(String field, String value) async {
    try {
      await ProfileService.deleteItem(field, value, widget.token);
      await fetchProfileData();
    } catch (e) {
      _logger.e("Error deleting $field", error: e);
    }
  }

  void showEditDialog(String field, String? oldValue) {
    final controller = TextEditingController(text: oldValue ?? '');
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit $field'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: field,
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await ProfileService.addItem(
                      field,
                      controller.text,
                      widget.token,
                    );
                    await fetchProfileData();
                    Navigator.pop(context);
                  } catch (e) {
                    _logger.e("Error updating $field", error: e);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Widget buildWebExpandableList(
    String title,
    List<String> items,
    String field,
  ) {
    final isCollapsed = collapsedSections[title] ?? false;
    final isExpanded = expandedSections[title] ?? false;
    final displayItems = isExpanded ? items : items.take(3).toList();

    return WebCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getSectionIcon(title),
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  isCollapsed ? Icons.expand_more : Icons.expand_less,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  setState(() {
                    collapsedSections[title] =
                        !(collapsedSections[title] ?? false);
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.add, color: Theme.of(context).primaryColor),
                onPressed: () => showEditDialog(field, null),
              ),
            ],
          ),
          if (!isCollapsed) ...[
            const SizedBox(height: 16),
            if (items.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'No $title added yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ...displayItems.map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(item, style: const TextStyle(fontSize: 14)),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red[400],
                          size: 18,
                        ),
                        onPressed: () => deleteItem(field, item),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            if (items.length > 3)
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      expandedSections[title] = !isExpanded;
                    });
                  },
                  child: Text(
                    isExpanded ? "Show Less ▲" : "Show More ▼",
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  IconData _getSectionIcon(String title) {
    switch (title) {
      case 'Education':
        return Icons.school_outlined;
      case 'Skills':
        return Icons.psychology_outlined;
      case 'Experience':
        return Icons.work_outline;
      case 'Certifications':
        return Icons.card_membership_outlined;
      case 'Languages':
        return Icons.language_outlined;
      default:
        return Icons.list_alt_outlined;
    }
  }

  Future<void> fetchUserDataAndPosts() async {
    Map<String, dynamic> decodedToken = JwtDecoder.decode(widget.token);
    String username = decodedToken['username'];
    _logger.i("Username: $username");
    try {
      final userResponse = await _postService.fetchUserByUsername(username);

      final postsResponse = await _postService.fetchPostsByUsername(
        username,
        _page,
        _limit,
      );

      setState(() {
        userData = userResponse;
        uploadedImageUrl = userResponse['avatarUrl'];
        fullName = userResponse['name'];
        username = userResponse['username'];

        userPosts =
            postsResponse.map((post) {
              return {
                'id': post['_id'],
                'text': post['content'],
                'time': DateTime.parse(post['createdAt']),
                'avatarUrl': post['avatarUrl'] ?? '',
                'isLiked': post['isLiked'] ?? false,
                'likeCount': post['likeCount'] ?? 0,
              };
            }).toList();
      });
    } catch (e) {
      _logger.e("Error fetching user data and posts", error: e);
    }
  }

  Future<void> _loadMyRating() async {
    try {
      final rating = await _ratingService.getMyRating();
      setState(() {
        currentRating = rating.rating;
        ratingCount = rating.count;
        myRating = rating.userRating;
      });
    } catch (e) {
      setState(() {
        currentRating = 0;
        ratingCount = 0;
        myRating = null;
      });
    }
  }

  Future<void> _updateMyRating(double ratingValue) async {
    setState(() => isRatingLoading = true);
    try {
      await _ratingService.updateRating(
        targetUsername: userData?['username'] ?? '',
        ratingValue: ratingValue,
      );
      await _loadMyRating();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update rating: $e')));
    } finally {
      setState(() => isRatingLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column - Profile Info
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile Header
                    WebCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.person_outline,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Profile',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                  Icons.settings_outlined,
                                  color: Theme.of(context).primaryColor,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              kIsWeb
                                                  ? const WebSettingsPage()
                                                  : SettingsPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AvatarUsername(token: widget.token),
                          const SizedBox(height: 16),
                          RatingDisplay(
                            averageRating: currentRating,
                            ratingCount: ratingCount,
                            myRating: myRating,
                            isLoading: isRatingLoading,
                            allowUpdate: true,
                            onRate: _updateMyRating,
                          ),
                          const SizedBox(height: 16),
                          UserData(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Summary Section
                    WebCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.description_outlined,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Summary",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  color: Theme.of(context).primaryColor,
                                ),
                                onPressed: () {
                                  // TODO: Implement edit summary dialog
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            userProfileData!.summary.isNotEmpty
                                ? userProfileData!.summary
                                : "No summary provided.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Resume Section
                    ResumeWidget(
                      token: widget.token,
                      onSkillsExtracted: fetchProfileData,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 24),

            // Right Column - Profile Sections
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    buildWebExpandableList(
                      "Education",
                      userProfileData!.education,
                      'education',
                    ),
                    const SizedBox(height: 16),
                    buildWebExpandableList(
                      "Skills",
                      userProfileData!.skills,
                      'skills',
                    ),
                    const SizedBox(height: 16),
                    buildWebExpandableList(
                      "Experience",
                      userProfileData!.experience,
                      'experience',
                    ),
                    const SizedBox(height: 16),
                    buildWebExpandableList(
                      "Certifications",
                      userProfileData!.certifications,
                      'certifications',
                    ),
                    const SizedBox(height: 16),
                    buildWebExpandableList(
                      "Languages",
                      userProfileData!.languages,
                      'languages',
                    ),

                    const SizedBox(height: 24),

                    // Posts Section
                    if (userPosts.isNotEmpty) ...[
                      WebCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.post_add_outlined,
                                    color: Theme.of(context).primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Recent Posts',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...userPosts.take(3).map((post) {
                              final authorName = fullName ?? 'Unknown Author';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: PostCard(
                                  postId: post['id'],
                                  postText: post['text'],
                                  authorName: authorName,
                                  timestamp: post['time'],
                                  authorAvatarUrl: post['avatarUrl'] ?? '',
                                  isOwner: false,
                                  isLiked: post['isLiked'] ?? false,
                                  likeCount: post['likeCount'] ?? 0,
                                  onLike: () {},
                                  onComment: () {},
                                  currentUserAvatar: uploadedImageUrl ?? '',
                                  currentUserName: fullName ?? 'Anonymous',
                                  token: widget.token,
                                  username: userData?['username'] ?? '',
                                  initialComments: const [],
                                  onDelete: null,
                                  onUpdate: null,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
