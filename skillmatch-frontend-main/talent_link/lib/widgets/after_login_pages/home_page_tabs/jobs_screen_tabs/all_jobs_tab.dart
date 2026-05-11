import 'package:flutter/material.dart';
import 'package:skillmatch_platform/models/job.dart';
import 'package:skillmatch_platform/services/job_functions.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/jobs_screen_tabs/job_details_screen.dart';
import 'package:skillmatch_platform/widgets/shared/job_card.dart';

class AllJobsTab extends StatefulWidget {
  final String token;

  const AllJobsTab({super.key, required this.token});

  @override
  State<AllJobsTab> createState() => _AllJobsTabState();
}

class _AllJobsTabState extends State<AllJobsTab> {
  List<Job> allJobs = [];
  bool isLoading = false;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _mounted = true;
    fetchJobs();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> fetchJobs() async {
    if (!_mounted) return;

    setState(() => isLoading = true);
    final jobs = await JobFunctions.fetchJobs(widget.token);

    if (!_mounted) return;

    setState(() {
      allJobs = jobs;
      isLoading = false;
    });
  }

  void _navigateToJobDetail(Job job) {
    if (!_mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailsScreen(job: job, token: widget.token),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading && allJobs.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
        ),
      );
    }

    if (allJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_off_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No jobs available',
              style: TextStyle(
                fontSize: 18,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: theme.primaryColor,
      onRefresh: fetchJobs,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: allJobs.length,
        itemBuilder: (context, index) {
          final job = allJobs[index];
          return JobCard(job: job, onTap: () => _navigateToJobDetail(job));
        },
      ),
    );
  }
}
