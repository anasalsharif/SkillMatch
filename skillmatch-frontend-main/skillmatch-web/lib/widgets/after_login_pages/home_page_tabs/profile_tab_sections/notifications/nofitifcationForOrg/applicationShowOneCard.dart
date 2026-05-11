import 'package:flutter/material.dart';
import 'package:skillmatch_platform/services/application_service.dart';
import 'package:skillmatch_platform/widgets/after_login_pages/organization_hom_tabs/applications_tab.dart';

class ApplicationDetailPage extends StatefulWidget {
  final String token;
  final String applicationId;

  const ApplicationDetailPage({
    super.key,
    required this.token,
    required this.applicationId,
  });

  @override
  State<ApplicationDetailPage> createState() => _ApplicationDetailPageState();
}

class _ApplicationDetailPageState extends State<ApplicationDetailPage> {
  Application? application;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchApplication();
  }

  Future<void> fetchApplication() async {
    setState(() {
      isLoading = true;
    });

    try {
      final fetchedApplication = await ApplicationService.getApplicationById(
        widget.token,
        widget.applicationId,
      );
      setState(() {
        application = fetchedApplication;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : application == null
              ? const Center(child: Text('Application not found'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ApplicationCard(
                  application: application!,
                  token: widget.token,
                  onStatusChange: fetchApplication,
                ),
              ),
    );
  }
}
