/// Authentication data models.
/// Mirrors: frontend/src/types/authTypes.ts

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

class LoginResponse {
  final String token;
  final String message;

  const LoginResponse({required this.token, required this.message});

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    token: json['token'] as String,
    message: json['message'] as String? ?? '',
  );
}

class RegisterRequest {
  final String userName;
  final String firstName;
  final String lastName;
  final String email;
  final String password;

  const RegisterRequest({
    required this.userName,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'userName': userName,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'password': password,
  };
}

class RegisterResponse {
  final String message;

  const RegisterResponse({required this.message});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      RegisterResponse(message: json['message'] as String? ?? '');
}
