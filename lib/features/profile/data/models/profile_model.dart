class ProfileModel {
  ProfileModel({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.bio = '',
    this.maxGrade = 'V0',
    this.totalSends = 0,
    this.createdAt,
  });

  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String bio;
  final String maxGrade;
  final int totalSends;
  final DateTime? createdAt;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String? ?? '',
      maxGrade: json['max_grade'] as String? ?? 'V0',
      totalSends: json['total_sends'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        if (displayName != null) 'display_name': displayName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'bio': bio,
      };
}
