/// İş ilanı verilerini temsil eden model
class JobModel {
  final int jobID;
  final String jobTitle;
  final String workType;
  final String showDate;

  JobModel({
    required this.jobID,
    required this.jobTitle,
    required this.workType,
    required this.showDate,
  });

  /// JSON'dan JobModel oluşturur
  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      jobID: json['jobID'] ?? 0,
      jobTitle: json['jobTitle'] ?? '',
      workType: json['workType'] ?? '',
      showDate: json['showDate'] ?? '',
    );
  }

  /// JobModel'i JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'jobID': jobID,
      'jobTitle': jobTitle,
      'workType': workType,
      'showDate': showDate,
    };
  }
}

/// Şirket detay verilerini temsil eden model
class CompanyDetailModel {
  final int compID;
  final String compName;
  final String compDesc;
  final String compAddress;
  final String compCity;
  final String compDistrict;
  final String profilePhoto;

  CompanyDetailModel({
    required this.compID,
    required this.compName,
    required this.compDesc,
    required this.compAddress,
    required this.compCity,
    required this.compDistrict,
    required this.profilePhoto,
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
      profilePhoto: json['profilePhoto'] ?? '',
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
      'profilePhoto': profilePhoto,
    };
  }
}

/// İş ilanları listesi data modeli
class JobListingData {
  final CompanyDetailModel company;
  final List<JobModel> jobs;

  JobListingData({
    required this.company,
    required this.jobs,
  });

  /// JSON'dan JobListingData oluşturur
  factory JobListingData.fromJson(Map<String, dynamic> json) {
    return JobListingData(
      company: CompanyDetailModel.fromJson(json['company'] ?? {}),
      jobs: (json['jobs'] as List<dynamic>?)
              ?.map((jobJson) => JobModel.fromJson(jobJson as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// JobListingData'yı JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'company': company.toJson(),
      'jobs': jobs.map((job) => job.toJson()).toList(),
    };
  }
}

/// İş ilanları API yanıtını temsil eden model
class JobListingResponse {
  final bool error;
  final bool success;
  final JobListingData? data;
  final String? status410;
  final String? status417;
  final String errorMessage;
  final bool isTokenError;

  JobListingResponse({
    required this.error,
    required this.success,
    this.data,
    this.status410,
    this.status417,
    required this.errorMessage,
    this.isTokenError = false,
  });

  /// JSON'dan JobListingResponse oluşturur
  factory JobListingResponse.fromJson(Map<String, dynamic> json, {bool isTokenError = false}) {
    return JobListingResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? JobListingData.fromJson(json['data']) : null,
      status410: json['410'],
      status417: json['417'],
      errorMessage: json['error_message'] ?? json['417'] ?? '',
      isTokenError: isTokenError,
    );
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

/// İş detayı verilerini temsil eden model
class JobDetailModel {
  final int jobID;
  final String jobTitle;
  final String jobDesc;
  final String catName;
  final String cityName;
  final String districtName;
  final int compID;
  final String compName;
  final String salaryMin;
  final String salaryMax;
  final String salaryType;
  final String workType;
  final bool isHighlighted;
  final bool isActive;
  final String showDate;
  final String createDate;
  final bool isApplied;
  final bool isFavorite;
  final List<String> benefits;

  JobDetailModel({
    required this.jobID,
    required this.jobTitle,
    required this.jobDesc,
    required this.catName,
    required this.cityName,
    required this.districtName,
    required this.compID,
    required this.compName,
    required this.salaryMin,
    required this.salaryMax,
    required this.salaryType,
    required this.workType,
    required this.isHighlighted,
    required this.isActive,
    required this.showDate,
    required this.createDate,
    required this.isApplied,
    required this.isFavorite,
    required this.benefits,
  });

  /// JSON'dan JobDetailModel oluşturur
  factory JobDetailModel.fromJson(Map<String, dynamic> json) {
    return JobDetailModel(
      jobID: json['jobID'] ?? 0,
      jobTitle: json['jobTitle'] ?? '',
      jobDesc: json['jobDesc'] ?? '',
      catName: json['catName'] ?? '',
      cityName: json['cityName'] ?? '',
      districtName: json['districtName'] ?? '',
      compID: json['compID'] ?? 0,
      compName: json['compName'] ?? '',
      salaryMin: json['salaryMin'] ?? '',
      salaryMax: json['salaryMax'] ?? '',
      salaryType: json['salaryType'] ?? '',
      workType: json['workType'] ?? '',
      isHighlighted: json['isHighlighted'] ?? false,
      isActive: json['isActive'] ?? true,
      showDate: json['showDate'] ?? '',
      createDate: json['createDate'] ?? '',
      isApplied: json['isApplied'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
      benefits: (json['benefits'] as List<dynamic>?)
              ?.map((benefit) => benefit.toString())
              .toList() ??
          [],
    );
  }

  /// JobDetailModel'i JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'jobID': jobID,
      'jobTitle': jobTitle,
      'jobDesc': jobDesc,
      'catName': catName,
      'cityName': cityName,
      'districtName': districtName,
      'compID': compID,
      'compName': compName,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'salaryType': salaryType,
      'workType': workType,
      'isHighlighted': isHighlighted,
      'isActive': isActive,
      'showDate': showDate,
      'createDate': createDate,
      'isApplied': isApplied,
      'isFavorite': isFavorite,
      'benefits': benefits,
    };
  }

  /// Maaş aralığını formatlar
  String get formattedSalary {
    if (salaryMin.isEmpty && salaryMax.isEmpty) return 'Belirtilmemiş';
    if (salaryMin.isEmpty) return 'Maks. $salaryMax $salaryType';
    if (salaryMax.isEmpty) return 'Min. $salaryMin $salaryType';
    return '$salaryMin - $salaryMax $salaryType';
  }

  /// Lokasyon bilgisini formatlar
  String get formattedLocation => '$districtName, $cityName';
}

/// Benzer iş ilanı verilerini temsil eden model
class SimilarJobModel {
  final int jobID;
  final String jobTitle;
  final int compID;
  final String compName;
  final String showDate;

  SimilarJobModel({
    required this.jobID,
    required this.jobTitle,
    required this.compID,
    required this.compName,
    required this.showDate,
  });

  /// JSON'dan SimilarJobModel oluşturur
  factory SimilarJobModel.fromJson(Map<String, dynamic> json) {
    return SimilarJobModel(
      jobID: json['jobID'] ?? 0,
      jobTitle: json['jobTitle'] ?? '',
      compID: json['compID'] ?? 0,
      compName: json['compName'] ?? '',
      showDate: json['showDate'] ?? '',
    );
  }

  /// SimilarJobModel'i JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'jobID': jobID,
      'jobTitle': jobTitle,
      'compID': compID,
      'compName': compName,
      'showDate': showDate,
    };
  }
}

