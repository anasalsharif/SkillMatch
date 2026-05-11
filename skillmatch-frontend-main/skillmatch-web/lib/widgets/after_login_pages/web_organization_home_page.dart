import 'package:flutter/material.dart';
import 'package:skillmatch_platform/services/message_service.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/organization_hom_tabs/applications_tab.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/organization_hom_tabs/home_tab.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/organization_hom_tabs/my_jobs_tab.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/organization_hom_tabs/profile_tab.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/organization_hom_tabs/recommended_users_tab.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/notifications/notifications_for_org.dart';
import 'package:skillmatch_platform/widgets/web_layouts/web_navigation.dart';
import 'package:skillmatch_platform/utils/responsive/responsive_layout.dart';
import 'package:logger/logger.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/notifications/web_notifications_for_user.dart';

class WebOrganizationHomePage extends StatefulWidget {
  final String token;
  const WebOrganizationHomePage({super.key, required this.token});

  @override
  State<WebOrganizationHomePage> createState() =>
      _WebOrganizationHomePageState();
}

class _WebOrganizationHomePageState extends State<WebOrganizationHomePage>
    with AutomaticKeepAliveClientMixin {
  final _logger = Logger();
  @override
  bool get wantKeepAlive => true;
  int _selectedIndex = 0;
  late MessageService _messageService;

  final List<NavigationItem> _navigationItems = const [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: "Home",
    ),
    NavigationItem(
      icon: Icons.work_outline,
      activeIcon: Icons.work,
      label: "My Jobs",
    ),
    NavigationItem(
      icon: Icons.description_outlined,
      activeIcon: Icons.description,
      label: "Applications",
    ),
    NavigationItem(
      icon: Icons.recommend_outlined,
      activeIcon: Icons.recommend,
      label: "Recommended",
    ),
    NavigationItem(
      icon: Icons.business_outlined,
      activeIcon: Icons.business,
      label: "Profile",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _messageService = MessageService(widget.token);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleSearchNavigation() {
    _messageService.navigateToSearchPage(context);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ResponsiveLayout(
      mobile: _buildMobileLayout(context),
      desktop: _buildWebLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text(
            "SkillMatch Platform",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.message_outlined),
              onPressed: _handleSearchNavigation,
              color: Colors.white,
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WebNotificationsPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.05),
                Colors.white,
                Theme.of(context).primaryColor.withOpacity(0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              HomeTab(token: widget.token),
              MyJobsTab(token: widget.token),
              ApplicationsTab(token: widget.token),
              RecommendedUsersTab(token: widget.token),
              ProfileTab(token: widget.token),
            ],
          ),
        ),
        bottomNavigationBar: WebNavigation(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
          items: _navigationItems,
        ),
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return WebNavigationLayout(
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
      navigationItems: _navigationItems,
      headerActions: [
        IconButton(
          icon: const Icon(Icons.message_outlined),
          onPressed: _handleSearchNavigation,
          tooltip: 'Messages',
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WebNotificationsPage(),
              ),
            );
          },
          tooltip: 'Notifications',
        ),
        const SizedBox(width: 16),
      ],
      child: Container(
        padding: const EdgeInsets.all(24),
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildWebHomeTab(),
            _buildWebMyJobsTab(),
            _buildWebApplicationsTab(),
            _buildWebRecommendedUsersTab(),
            _buildWebProfileTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildWebHomeTab() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: HomeTab(token: widget.token),
    );
  }

  Widget _buildWebMyJobsTab() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: MyJobsTab(token: widget.token),
    );
  }

  Widget _buildWebApplicationsTab() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: ApplicationsTab(token: widget.token),
    );
  }

  Widget _buildWebRecommendedUsersTab() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: RecommendedUsersTab(token: widget.token),
    );
  }

  Widget _buildWebProfileTab() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      child: ProfileTab(token: widget.token),
    );
  }
}
