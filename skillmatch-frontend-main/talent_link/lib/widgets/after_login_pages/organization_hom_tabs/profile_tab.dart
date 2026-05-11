import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/post_sections/followers_list_screen.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/organization_hom_tabs/profile_tab_items/avatar_name.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/organization_hom_tabs/profile_tab_items/location_picker_screen.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/organization_hom_tabs/profile_tab_items/location_view.dart';
import 'package:skillmatch_platform/widgets/base_widgets/button.dart';
import 'package:skillmatch_platform/services/location_service.dart';
import 'package:skillmatch_platform/widgets/appSetting/seeting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillmatch_platform/utils/auth_utils.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:logger/logger.dart';
import 'package:skillmatch_platform/widgets/appSetting/web_settings_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:skillmatch_platform/services/post_service.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/post_sections/post_card.dart';
import 'package:skillmatch_platform/services/rating_service.dart';
import 'package:skillmatch_platform/widgets/shared/rating_display.dart';


class ProfileTab extends StatefulWidget {
  final String token;
  const ProfileTab({super.key, required this.token});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final logger = Logger();
  double lat = 32.150146;
  double lag = 35.253834;
  bool isLoading = true;
  int followersCount = 0;
  int followingCount = 0;
  String username = '';
  Map<String, dynamic>? organizationData;
  late final LocationService _locationService;
  late PostService _postService;
  List<Map<String, dynamic>> orgPosts = [];
  double currentRating = 0;
  int ratingCount = 0;
  double? myRating;
  bool isRatingLoading = false;
  late RatingService _ratingService;


  @override
  void initState() {
    super.initState();
    final decodedToken = JwtDecoder.decode(widget.token);
    username = decodedToken['username'];
    _locationService = LocationService(
      //192.168.1.7        baseUrl: 'http://10.0.2.2:5000',
      // baseUrl: 'http://192.168.1.7:5000',
      token: widget.token,
    );
    _postService = PostService(widget.token);
    _fetchLocation();
    _fetchOrganizationPosts();
    _ratingService = RatingService(token: widget.token);
    _loadMyRating();
  }

