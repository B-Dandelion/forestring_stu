enum AppRole {
  master,
  manager,
  teacher,
  student;

  factory AppRole.fromValue(String value) {
    return switch (value) {
      'master' => AppRole.master,
      'manager' => AppRole.manager,
      'teacher' => AppRole.teacher,
      'student' => AppRole.student,
      _ => throw ArgumentError('Unknown Forestring role: $value'),
    };
  }
}

class CurrentProfile {
  const CurrentProfile({
    required this.id,
    required this.displayName,
    required this.role,
    required this.isActive,
    required this.isReviewAccount,
    this.branchId,
  });

  final String id;
  final String displayName;
  final AppRole role;
  final bool isActive;
  final bool isReviewAccount;
  final String? branchId;

  factory CurrentProfile.fromJson(Map<String, dynamic> json) {
    return CurrentProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      role: AppRole.fromValue(json['role'] as String),
      isActive: json['is_active'] as bool,
      isReviewAccount: json['is_review_account'] == true,
      branchId: json['branch_id'] as String?,
    );
  }
}
