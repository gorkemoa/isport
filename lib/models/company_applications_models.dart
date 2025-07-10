import 'package:flutter/material.dart';

/// Şirket başvuru modeli
class CompanyApplication {
  final int appID;
  final int userID;
  final int jobID;
  final int jobStatusID;
  final String jobTitle;
  final String jobDesc;
  final String userName;
  final String statusName;
  final String statusColor;
  final bool isFavorite;
  final String appliedAt;

  CompanyApplication({
    required this.appID,
    required this.userID,
    required this.jobID,
    required this.jobStatusID,
    required this.jobTitle,
    required this.jobDesc,
    required this.userName,
    required this.statusName,
    required this.statusColor,
    required this.isFavorite,
    required this.appliedAt,
  });

  factory CompanyApplication.fromJson(Map<String, dynamic> json) {
    return CompanyApplication(
      appID: json['appID'] ?? 0,
      userID: json['userID'] ?? 0,
      jobID: json['jobID'] ?? 0,
      jobStatusID: json['jobStatusID'] ?? 0,
      jobTitle: json['jobTitle'] ?? '',
      jobDesc: json['jobDesc'] ?? '',
      userName: json['userName'] ?? '',
      statusName: json['statusName'] ?? '',
      statusColor: json['statusColor'] ?? '#000000',
      isFavorite: json['isFavorite'] ?? false,
      appliedAt: json['appliedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appID': appID,
      'userID': userID,
      'jobID': jobID,
      'jobStatusID': jobStatusID,
      'jobTitle': jobTitle,
      'jobDesc': jobDesc,
      'userName': userName,
      'statusName': statusName,
      'statusColor': statusColor,
      'isFavorite': isFavorite,
      'appliedAt': appliedAt,
    };
  }

  /// Başvuru durumuna göre renk döndürür
  Color get statusColorValue {
    return Color(int.parse(statusColor.replaceFirst('#', '0xFF')));
  }

  /// Başvuru durumuna göre ikon döndürür
  IconData get statusIcon {
    switch (jobStatusID) {
      case 1:
        return Icons.hourglass_empty; // Beklemede
      case 2:
        return Icons.visibility; // İnceleniyor
      case 3:
        return Icons.check_circle; // Onaylandı
      case 4:
        return Icons.cancel; // Reddedildi
      default:
        return Icons.help_outline;
    }
  }

  /// Başvuru zamanının formatlanmış hali
  String get formattedAppliedAt {
    return appliedAt;
  }

  /// İlan açıklamasının kısa hali
  String get shortJobDesc {
    if (jobDesc.length <= 100) return jobDesc;
    return '${jobDesc.substring(0, 100)}...';
  }

  /// Başvuru sahibinin ilk harfi
  String get userInitial {
    return userName.isNotEmpty ? userName[0].toUpperCase() : '?';
  }
}

/// Favori aday modeli
class FavoriteApplicant {
  final int favID;
  final int userID;
  final int jobID;
  final String userName;
  final String jobTitle;
  final String favDate;

  FavoriteApplicant({
    required this.favID,
    required this.userID,
    required this.jobID,
    required this.userName,
    required this.jobTitle,
    required this.favDate,
  });

  factory FavoriteApplicant.fromJson(Map<String, dynamic> json) {
    return FavoriteApplicant(
      favID: json['favID'] ?? 0,
      userID: json['userID'] ?? 0,
      jobID: json['jobID'] ?? 0,
      userName: json['userName'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      favDate: json['favDate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'favID': favID,
      'userID': userID,
      'jobID': jobID,
      'userName': userName,
      'jobTitle': jobTitle,
      'favDate': favDate,
    };
  }

  /// Favori ekleme zamanının formatlanmış hali
  String get formattedFavDate {
    return favDate;
  }

  /// Aday adının ilk harfi
  String get userInitial {
    return userName.isNotEmpty ? userName[0].toUpperCase() : '?';
  }
}

/// Şirket başvuruları listesi verisi
class CompanyApplicationsData {
  final List<CompanyApplication> applications;

  CompanyApplicationsData({required this.applications});

  factory CompanyApplicationsData.fromJson(Map<String, dynamic> json) {
    var applicationsList = json['applications'] as List? ?? [];
    List<CompanyApplication> applications = applicationsList
        .map((i) => CompanyApplication.fromJson(i))
        .toList();
    
    return CompanyApplicationsData(applications: applications);
  }
}

/// Favori adaylar listesi verisi
class FavoriteApplicantsData {
  final List<FavoriteApplicant> favorites;

  FavoriteApplicantsData({required this.favorites});

  factory FavoriteApplicantsData.fromJson(Map<String, dynamic> json) {
    var favoritesList = json['favorites'] as List? ?? [];
    List<FavoriteApplicant> favorites = favoritesList
        .map((i) => FavoriteApplicant.fromJson(i))
        .toList();
    
    return FavoriteApplicantsData(favorites: favorites);
  }
}

/// Şirket başvuruları API yanıtı
class CompanyApplicationsResponse {
  final bool error;
  final bool success;
  final CompanyApplicationsData? data;
  final String? message410;

  CompanyApplicationsResponse({
    required this.error,
    required this.success,
    this.data,
    this.message410,
  });

  factory CompanyApplicationsResponse.fromJson(Map<String, dynamic> json) {
    return CompanyApplicationsResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? CompanyApplicationsData.fromJson(json['data']) : null,
      message410: json['410'],
    );
  }
}

/// Favori adaylar API yanıtı
class FavoriteApplicantsResponse {
  final bool error;
  final bool success;
  final FavoriteApplicantsData? data;
  final String? message410;

