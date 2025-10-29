class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? username;
  final String role;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final int? heightCm;
  final String? fitnessGoal;
  final String? activityLevel;
  final double? targetWeightKg;
  final bool isActive;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool? notificationsEnabled;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.username,
    required this.role,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    this.heightCm,
    this.fitnessGoal,
    this.activityLevel,
    this.targetWeightKg,
    this.notificationsEnabled,
    required this.isActive,
    required this.onboardingCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      username: json['username'] as String?,
      role: json['role'] as String,
      avatarUrl: json['avatar_url'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] as String?,
      heightCm: json['height_cm'] as int?,
      fitnessGoal: json['fitness_goal'] as String?,
      activityLevel: json['activity_level'] as String?,
      targetWeightKg: json['target_weight_kg'] != null
          ? (json['target_weight_kg'] as num).toDouble()
          : null,
      isActive: json['is_active'] as bool,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      notificationsEnabled: json['notifications_enabled'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'username': username,
      'role': role,
      'avatar_url': avatarUrl,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'gender': gender,
      'height_cm': heightCm,
      'fitness_goal': fitnessGoal,
      'activity_level': activityLevel,
      'target_weight_kg': targetWeightKg,
      'is_active': isActive,
      'onboarding_completed': onboardingCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? username,
    String? role,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? gender,
    int? heightCm,
    String? fitnessGoal,
    String? activityLevel,
    double? targetWeightKg,
    bool? isActive,
    bool? onboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      activityLevel: activityLevel ?? this.activityLevel,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      isActive: isActive ?? this.isActive,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  String get displayName =>
      fullName.isNotEmpty ? fullName : email.split('@')[0];

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  bool get isProfileComplete {
    return fullName.isNotEmpty &&
        gender != null &&
        heightCm != null &&
        fitnessGoal != null &&
        activityLevel != null;
  }

  String get roleDisplayName {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrator';
      case 'trainer':
        return 'Trainer';
      case 'member':
        return 'Member';
      default:
        return role;
    }
  }

  String get fitnessGoalDisplayName {
    if (fitnessGoal == null) return 'Not set';
    switch (fitnessGoal!.toLowerCase()) {
      case 'weight_loss':
        return 'Weight Loss';
      case 'muscle_gain':
        return 'Muscle Gain';
      case 'strength':
        return 'Strength';
      case 'endurance':
        return 'Endurance';
      case 'general_fitness':
        return 'General Fitness';
      default:
        return fitnessGoal!;
    }
  }

  String get activityLevelDisplayName {
    if (activityLevel == null) return 'Not set';
    switch (activityLevel!.toLowerCase()) {
      case 'sedentary':
        return 'Sedentary';
      case 'lightly_active':
        return 'Lightly Active';
      case 'moderately_active':
        return 'Moderately Active';
      case 'very_active':
        return 'Very Active';
      case 'extremely_active':
        return 'Extremely Active';
      default:
        return activityLevel!;
    }
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, fullName: $fullName, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
