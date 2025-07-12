/// Firma detayı ile ilgili model sınıfları

/// Firma detay verilerini temsil eden model
class CompanyDetailModel {
  final int compID;
  final String compName;
  final String compDesc;
  final String compAddress;
  final String compCity;
  final String compDistrict;
  final String compWebSite;
  final int compPersonNumber;
  final int compSectorID;
  final String compSector;
  final String profilePhoto;
  final bool isFavorite;

  CompanyDetailModel({
    required this.compID,
    required this.compName,
    required this.compDesc,
    required this.compAddress,
    required this.compCity,
    required this.compDistrict,
    required this.compWebSite,
    required this.compPersonNumber,
    required this.compSectorID,
    required this.compSector,
    required this.profilePhoto,
    required this.isFavorite,
  });

  /// JSON'dan CompanyDetailModel oluşturur
  factory CompanyDetailModel.fromJson(Map<String, dynamic> json) {
    return CompanyDetailModel(
      compID: json['compID'] ?? 0,
      compName: json['compName'] ?? '',
      compDesc: json['compDesc'] ?? '',
      compAddress: json['compAddress'] ?? '',
      compCity: json['compCity'] ?? '',
      compDistrict: json['compDistrict'] ?? '',
      compWebSite: json['compWebSite'] ?? '',
      compPersonNumber: json['compPersonNumber'] ?? 0,
      compSectorID: json['compSectorID'] ?? 0,
      compSector: json['compSector'] ?? '',
      profilePhoto: json['profilePhoto'] ?? '',
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  /// CompanyDetailModel'i JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'compID': compID,
      'compName': compName,
      'compDesc': compDesc,
      'compAddress': compAddress,
      'compCity': compCity,
      'compDistrict': compDistrict,
      'compWebSite': compWebSite,
      'compPersonNumber': compPersonNumber,
      'compSectorID': compSectorID,
      'compSector': compSector,
      'profilePhoto': profilePhoto,
      'isFavorite': isFavorite,
    };
  }

  /// Firma lokasyonu formatlanmış haliyle döner
  String get formattedLocation {
    final List<String> locationParts = [];
    if (compDistrict.isNotEmpty) locationParts.add(compDistrict);
    if (compCity.isNotEmpty) locationParts.add(compCity);
    return locationParts.join(', ');
  }

  /// Firma açıklaması var mı kontrol eder
  bool get hasDescription => compDesc.isNotEmpty;

  /// Web sitesi var mı kontrol eder
  bool get hasWebsite => compWebSite.isNotEmpty;

  /// Çalışan sayısı formatlanmış haliyle döner
  String get formattedEmployeeCount {
    if (compPersonNumber == 0) return 'Belirtilmemiş';
    if (compPersonNumber == 1) return '1 çalışan';
    return '$compPersonNumber çalışan';
  }
}

/// Firma iş ilanı verilerini temsil eden model
class CompanyJobModel {
  final int jobID;
  final String jobTitle;
  final String jobDesc;
  final String jobImage;
  final String workType;
  final String showDate;

  CompanyJobModel({
    required this.jobID,
    required this.jobTitle,
    required this.jobDesc,
    required this.jobImage,
    required this.workType,
    required this.showDate,
  });

  /// JSON'dan CompanyJobModel oluşturur
  factory CompanyJobModel.fromJson(Map<String, dynamic> json) {
    return CompanyJobModel(
      jobID: json['jobID'] ?? 0,
      jobTitle: json['jobTitle'] ?? '',
      jobDesc: json['jobDesc'] ?? '',
      jobImage: json['jobImage'] ?? '',
      workType: json['workType'] ?? '',
      showDate: json['showDate'] ?? '',
    );
  }

  /// CompanyJobModel'i JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'jobID': jobID,
      'jobTitle': jobTitle,
      'jobDesc': jobDesc,
      'jobImage': jobImage,
      'workType': workType,
      'showDate': showDate,
    };
  }

  /// İş açıklaması var mı kontrol eder
  bool get hasDescription => jobDesc.isNotEmpty;

  /// İş açıklamasının kısa versiyonunu döner
  String get shortDescription {
    if (!hasDescription) return 'İş açıklaması mevcut değil';
    return jobDesc.length > 100 ? '${jobDesc.substring(0, 100)}...' : jobDesc;
  }
}

