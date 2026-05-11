class FollowerUser {
  final String username;
  final String name;
  final String avatarUrl;
  final bool isFollowing;

  FollowerUser({
    required this.username,
    required this.name,
    required this.avatarUrl,
    required this.isFollowing,
  });

  factory FollowerUser.fromJson(Map<String, dynamic> json) {
    return FollowerUser(
      username: json['username'],
      name: json['name'],
      avatarUrl: json['avatarUrl'] ?? '',
      isFollowing: json['isFollowing'] ?? false,
    );
  }
}
