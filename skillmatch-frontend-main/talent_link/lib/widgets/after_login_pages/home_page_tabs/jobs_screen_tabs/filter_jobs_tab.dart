import 'package:flutter/material.dart';
import 'package:skillmatch_platform/models/job.dart';
import 'package:skillmatch_platform/services/job_functions.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/home_page_tabs/jobs_screen_tabs/job_details_screen.dart';
import 'package:skillmatch_platform/widgets/shared/job_card.dart';

class FilterJobsTab extends StatefulWidget {
  final String token;

  const FilterJobsTab({super.key, required this.token});

  @override
  State<FilterJobsTab> createState() => _FilterJobsTabState();
}

class _FilterJobsTabState extends State<FilterJobsTab> {
  List<Job> allJobs = [];
  List<Job> filteredJobs = [];
  bool isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  bool _mounted = true;

  String? selectedJobType;
  String? selectedLocation;
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    _mounted = true;
    fetchJobs();
  }

  @override
  void dispose() {
    _mounted = false;
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchJobs() async {
    if (!_mounted) return;

    setState(() => isLoading = true);

    try {
      final jobs = await JobFunctions.fetchJobs(widget.token);

      if (!_mounted) return;

      // Schedule setState on next frame to avoid blocking main thread
      Future.microtask(() {
        if (!_mounted) return;
        setState(() {
          allJobs = jobs;
          filteredJobs = List.from(jobs);
          isLoading = false;
        });
      });
    } catch (e) {
      if (!_mounted) return;

      setState(() {
        isLoading = false;
      });

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load jobs. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _applyFilters() {
    if (!_mounted) return;

    final query = _searchController.text.toLowerCase();

    setState(() {
      filteredJobs =
          allJobs.where((job) {
            final matchesQuery =
                job.title.toLowerCase().contains(query) ||
                job.category.toLowerCase().contains(query) ||
                job.location.toLowerCase().contains(query) ||
                job.description.toLowerCase().contains(query);

            final matchesJobType =
                selectedJobType == null || job.jobType == selectedJobType;
            final matchesLocation =
                selectedLocation == null || job.location == selectedLocation;
            final matchesCategory =
                selectedCategory == null || job.category == selectedCategory;

            return matchesQuery &&
                matchesJobType &&
                matchesLocation &&
                matchesCategory;
          }).toList();
    });
  }

  void _showFilterDialog() {
    final jobTypes = allJobs.map((job) => job.jobType).toSet().toList();
    final locations = allJobs.map((job) => job.location).toSet().toList();
    final categories = allJobs.map((job) => job.category).toSet().toList();

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final mediaQuery = MediaQuery.of(context);
        final screenHeight = mediaQuery.size.height;
        final screenWidth = mediaQuery.size.width;

        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: screenWidth > 400 ? 400 : screenWidth - 32,
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.85,
              minHeight: 300,
            ),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fixed header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Filter Jobs',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(),
                ),
                // Scrollable content
                Flexible(
                  child: Container(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          _buildFilterDropdown(
                            label: "Job Type",
                            value: selectedJobType,
                            items: jobTypes,
                            onChanged: (value) {
                              setState(() => selectedJobType = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildFilterDropdown(
                            label: "Location",
                            value: selectedLocation,
                            items: locations,
                            onChanged: (value) {
                              setState(() => selectedLocation = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildFilterDropdown(
                            label: "Category",
                            value: selectedCategory,
                            items: categories,
                            onChanged: (value) {
                              setState(() => selectedCategory = value);
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                // Fixed footer with safe area
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                selectedJobType = null;
                                selectedLocation = null;
                                selectedCategory = null;
                                _applyFilters();
                              });
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: theme.colorScheme.outline,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Clear All',
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _applyFilters();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Apply',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      items:
          items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis, maxLines: 1),
            );
          }).toList(),
      onChanged: onChanged,
      menuMaxHeight: 200,
    );
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
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search jobs...',
                    prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) => _applyFilters(),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.tune, color: theme.primaryColor),
                  onPressed: _showFilterDialog,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              filteredJobs.isEmpty
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
                          'Try adjusting your search or filters',
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
                    itemCount: filteredJobs.length,
                    itemBuilder: (context, index) {
                      final job = filteredJobs[index];
                      return JobCard(
                        job: job,
                        onTap: () => _navigateToJobDetail(job),
                        isCompact: true,
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
