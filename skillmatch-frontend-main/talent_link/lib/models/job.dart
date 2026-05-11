class Job {
  final String id;
  final String title;
  final String description;
  final String location;
  final String salary;
  final String jobType;
  final String category;
  final String deadline;
  final List<String> requirements;
  final List<String> responsibilities;
  final double? matchScore;
  final String organizationId;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.salary,
    required this.jobType,
    required this.category,
    required this.deadline,
    required this.requirements,
    required this.responsibilities,
    this.matchScore,
    required this.organizationId,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['_id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      salary: json['salary']?.toString() ?? '',
      jobType: json['jobType'] ?? '',
      category: json['category'] ?? '',
      deadline: json['deadline'] ?? '',
      requirements: List<String>.from(json['requirements'] ?? []),
      responsibilities: List<String>.from(json['responsibilities'] ?? []),
      matchScore:
          json['matchScore'] != null
              ? (json['matchScore'] as num).toDouble()
              : null,
      organizationId: json['companyId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'location': location,
      'salary': salary,
      'jobType': jobType,
      'category': category,
      'deadline': deadline,
      'requirements': requirements,
      'responsibilities': responsibilities,
      'matchScore': matchScore,
      'companyId': organizationId,
    };
  }
}