/// İş detayı data modeli
class JobDetailData {
  final JobDetailModel job;
  final List<SimilarJobModel> similarJobs;

  JobDetailData({
    required this.job,
    required this.similarJobs,
  });

  /// JSON'dan JobDetailData oluşturur
  factory JobDetailData.fromJson(Map<String, dynamic> json) {
    return JobDetailData(
      job: JobDetailModel.fromJson(json['job'] ?? {}),
      similarJobs: (json['similarJobs'] as List<dynamic>?)
              ?.map((jobJson) => SimilarJobModel.fromJson(jobJson as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// JobDetailData'yı JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'job': job.toJson(),
      'similarJobs': similarJobs.map((job) => job.toJson()).toList(),
    };
  }
}

/// İş detayı API yanıtını temsil eden model
class JobDetailResponse {
  final bool error;
  final bool success;
  final JobDetailData? data;
  final String? status410;
  final String? status417;
  final String errorMessage;
  final bool isTokenError;

  JobDetailResponse({
    required this.error,
    required this.success,
    this.data,
    this.status410,
    this.status417,
    required this.errorMessage,
    this.isTokenError = false,
  });

  /// JSON'dan JobDetailResponse oluşturur
  factory JobDetailResponse.fromJson(Map<String, dynamic> json, {bool isTokenError = false}) {
    return JobDetailResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? JobDetailData.fromJson(json['data']) : null,
      status410: json['410'],
      status417: json['417'],
      errorMessage: json['error_message'] ?? json['417'] ?? '',
      isTokenError: isTokenError,
    );
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