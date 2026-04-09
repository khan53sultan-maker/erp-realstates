class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String role; // 'ADMIN', 'MANAGER', 'SALES_AGENT', 'ACCOUNTANT'
  final DateTime? dateJoined;
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.dateJoined,
    this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'ADMIN',
      dateJoined: json['date_joined'] != null
          ? DateTime.parse(json['date_joined'])
          : null,
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role,
      'date_joined': dateJoined?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  UserModel copyWith({
    int? id,
    String? fullName,
    String? email,
    String? role,
    DateTime? dateJoined,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      dateJoined: dateJoined ?? this.dateJoined,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, fullName: $fullName, email: $email, dateJoined: $dateJoined, lastLogin: $lastLogin)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.fullName == fullName &&
        other.email == email &&
        other.dateJoined == dateJoined &&
        other.lastLogin == lastLogin;
  }

  @override
  int get hashCode {
    return Object.hash(id, fullName, email, dateJoined, lastLogin);
  }
}
