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
  final String? message410;
  final Map<String, dynamic>? validationErrors;

  RegisterResponse({
    required this.error,
    required this.success,
    this.successMessage,
    this.data,
    this.message410,
    this.validationErrors,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
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
      message410: json['410'],
    );
  }
}