/// Firma detay sayfası data modeli
class CompanyDetailData {
  final CompanyDetailModel company;
  final List<CompanyJobModel> jobs;

  CompanyDetailData({
    required this.company,
    required this.jobs,
  });

  /// JSON'dan CompanyDetailData oluşturur
  factory CompanyDetailData.fromJson(Map<String, dynamic> json) {
    return CompanyDetailData(
      company: CompanyDetailModel.fromJson(json['company'] ?? {}),
      jobs: (json['jobs'] as List<dynamic>?)
              ?.map((jobJson) => CompanyJobModel.fromJson(jobJson as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// CompanyDetailData'yı JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'company': company.toJson(),
      'jobs': jobs.map((job) => job.toJson()).toList(),
    };
  }

  /// Aktif iş sayısını döner
  int get activeJobCount => jobs.length;

  /// İş ilanları var mı kontrol eder
  bool get hasJobs => jobs.isNotEmpty;

  /// İş türlerine göre gruplama
  Map<String, List<CompanyJobModel>> get jobsByType {
    final Map<String, List<CompanyJobModel>> grouped = {};
    for (final job in jobs) {
      if (!grouped.containsKey(job.workType)) {
        grouped[job.workType] = [];
      }
      grouped[job.workType]!.add(job);
    }
    return grouped;
  }
}

/// Firma detay API yanıtını temsil eden model
class CompanyDetailResponse {
  final bool error;
  final bool success;
  final CompanyDetailData? data;
  final String? status410;
  final String? status417;
  final String errorMessage;
  final bool isTokenError;

  CompanyDetailResponse({
    required this.error,
    required this.success,
    this.data,
    this.status410,
    this.status417,
    required this.errorMessage,
    this.isTokenError = false,
  });

  /// JSON'dan CompanyDetailResponse oluşturur
  factory CompanyDetailResponse.fromJson(Map<String, dynamic> json, {bool isTokenError = false}) {
    return CompanyDetailResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? CompanyDetailData.fromJson(json['data']) : null,
      status410: json['410'],
      status417: json['417'],
      errorMessage: json['error_message'] ?? json['417'] ?? '',
      isTokenError: isTokenError,
    );
  }

  /// CompanyDetailResponse'u JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'success': success,
      'data': data?.toJson(),
      '410': status410,
      '417': status417,
      'error_message': errorMessage,
    };
  }

  /// İstek başarılı mı kontrol eder (410 status başarılı demektir)
  bool get isSuccessful => status410 != null || (!error && success);

  /// Hata mesajını alır
  String? get displayMessage {
    if (isTokenError) return 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.';
    if (status417 != null) return status417;
    return errorMessage.isNotEmpty ? errorMessage : null;
  }
}

/// Firma favorileri için model
class CompanyFavoriteRequest {
  final String userToken;
  final int compID;
  final bool isFavorite;

  CompanyFavoriteRequest({
    required this.userToken,
    required this.compID,
    required this.isFavorite,
  });

  /// JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'compID': compID,
      'isFavorite': isFavorite,
    };
  }
}

/// Firma favorileri API yanıtı
class CompanyFavoriteResponse {
  final bool error;
  final bool success;
  final String? message;
  final String errorMessage;
  final bool isTokenError;

  CompanyFavoriteResponse({
    required this.error,
    required this.success,
    this.message,
    required this.errorMessage,
    this.isTokenError = false,
  });

  /// JSON'dan CompanyFavoriteResponse oluşturur
  factory CompanyFavoriteResponse.fromJson(Map<String, dynamic> json, {bool isTokenError = false}) {
    return CompanyFavoriteResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      message: json['message'] ?? json['success_message'],
      errorMessage: json['error_message'] ?? json['417'] ?? '',
      isTokenError: isTokenError,
    );
  }

  /// Hata mesajını alır
  String? get displayMessage {
    if (isTokenError) return 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.';
    return errorMessage.isNotEmpty ? errorMessage : null;
  }
} 