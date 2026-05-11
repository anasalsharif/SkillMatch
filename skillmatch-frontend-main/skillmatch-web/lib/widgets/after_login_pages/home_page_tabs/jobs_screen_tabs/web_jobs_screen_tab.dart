import 'package:flutter/material.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/jobs_screen_tabs/all_jobs_tab.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/jobs_screen_tabs/best_matched_tab.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/jobs_screen_tabs/filter_jobs_tab.dart';
import 'package:skillmatch_platform/widgets/web_layouts/web_form_components.dart';

class WebJobsScreenTab extends StatefulWidget {
  final String token;

  const WebJobsScreenTab({super.key, required this.token});

  @override
  State<WebJobsScreenTab> createState() => _WebJobsScreenTabState();
}

class _WebJobsScreenTabState extends State<WebJobsScreenTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Navigation
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 16,
              ),
              tabs: const [
                Tab(
                  text: 'All Jobs',
                  icon: Icon(Icons.list_alt_outlined, size: 20),
                ),
                Tab(
                  text: 'Best Matches',
                  icon: Icon(Icons.star_outline, size: 20),
                ),
                Tab(
                  text: 'Filter Jobs',
                  icon: Icon(Icons.filter_list_outlined, size: 20),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(AllJobsTab(token: widget.token)),
                _buildTabContent(BestMatchedTab(token: widget.token)),
                _buildTabContent(FilterJobsTab(token: widget.token)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
    );
  }
}
