/// Kullanıcı verilerini temsil eden model.
class UserModel {
  final int userID;
  final String username;
  final String userFirstname;
  final String userLastname;
  final String userFullname;
  final String userEmail;
  final String userBirthday;
  final String userPhone;
  final String userRank;
  final String userStatus;
  final String userGender;
  final String userToken;
  final String userPlatform;
  final String userVersion;
  final String iosVersion;
  final String androidVersion;
  final String profilePhoto;
  final bool isApproved;
  final bool isComp;
  final List<dynamic> company; // Tipini bilmiyoruz, simdilik dynamic kalabilir.

  UserModel({
    required this.userID,
    required this.username,
    required this.userFirstname,
    required this.userLastname,
    required this.userFullname,
    required this.userEmail,
    required this.userBirthday,
    required this.userPhone,
    required this.userRank,
    required this.userStatus,
    required this.userGender,
    required this.userToken,
    required this.userPlatform,
    required this.userVersion,
    required this.iosVersion,
    required this.androidVersion,
    required this.profilePhoto,
    required this.isApproved,
    required this.isComp,
    required this.company,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userID: json['userID'] ?? 0,
      username: json['username'] ?? '',
      userFirstname: json['userFirstname'] ?? '',
      userLastname: json['userLastname'] ?? '',
      userFullname: json['userFullname'] ?? '',
      userEmail: json['userEmail'] ?? '',
      userBirthday: json['userBirthday'] ?? '',
      userPhone: json['userPhone'] ?? '',
      userRank: json['userRank'] ?? '',
      userStatus: json['userStatus'] ?? '',
      userGender: json['userGender'] ?? '',
      userToken: json['userToken'] ?? '',
      userPlatform: json['userPlatform'] ?? '',
      userVersion: json['userVersion'] ?? '',
      iosVersion: json['iosVersion'] ?? '',
      androidVersion: json['androidVersion'] ?? '',
      profilePhoto: json['profilePhoto'] ?? '',
      isApproved: json['isApproved'] ?? false,
      isComp: json['isComp'] ?? false,
      company: json['company'] ?? [],
    );
  }
}

/// API'den gelen 'data' alanını temsil eden sınıf.
class UserData {
  final UserModel user;

  UserData({required this.user});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }
}

/// Kullanıcı API yanıtının tamamını temsil eden sınıf.
class UserResponse {
  final bool error;
  final bool success;
  final UserData? data;
  final String? message410;

  UserResponse({
    required this.error,
    required this.success,
    this.data,
    this.message410,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? UserData.fromJson(json['data']) : null,
      message410: json['410'],
    );
  }
}

/// Kullanıcı güncelleme isteği için model.
class UpdateUserRequest {
  final String userToken;
  final String userFirstname;
  final String userLastname;
  final String userEmail;
  final String userPhone;
  final String userBirthday;
  final int userGender; // 1: Erkek, 2: Kadın, 3: Belirtilmemiş
  final String? profilePhoto; // base64 string

  UpdateUserRequest({
    required this.userToken,
    required this.userFirstname,
    required this.userLastname,
    required this.userEmail,
    required this.userPhone,
    required this.userBirthday,
    required this.userGender,
    this.profilePhoto,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {
      'userToken': userToken,
      'userFirstname': userFirstname,
      'userLastname': userLastname,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'userBirthday': userBirthday,
      'userGender': userGender,
    };
    if (profilePhoto != null && profilePhoto!.isNotEmpty) {
      map['profilePhoto'] = profilePhoto;
    }
    return map;
  }
} 