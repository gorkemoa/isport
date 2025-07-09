// Authentication ile ilgili model sınıfları

/// Giriş isteği için model
class LoginRequest {
  final String userEmail;
  final String userPassword;

  LoginRequest({
    required this.userEmail,
    required this.userPassword,
  });

  /// JSON'a çevirme
  Map<String, dynamic> toJson() {
    return {
      'userEmail': userEmail,
      'userPassword': userPassword,
    };
  }
}

/// API'den gelen authentication data
class AuthData {
  final int userID;
  final String token;
  final bool isComp;

  AuthData({
    required this.userID,
    required this.token,
    required this.isComp,
  });

  /// JSON'dan oluşturma
  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      userID: json['userID'] ?? 0,
      token: json['token'] ?? '',
      isComp: json['isComp'] ?? false,
    );
  }

  /// JSON'a çevirme
  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'token': token,
      'isComp': isComp,
    };
  }
}

/// Giriş yanıtı için model
class LoginResponse {
  final bool error;
  final bool success;
  final AuthData? data;
  final String? message410;

  LoginResponse({
    required this.error,
    required this.success,
    this.data,
    this.message410,
  });

  /// JSON'dan oluşturma
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? AuthData.fromJson(json['data']) : null,
      message410: json['410'],
    );
  }
}

/// Kullanıcı modeli (SharedPreferences'tan yüklemek için)
class User {
  final int userID;
  final String token;
  final bool isComp;
  final String userEmail;

  User({
    required this.userID,
    required this.token,
    required this.isComp,
    required this.userEmail,
  });

  /// JSON'dan oluşturma
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userID: json['userID'] ?? 0,
      token: json['token'] ?? '',
      isComp: json['isComp'] ?? false,
      userEmail: json['userEmail'] ?? '',
    );
  }

  /// JSON'a çevirme
  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'token': token,
      'isComp': isComp,
      'userEmail': userEmail,
    };
  }
}

/// Authentication durumu enum'u
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}
