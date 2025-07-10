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
  final CompanyModel? company;

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
    this.company,
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
      company: json['isComp'] == true && json['company'] is Map<String, dynamic>
          ? CompanyModel.fromJson(json['company'])
          : null,
    );
  }
}

/// Kurumsal kullanıcı verilerini temsil eden model.
class CompanyModel {
  final String compName;
  final String compDesc;
  final String compAddress;
  final String compCity;
  final int compCityNo;
  final String compDistrict;
  final int compDistrictNo;
  final String compTaxNumber;
  final String compTaxPlace;

  CompanyModel({
    required this.compName,
    required this.compDesc,
    required this.compAddress,
    required this.compCity,
    required this.compCityNo,
    required this.compDistrict,
    required this.compDistrictNo,
    required this.compTaxNumber,
    required this.compTaxPlace,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      compName: json['compName'] ?? '',
      compDesc: json['compDesc'] ?? '',
      compAddress: json['compAddress'] ?? '',
      compCity: json['compCity'] ?? '',
      compCityNo: json['compCityNo'] ?? 0,
      compDistrict: json['compDistrict'] ?? '',
      compDistrictNo: json['compDistrictNo'] ?? 0,
      compTaxNumber: json['compTaxNumber'] ?? '',
      compTaxPlace: json['compTaxPlace'] ?? '',
    );
  }
}


/// API'den gelen 'data' alanını temsil eden sınıf.
class UserData {
  final UserModel user;

  UserData({required this.user});

  factory UserData.fromJson(Map<String, dynamic> json) {
    // API'den gelen 'user' alanı bir liste mi yoksa doğrudan bir map mi kontrol edelim.
    final userJson = json['user'];
    if (userJson is List && userJson.isNotEmpty) {
      // Eğer bir liste ise ve boş değilse, ilk elemanı al.
      return UserData(
        user: UserModel.fromJson(userJson.first as Map<String, dynamic>),
      );
    } else if (userJson is Map<String, dynamic>) {
      // Eğer doğrudan bir map ise, onu kullan.
      return UserData(
        user: UserModel.fromJson(userJson),
      );
    } else {
      // Beklenmedik bir durum veya boş veri için hata fırlat veya varsayılan bir değer ata.
      // Bu örnekte, boş bir UserModel oluşturuyoruz.
      return UserData(user: UserModel.fromJson({}));
    }
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

/// Kullanıcı şifre güncelleme isteği için model.
class UpdatePasswordRequest {
  final String userToken;
  final String currentPassword;
  final String password;
  final String passwordAgain;

  UpdatePasswordRequest({
    required this.userToken,
    required this.currentPassword,
    required this.password,
    required this.passwordAgain,
  });

  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'currentPassword': currentPassword,
      'password': password,
      'passwordAgain': passwordAgain,
    };
  }
} 