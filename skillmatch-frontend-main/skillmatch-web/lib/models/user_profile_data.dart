class UserProfileData {
  final List<String> education;
  final List<String> skills;
  final List<String> certifications;
  final List<String> languages;
  final List<String> experience; // ✅ NEW
  final String summary;

  UserProfileData({
    required this.education,
    required this.skills,
    required this.certifications,
    required this.languages,
    required this.experience, // ✅ NEW
    required this.summary,
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      education: List<String>.from(json['education'] ?? []),
      skills: List<String>.from(json['skills'] ?? []),
      certifications: List<String>.from(json['certifications'] ?? []),
      languages: List<String>.from(json['languages'] ?? []),
      experience: List<String>.from(json['experience'] ?? []), // ✅ NEW
      summary: json['summary'] ?? '',
    );
  }
}
