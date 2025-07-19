class User {
  final int id;
  final String username;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.username,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      name: json['name'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class LoginResponse {
  final bool success;
  final String? token;
  final User? user;
  final String? error;

  LoginResponse({
    required this.success,
    this.token,
    this.user,
    this.error,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    if (json['success'] == true && json['data'] != null) {
      final data = json['data'];
      return LoginResponse(
        success: true,
        token: data['token'],
        user: User.fromJson(data),
        error: null,
      );
    } else {
      return LoginResponse(
        success: json['success'] ?? false,
        token: null,
        user: null,
        error: json['message'] ?? json['error'] ?? 'Error desconocido',
      );
    }
  }
}
