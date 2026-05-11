import 'package:skillmatch_platform/models/job.dart';
import 'package:skillmatch_platform/services/job_service.dart';

class JobFunctions {
  static Future<List<Job>> fetchJobs(String token) async {
    final service = JobService(token: token);
    return await service.fetchUserJobs();
  }

  static List<Job> sortJobsByMatchScore(List<Job> jobs) {
    final sortedJobs = List<Job>.from(jobs);
    sortedJobs.sort((a, b) => (b.matchScore ?? 0).compareTo(a.matchScore ?? 0));
    return sortedJobs;
  }

  static List<Job> filterJobs(List<Job> jobs, String query) {
    final lowerQuery = query.toLowerCase();
    return jobs
        .where(
          (job) =>
              job.title.toLowerCase().contains(lowerQuery) ||
              job.category.toLowerCase().contains(lowerQuery) ||
              job.location.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }
}
