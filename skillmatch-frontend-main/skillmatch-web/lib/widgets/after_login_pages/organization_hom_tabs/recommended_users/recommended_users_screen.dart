import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:skillmatch_platform/services/job_service.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/post_sections/profile_widget_for_another_users.dart';

class RecommendedUsersScreen extends StatefulWidget {
  final String jobId;
  final String organizationId;
  final String token;

  const RecommendedUsersScreen({
    super.key,
    required this.jobId,
    required this.organizationId,
    required this.token,
  });

  @override
  State<RecommendedUsersScreen> createState() => _RecommendedUsersScreenState();
}

class _RecommendedUsersScreenState extends State<RecommendedUsersScreen>
    with SingleTickerProviderStateMixin {
  final _logger = Logger();
  late JobService _jobMatchService;
  List<dynamic> matchedUsers = [];
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _jobMatchService = JobService(token: widget.token);
    _setupAnimations();
    _loadMatchedUsers();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  Future<void> _loadMatchedUsers() async {
    try {
      final users = await _jobMatchService.fetchMatchedUsers(widget.jobId);
      if (mounted) {
        setState(() {
          matchedUsers =
              users
                  .where(
                    (user) =>
                        user != null &&
                        user['userId'] != null &&
                        user['userId'] is Map,
                  )
                  .toList();
          isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      _logger.e('Error loading matched users', error: e);
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Recommended Users",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child:
                    isLoading
                        ? Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).primaryColor,
                          ),
                        )
                        : matchedUsers.isEmpty
                        ? Center(
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder:
                                (context, child) => Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: Transform.translate(
                                    offset: _slideAnimation.value,
                                    child: child,
                                  ),
                                ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_search,
                                  size: 64,
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No Matches Found",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "No users match this job profile yet.\nPlease check again later.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: matchedUsers.length,
                          itemBuilder: (context, index) {
                            final userMatch = matchedUsers[index];
                            final user =
                                userMatch['userId'] as Map<String, dynamic>?;
                            final matchScore = userMatch['matchScore'] ?? 0;

                            if (user == null) return const SizedBox.shrink();

                            return AnimatedBuilder(
                              animation: _animationController,
                              builder:
                                  (context, child) => Opacity(
                                    opacity: _fadeAnimation.value,
                                    child: Transform.translate(
                                      offset: _slideAnimation.value,
                                      child: child,
                                    ),
                                  ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) =>
                                                  ProfileWidgetForAnotherUsers(
                                                    username:
                                                        user['username'] ??
                                                        'Unknown User',
                                                    token: widget.token,
                                                  ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          // Avatar
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor.withOpacity(0.2),
                                                width: 2,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              child:
                                                  user['avatarUrl'] != null
                                                      ? Image.network(
                                                        user['avatarUrl'],
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return Icon(
                                                            Icons.person,
                                                            size: 30,
                                                            color:
                                                                Theme.of(
                                                                  context,
                                                                ).primaryColor,
                                                          );
                                                        },
                                                      )
                                                      : Icon(
                                                        Icons.person,
                                                        size: 30,
                                                        color:
                                                            Theme.of(
                                                              context,
                                                            ).primaryColor,
                                                      ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),

                                          // User Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  user['username'] ??
                                                      'Unknown User',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .primaryColor
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Match: ${matchScore.toString()}%',
                                                    style: TextStyle(
                                                      color:
                                                          Theme.of(
                                                            context,
                                                          ).primaryColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Contact Button
                                          ElevatedButton(
                                            onPressed: () {
                                              // Contact logic here
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Theme.of(
                                                    context,
                                                  ).primaryColor,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                            ),
                                            child: const Text(
                                              "Contact",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
