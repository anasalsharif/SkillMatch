//new api all fixed i used api.env

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillmatch_platform/services/message_service.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/jobs_screen_tab.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/map_screen.dart';
import 'dart:convert';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/exploreUser.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/notifications/notifications_for_user.dart';
import 'package:skillmatch_platform/widgets/appSetting/logout.dart';
import 'package:skillmatch_platform/widgets/appSetting/seeting.dart';
import 'package:skillmatch_platform/widgets/freeLancing/freelanceFeed.dart';
import 'package:skillmatch_platform/widgets/login_widgets/login_page.dart';
import '../after_login_pages/home_page_tabs/profile_tab_sections/post_sections/post_creator.dart';
import 'package:logger/logger.dart';

final String baseUrl = dotenv.env['BASE_URL']!;

class HomePage extends StatefulWidget {
  final String data; // Token
  final Function(String) onTokenChanged;

  const HomePage({super.key, required this.data, required this.onTokenChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  final _logger = Logger();
  @override
  bool get wantKeepAlive => true;
  int _selectedIndex = 0;
  List<String> userSkills = [];
  List<String> userEducation = [];
  late MessageService _messageService;

  @override
  void initState() {
    super.initState();
    _messageService = MessageService(widget.data);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleLogout() {
    widget.onTokenChanged('Unauthorized');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _handleSearchNavigation() {
    _messageService.navigateToSearchPage(context);
  }

  Future<String> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? 'defaultUsername';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
                icon: const Icon(Icons.search),
                color: Colors.white,
                onPressed: () async {
                  final username = await getCurrentUsername();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ExploreUserPage(
                            username: username,
                            token: widget.data,
                          ),
                    ),
                  );
                },
              ),
            ),

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
                      builder: (context) => NotificationsPage(),
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
              PostCreator(token: widget.data),
              JobsScreenTab(token: widget.data),
              MapScreen(token: widget.data),
              FreelanceFeed(),
              ProfileTab(token: widget.data, onLogout: _handleLogout),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey.shade600,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.find_in_page_outlined),
                activeIcon: Icon(Icons.find_in_page),
                label: "Jobs",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: "Map",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.work_outline),
                activeIcon: Icon(Icons.work_history),
                label: "Freelance",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
