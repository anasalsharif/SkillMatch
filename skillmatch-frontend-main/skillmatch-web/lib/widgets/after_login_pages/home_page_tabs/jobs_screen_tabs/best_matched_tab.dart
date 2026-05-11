import 'package:flutter/material.dart';
import 'package:skillmatch_platform/models/job.dart';
import 'package:skillmatch_platform/services/job_functions.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/jobs_screen_tabs/job_details_screen.dart';
import 'package:skillmatch_platform/widgets/shared/job_card.dart';

class BestMatchedTab extends StatefulWidget {
  final String token;

  const BestMatchedTab({super.key, required this.token});

  @override
  State<BestMatchedTab> createState() => _BestMatchedTabState();
}

class _BestMatchedTabState extends State<BestMatchedTab> {
  List<Job> allJobs = [];
  List<Job> bestJobs = [];
  bool isLoading = false;
  double minMatchScore = 0;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _mounted = true;
    fetchBestMatches();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> fetchBestMatches() async {
    if (!_mounted) return;

    setState(() => isLoading = true);

    try {
      final jobs = await JobFunctions.fetchJobs(widget.token);
      if (!_mounted) return;

      setState(() {
        allJobs = JobFunctions.sortJobsByMatchScore(jobs);
        filterJobs();
        isLoading = false;
      });
    } catch (e) {
      if (!_mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  void filterJobs() {
    if (!_mounted) return;

    setState(() {
      bestJobs =
          allJobs
              .where((job) => (job.matchScore ?? 0) >= minMatchScore)
              .toList();
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

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Minimum Match Score: ${minMatchScore.round()}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: theme.primaryColor,
                  inactiveTrackColor: theme.primaryColor.withOpacity(0.2),
                  thumbColor: theme.primaryColor,
                  overlayColor: theme.primaryColor.withOpacity(0.1),
                ),
                child: Slider(
                  value: minMatchScore,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${minMatchScore.round()}%',
                  onChanged: (value) {
                    if (!_mounted) return;
                    setState(() {
                      minMatchScore = value;
                      filterJobs();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              bestJobs.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No matching jobs found',
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting the match score filter',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: bestJobs.length,
                    itemBuilder: (context, index) {
                      final job = bestJobs[index];
                      return JobCard(
                        job: job,
                        onTap: () => _navigateToJobDetail(job),
                        showMatchScore: true,
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