  Future<void> _fetchLocation() async {
    try {
      final decodedToken = JwtDecoder.decode(widget.token);
      username = decodedToken['username'];
      final location = await _locationService.getLocationByUsername(username);
      setState(() {
        lat = location['lat']!;
        lag = location['lng']!;
        isLoading = false;
      });
      await _fetchOrganizationData();
    } catch (e) {
      logger.e("Error fetching location", error: e);
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchOrganizationData() async {
    try {
      final decodedToken = JwtDecoder.decode(widget.token);
      final orgUsername = decodedToken['username'];
      final orgData = await _postService.fetchOrganizationDataByuserName(
        orgUsername,
      );
      setState(() {
        organizationData = orgData;
        print('Organization Data: $organizationData');
      });
    } catch (e) {
      logger.e('Error fetching organization data', error: e);
    }
  }

  Future<void> _fetchOrganizationPosts() async {
    try {
      final decodedToken = JwtDecoder.decode(widget.token);
      final orgUsername = decodedToken['username'];
      final posts = await _postService.fetchPostsByUsername(
        orgUsername,
        1,
        1,
      ); // Fetch only the latest post
      setState(() {
        orgPosts = posts;
      });
    } catch (e) {
      logger.e('Error fetching organization posts', error: e);
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
        targetUsername: username,
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
  Widget _buildCountWidget(int count, String label, bool isFollowers) {
    return GestureDetector(
      onTap: () => _showFollowList(context, isFollowers),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  void _showFollowList(BuildContext context, bool showFollowers) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FollowersListScreen(
              token: widget.token,
              username: username,
              showFollowers: showFollowers,
            ),
      ),
    );
  }

  Future<void> _updateLocation(double newLat, double newLng) async {
    setState(() {
      lat = newLat;
      lag = newLng;
    });

    final success = await _locationService.setLocation(
      lat: newLat,
      lng: newLng,
    );
    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to update location")));
    }
  }

  Future<void> _handleLogout() async {
    try {
      // Use the centralized logout utility for consistent behavior
      await AuthUtils.performCompleteLogout(context);
    } catch (e) {
      logger.e("Error during logout", error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during logout. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    // Organization Info Cards with default values if missing
    final desc = organizationData?['description']?.toString() ?? '';
    final aboutValue = desc.isNotEmpty ? desc : 'No description provided';
    final industry = organizationData?['industry']?.toString() ?? '';
    final industryValue =
        industry.isNotEmpty ? industry : 'No industry provided';
    final website = organizationData?['website']?.toString() ?? '';
    final websiteValue = website.isNotEmpty ? website : 'No website provided';
    final email = organizationData?['email']?.toString() ?? '';
    final emailValue = email.isNotEmpty ? email : 'No email provided';
    final orgUsername = username ?? '';

    return Container(
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
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Avatar, Name and Settings
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.9),
                    Theme.of(context).primaryColor.withOpacity(0.7),
                    Theme.of(context).primaryColor.withOpacity(0.5),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 16,
                      ),
                      child: Stack(
                        children: [
                          Center(child: AvatarName(token: widget.token)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 15),

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCountWidget(followersCount, 'Followers', true),
                          const SizedBox(width: 24),
                          _buildCountWidget(followingCount, 'Following', false),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Rating section above About
            RatingDisplay(
              averageRating: currentRating,
              ratingCount: ratingCount,
              myRating: myRating,
              isLoading: isRatingLoading,
              allowUpdate: true,
              onRate: (ratingValue) => _updateMyRating(ratingValue),
            ),
            // Location Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.location_on_outlined,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Organization Location",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LocationView(lat: lat, lag: lag),
                  const SizedBox(height: 16),
                  // Organization Info Cards
                  SizedBox(
                    width: double.infinity,
                    child: BaseButton(
                      text: 'Update Location',
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => LocationPickerScreen(
                                  initialLat: lat,
                                  initialLng: lag,
                                ),
                          ),
                        );

                        if (result != null) {
                          await _updateLocation(result['lat'], result['lng']);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            _buildOrganizationInfoCard(
              'About',
              aboutValue,
              Icons.description_outlined,
            ),
            _buildOrganizationInfoCard(
              'Industry',
              industryValue,
              Icons.business_outlined,
            ),
            _buildOrganizationInfoCard(
              'Website',
              websiteValue,
              Icons.language_outlined,
            ),
            _buildOrganizationInfoCard(
              'Email',
              emailValue,
              Icons.email_outlined,
            ),
            const SizedBox(height: 24),

            // Organization Posts Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Latest Post',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => OrganizationPostsScreen(
                                    token: widget.token,
                                  ),
                            ),
                          );
                        },
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  orgPosts.isNotEmpty
                      ? PostCard(
                        postId: orgPosts[0]['id']?.toString() ?? '',
                        postText: orgPosts[0]['text']?.toString() ?? '',
                        authorName: orgPosts[0]['author']?.toString() ?? '',
                        timestamp:
                            orgPosts[0]['time'] != null
                                ? DateTime.parse(orgPosts[0]['time'].toString())
                                : DateTime.now(),
                        authorAvatarUrl:
                            orgPosts[0]['avatarUrl']?.toString() ?? '',
                        isOwner: orgPosts[0]['isOwner'] ?? false,
                        isLiked: orgPosts[0]['isLiked'] ?? false,
                        likeCount: orgPosts[0]['likeCount'] ?? 0,
                        onLike: () {},
                        onComment: () {},
                        currentUserAvatar: '',
                        currentUserName: '',
                        token: widget.token,
                        username: orgPosts[0]['author']?.toString() ?? '',
                        onDelete: null,
                        onUpdate: null,
                        initialComments: List<Map<String, dynamic>>.from(
                          orgPosts[0]['comments'] ?? [],
                        ),
                      )
                      : const Text('No posts yet.'),
                ],
              ),
            ),

            // Quick Actions Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.settings,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Account Settings",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActionTile(
                    icon: Icons.settings,
                    title: 'Account Settings',
                    subtitle: 'Manage your organization settings',
                    onTap: () {
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
                  const SizedBox(height: 12),
                  _buildQuickActionTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    subtitle: 'Sign out of your account',
                    isLogout: true,
                    onTap: () {
                      _showLogoutDialog();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isLogout
                    ? Colors.red.withOpacity(0.05)
                    : Theme.of(context).primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isLogout
                      ? Colors.red.withOpacity(0.2)
                      : Theme.of(context).primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isLogout
                          ? Colors.red.withOpacity(0.1)
                          : Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isLogout ? Colors.red : Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isLogout ? Colors.red : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isLogout ? Colors.red : Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 24),
              const SizedBox(width: 12),
              const Text('Logout'),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout? You will need to sign in again to access your account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrganizationInfoCard(
    String title,
    String? value,
    IconData icon,
  ) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder for the organization posts screen
class OrganizationPostsScreen extends StatelessWidget {
  final String token;
  const OrganizationPostsScreen({Key? key, required this.token})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organization Posts')),
      body: const Center(
        child: Text('All organization posts will be shown here.'),
      ),
    );
  }
}
