import 'package:flutter/material.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/profile_tab_sections/post_sections/post_creator.dart';

class HomeTab extends StatefulWidget {
  final String token;
  const HomeTab({super.key, required this.token});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Expanded(child: PostCreator(token: widget.token)));
  }
}