  FavoriteApplicantsResponse({
    required this.error,
    required this.success,
    this.data,
    this.message410,
  });

  factory FavoriteApplicantsResponse.fromJson(Map<String, dynamic> json) {
    return FavoriteApplicantsResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? FavoriteApplicantsData.fromJson(json['data']) : null,
      message410: json['410'],
    );
  }
}

/// Favori aday ekleme/silme isteği
class FavoriteApplicantRequest {
  final String userToken;
  final int jobID;
  final int applicantID;

  FavoriteApplicantRequest({
    required this.userToken,
    required this.jobID,
    required this.applicantID,
  });

  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'jobID': jobID,
      'applicantID': applicantID,
    };
  }
}

/// Favori aday ekleme/silme yanıtı
class FavoriteApplicantResponse {
  final bool error;
  final bool success;
  final FavoriteApplicantResponseData? data;
  final String? message410;

  FavoriteApplicantResponse({
    required this.error,
    required this.success,
    this.data,
    this.message410,
  });

  factory FavoriteApplicantResponse.fromJson(Map<String, dynamic> json) {
    return FavoriteApplicantResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? FavoriteApplicantResponseData.fromJson(json['data']) : null,
      message410: json['410'],
    );
  }
}

/// Favori aday ekleme/silme yanıt verisi
class FavoriteApplicantResponseData {
  final String message;

  FavoriteApplicantResponseData({required this.message});

  factory FavoriteApplicantResponseData.fromJson(Map<String, dynamic> json) {
    return FavoriteApplicantResponseData(
      message: json['message'] ?? '',
    );
  }
} 

/// CV verisi
class CvData {
  final int cvID;
  final String cvSummary;

  CvData({
    required this.cvID,
    required this.cvSummary,
  });

  factory CvData.fromJson(Map<String, dynamic> json) {
    return CvData(
      cvID: json['cvID'] ?? 0,
      cvSummary: json['cvSummary'] ?? '',
    );
  }
}

/// Başvuru detayı
class ApplicationDetail {
  final int appID;
  final int jobID;
  final String jobTitle;
  final int userID;
  final String userName;
  final String userEmail;
  final String userPhone;
  final int statusID;
  final String statusName;
  final String statusColor;
  final String appliedAt;
  final bool isShowContact;
  final CvData cvData;

  ApplicationDetail({
    required this.appID,
    required this.jobID,
    required this.jobTitle,
    required this.userID,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.statusID,
    required this.statusName,
    required this.statusColor,
    required this.appliedAt,
    required this.isShowContact,
    required this.cvData,
  });

  factory ApplicationDetail.fromJson(Map<String, dynamic> json) {
    return ApplicationDetail(
      appID: json['appID'] ?? 0,
      jobID: json['jobID'] ?? 0,
      jobTitle: json['jobTitle'] ?? '',
      userID: json['userID'] ?? 0,
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      userPhone: json['userPhone'] ?? '',
      statusID: json['statusID'] ?? 0,
      statusName: json['statusName'] ?? '',
      statusColor: json['statusColor'] ?? '',
      appliedAt: json['appliedAt'] ?? '',
      isShowContact: json['isShowContact'] ?? false,
      cvData: json['cvData'] != null 
          ? CvData.fromJson(json['cvData'])
          : CvData(cvID: 0, cvSummary: ''),
    );
  }

  /// Status rengi Color objesine çevir
  Color get statusColorValue {
    try {
      return Color(int.parse(statusColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  /// Status ikonu
  IconData get statusIcon {
    switch (statusID) {
      case 1:
        return Icons.schedule;
      case 2:
        return Icons.visibility;
      case 3:
        return Icons.check_circle;
      case 4:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  /// Kullanıcı adının ilk harfi
  String get userInitial {
    return userName.isNotEmpty ? userName[0].toUpperCase() : '?';
  }

  /// Başvuru tarihini formatla
  String get formattedAppliedAt {
    return appliedAt;
  }

  /// Telefon numarasını formatla
  String get formattedPhone {
    return userPhone.isNotEmpty ? userPhone : 'Telefon bilgisi yok';
  }

  /// Email'i formatla
  String get formattedEmail {
    return userEmail.isNotEmpty ? userEmail : 'Email bilgisi yok';
  }
}

/// Başvuru detayı isteği
class ApplicationDetailRequest {
  final String userToken;
  final int appID;
  final int? newStatus; // Opsiyonel - sadece durum güncellemesi için

  ApplicationDetailRequest({
    required this.userToken,
    required this.appID,
    this.newStatus,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'userToken': userToken,
      'appID': appID,
    };
    
    if (newStatus != null) {
      data['newStatus'] = newStatus;
    }
    
    return data;
  }
}

/// Başvuru detayı yanıtı
class ApplicationDetailResponse {
  final bool error;
  final bool success;
  final ApplicationDetail? data;
  final String? message410;

  ApplicationDetailResponse({
    required this.error,
    required this.success,
    this.data,
    this.message410,
  });

  factory ApplicationDetailResponse.fromJson(Map<String, dynamic> json) {
    return ApplicationDetailResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? ApplicationDetail.fromJson(json['data']) : null,
      message410: json['410'],
    );
  }
} 