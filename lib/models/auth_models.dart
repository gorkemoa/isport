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
  final bool isTokenError;
  final String error_message;
  LoginResponse({
    required this.error,
    required this.success,
    this.data,
    this.isTokenError = false,
    required this.error_message,
  });

  /// JSON'dan oluşturma
  factory LoginResponse.fromJson(Map<String, dynamic> json, {bool isTokenError = false}) {
    return LoginResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? AuthData.fromJson(json['data']) : null,
      isTokenError: isTokenError,
      error_message: json['error_message'] ?? '',
      );
  }

  /// Hata mesajını al
  String? get displayMessage {
    if (isTokenError) return 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.';
    return error_message; 
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

/// Kayıt isteği için model
class RegisterRequest {
  final String? compName;
  final String? compAddress;
  final int? compCity;
  final int? compDistrict;
  final String? compTaxNumber;
  final String? compTaxPlace;
  final String userFirstname;
  final String userLastname;
  final String userEmail;
  final String userPhone;
  final String userPassword;
  final String version;
  final String platform;
  final bool policy;
  final bool kvkk;
  final int isComp; // 0: Bireysel, 1: Kurumsal

  RegisterRequest({
    this.compName,
    this.compAddress,
    this.compCity,
    this.compDistrict,
    this.compTaxNumber,
    this.compTaxPlace,
    required this.userFirstname,
    required this.userLastname,
    required this.userEmail,
    required this.userPhone,
    required this.userPassword,
    required this.version,
    required this.platform,
    required this.policy,
    required this.kvkk,
    required this.isComp,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'userFirstname': userFirstname,
      'userLastname': userLastname,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'userPassword': userPassword,
      'version': version,
      'platform': platform,
      'policy': policy,
      'kvkk': kvkk,
      'isComp': isComp,
    };

    if (isComp == 1) {
      data['compName'] = compName;
      data['compAddress'] = compAddress;
      data['compCity'] = compCity;
      data['compDistrict'] = compDistrict;
      data['compTaxNumber'] = compTaxNumber;
      data['compTaxPlace'] = compTaxPlace;
    }
    // Boş değerleri göndermemek için null olanları temizle
    data.removeWhere((key, value) => value == null);

    return data;
  }
}

/// Kayıt yanıtındaki 'data' alanı
class RegisterData {
  final int userID;
  final String userToken;
  final String codeToken;

  RegisterData({
    required this.userID,
    required this.userToken,
    required this.codeToken,
  });

  factory RegisterData.fromJson(Map<String, dynamic> json) {
    return RegisterData(
      userID: json['userID'] ?? 0,
      userToken: json['userToken'] ?? '',
      codeToken: json['codeToken'] ?? '',
    );
  }
}

/// Kayıt yanıtı için model
class RegisterResponse {
  final bool error;
  final bool success;
  final String? successMessage;
  final RegisterData? data;
  final bool isTokenError;
  final Map<String, dynamic>? validationErrors;
  final String error_message;

  RegisterResponse({
    required this.error,
    required this.success,
    this.successMessage,
    this.data,
    this.isTokenError = false,
    this.validationErrors,
    required this.error_message,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json, {bool isTokenError = false}) {
    // 'data' alanı bazen string '[]' olarak gelebilir.
    dynamic dataField = json['data'];
    RegisterData? parsedData;
    Map<String, dynamic>? validationData;

    if (dataField is Map<String, dynamic>) {
       if (dataField.containsKey('userID')) {
         parsedData = RegisterData.fromJson(dataField);
       } else {
         validationData = dataField;
       }
    }

    return RegisterResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      successMessage: json['success_message'],
      data: parsedData,
      validationErrors: validationData,
      isTokenError: isTokenError,
      error_message: json['error_message'] ?? '',
    );
  }

  /// Hata mesajını al
  String? get displayMessage {
    if (isTokenError) return 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.';
    if (validationErrors != null && validationErrors!.isNotEmpty) {
       return validationErrors!.values.first.toString();
    }
    return error_message;
  }
}

/// Şifremi unuttum isteği için model
class ForgotPasswordRequest {
  final String userEmail;

  ForgotPasswordRequest({required this.userEmail});

  Map<String, dynamic> toJson() {
    return {'userEmail': userEmail};
  }
}

/// Şifremi unuttum yanıtındaki 'data' alanı
class ForgotPasswordData {
  final String codeToken;

  ForgotPasswordData({required this.codeToken});

  factory ForgotPasswordData.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordData(
      codeToken: json['codeToken'] ?? '',
    );
  }
}

/// Şifremi unuttum yanıtı için model
class ForgotPasswordResponse {
  final bool error;
  final bool success;
  final String? message;
  final ForgotPasswordData? data;
  final String error_message;
  final bool isTokenError;

  ForgotPasswordResponse({
    required this.error,
    required this.success,
    this.message,
    this.data,
    this.isTokenError = false,
    required this.error_message,
  });

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json, {bool isTokenError = false}) {
    return ForgotPasswordResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      message: json['message'] ?? json['success_message'],
      data: json['data'] != null ? ForgotPasswordData.fromJson(json['data']) : null,
      error_message: json['error_message'] ?? '',
      isTokenError: isTokenError,
    );
  }

  /// Hata mesajını al
  String? get displayMessage {
    if (isTokenError) return 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.';
    return error_message;
  }
}

/// Kod doğrulama isteği için model
class CheckCodeRequest {
  final String code;
  final String codeToken;

  CheckCodeRequest({required this.code, required this.codeToken});

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'codeToken': codeToken,
    };
  }
}

/// Şifre sıfırlama isteği için model
class ResetPasswordRequest {
  final String codeToken;
  final String userPassword;

  ResetPasswordRequest({required this.codeToken, required this.userPassword});

  Map<String, dynamic> toJson() {
    return {
      'codeToken': codeToken,
      'userPassword': userPassword,
    };
  }
}


/// Genel amaçlı API yanıt modeli (CheckCode, ResetPassword vb. için)
class GenericAuthResponse {
  final bool error;
  final bool success;
  final String? message;
  final String error_message;
  final bool isTokenError;
  final Map<String, dynamic>? validationErrors;


  GenericAuthResponse({
    required this.error,
    required this.success,
    this.message,
    this.isTokenError = false,
    required this.error_message,
    this.validationErrors,
  });

  factory GenericAuthResponse.fromJson(Map<String, dynamic> json, {bool isTokenError = false}) {
     dynamic dataField = json['data'];
    Map<String, dynamic>? validationData;

    if (dataField is Map<String, dynamic>) {
       if (!dataField.containsKey('userID') && !dataField.containsKey('codeToken')) {
          validationData = dataField;
       }
    }

    return GenericAuthResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      message: json['message'] ?? json['success_message'],
      validationErrors: validationData,
      error_message: json['error_message'] ?? '',
      isTokenError: isTokenError,
    );
  }

  /// Hata mesajını al
  String? get displayMessage {
    if (isTokenError) return 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.';
    if (validationErrors != null && validationErrors!.isNotEmpty) {
      return validationErrors!.values.first.toString();
    }
    return error_message;
  }
}
