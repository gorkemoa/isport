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
  final String jobImage;
  final String showDay;
  final String salaryMin;
  final String salaryMax; 
  final String salaryType;
  final String workType;
  final bool isHighlighted;
  final bool isActive;
  final String showDate;
  final String createDate;
  bool isApplied;
  bool isFavorite;
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
    required this.jobImage,
    required this.showDay,
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
      jobImage: json['jobImage'] ?? '',
      showDay: json['showDay'] ?? '',
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
      'jobImage': jobImage,
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
      similarJobs: (json['similar_jobs'] as List<dynamic>?)
              ?.map((jobJson) => SimilarJobModel.fromJson(jobJson as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// JobDetailData'yı JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'job': job.toJson(),
      'similar_jobs': similarJobs.map((job) => job.toJson()).toList(),
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

  /// JobDetailResponse'u JSON'a çevirir
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

  /// İstek başarılı mı kontrol eder
  bool get isSuccessful => status410 != null || (!error && success);

  /// Hata mesajını alır
  String? get displayMessage {
    if (isTokenError) return 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.';
    if (status417 != null) return status417;
    return errorMessage.isNotEmpty ? errorMessage : null;
  }
} 

/// İş başvurusu isteğini temsil eden model
class ApplyJobRequest {
  final String userToken;
  final int jobID;
  final String appNote;

  ApplyJobRequest({
    required this.userToken,
    required this.jobID,
    required this.appNote,
  });

  /// ApplyJobRequest'i JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'jobID': jobID,
      'appNote': appNote,
    };
  }
}

/// İş başvurusu yanıtı data modeli
class ApplyJobData {
  final int appID;

  ApplyJobData({required this.appID});

  /// JSON'dan ApplyJobData oluşturur
  factory ApplyJobData.fromJson(Map<String, dynamic> json) {
    return ApplyJobData(
      appID: json['appID'] ?? 0,
    );
  }

  /// ApplyJobData'yı JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'appID': appID,
    };
  }
}

/// İş başvurusu API yanıtını temsil eden model
class ApplyJobResponse {
  final bool error;
  final bool success;
  final String successMessage;
  final ApplyJobData? data;
  final String? status410;
  final String? status417;
  final String errorMessage;
  final bool isTokenError;

  ApplyJobResponse({
    required this.error,
    required this.success,
    required this.successMessage,
    this.data,
    this.status410,
    this.status417,
    required this.errorMessage,
    this.isTokenError = false,
  });

  /// JSON'dan ApplyJobResponse oluşturur
  factory ApplyJobResponse.fromJson(Map<String, dynamic> json, {bool isTokenError = false}) {
    return ApplyJobResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      successMessage: json['success_message'] ?? '',
      data: json['data'] != null ? ApplyJobData.fromJson(json['data']) : null,
      status410: json['410'],
      status417: json['417'],
      errorMessage: json['error_message'] ?? json['417'] ?? '',
      isTokenError: isTokenError,
    );
  }

  /// ApplyJobResponse'u JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'success': success,
      'success_message': successMessage,
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

  /// Başarı mesajını alır
  String get displaySuccessMessage {
    if (successMessage.isNotEmpty) return successMessage;
    return 'Başvurunuz başarıyla alınmıştır.';
  }
} 

/// İş ilanı ekleme request modeli
class AddJobRequest {
  final String userToken;
  final String jobTitle;
  final String jobDesc;
  final int catID;
  final int jobCity;
  final int jobDistrict;
  final double jobLat;
  final double jobLong;
  final int isHighlighted;
  final int? salaryType;
  final int? salaryMin;
  final int? salaryMax;
  final int workType;
  final List<int>? benefits;

  AddJobRequest({
    required this.userToken,
    required this.jobTitle,
    required this.jobDesc,
    required this.catID,
    required this.jobCity,
    required this.jobDistrict,
    required this.jobLat,
    required this.jobLong,
    this.isHighlighted = 0,
    this.salaryType,
    this.salaryMin,
    this.salaryMax,
    required this.workType,
    this.benefits,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'userToken': userToken,
      'jobTitle': jobTitle,
      'jobDesc': jobDesc,
      'catID': catID,
      'jobCity': jobCity,
      'jobDistrict': jobDistrict,
      'jobLat': jobLat,
      'jobLong': jobLong,
      'isHighlighted': isHighlighted,
      'workType': workType,
    };

    if (salaryType != null) data['salaryType'] = salaryType;
    if (salaryMin != null) data['salaryMin'] = salaryMin;
    if (salaryMax != null) data['salaryMax'] = salaryMax;
    if (benefits != null && benefits!.isNotEmpty) data['benefits'] = benefits;

    return data;
  }
}

/// İş ilanı güncelleme request modeli
class UpdateJobRequest {
  final String userToken;
  final int jobID;
  final String jobTitle;
  final String jobDesc;
  final int catID;
  final int jobCity;
  final int jobDistrict;
  final double jobLat;
  final double jobLong;
  final int isHighlighted;
  final int? salaryType;
  final int? salaryMin;
  final int? salaryMax;
  final int workType;
  final List<int>? benefits;
  final int? isActive;

  UpdateJobRequest({
    required this.userToken,
    required this.jobID,
    required this.jobTitle,
    required this.jobDesc,
    required this.catID,
    required this.jobCity,
    required this.jobDistrict,
    required this.jobLat,
    required this.jobLong,
    this.isHighlighted = 0,
    this.salaryType,
    this.salaryMin,
    this.salaryMax,
    required this.workType,
    this.benefits,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'userToken': userToken,
      'jobID': jobID,
      'jobTitle': jobTitle,
      'jobDesc': jobDesc,
      'catID': catID,
      'jobCity': jobCity,
      'jobDistrict': jobDistrict,
      'jobLat': jobLat,
      'jobLong': jobLong,
      'isHighlighted': isHighlighted,
      'workType': workType,
    };

    if (salaryType != null) data['salaryType'] = salaryType;
    if (salaryMin != null) data['salaryMin'] = salaryMin;
    if (salaryMax != null) data['salaryMax'] = salaryMax;
    if (benefits != null && benefits!.isNotEmpty) data['benefits'] = benefits;
    if (isActive != null) data['isActive'] = isActive;

    return data;
  }
}

/// İş ilanı ekleme/güncelleme response modeli
class JobOperationResponse {
  final bool error;
  final bool success;
  final JobOperationData? data;
  final String? status410;
  final String? status417;
  final String errorMessage;
  final bool isTokenError;

  JobOperationResponse({
    required this.error,
    required this.success,
    this.data,
    this.status410,
    this.status417,
    required this.errorMessage,
    this.isTokenError = false,
  });

  factory JobOperationResponse.fromJson(Map<String, dynamic> json, {bool isTokenError = false}) {
    return JobOperationResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? JobOperationData.fromJson(json['data']) : null,
      status410: json['410'],
      status417: json['417'],
      errorMessage: json['error_message'] ?? json['417'] ?? '',
      isTokenError: isTokenError,
    );
  }

  /// Hata mesajını alır
  String? get displayMessage {
    if (isTokenError) return 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.';
    if (status417 != null) return status417;
    return errorMessage.isNotEmpty ? errorMessage : null;
  }

  /// İstek başarılı mı kontrol eder
  bool get isSuccessful => status410 != null || (!error && success);
}

/// İş ilanı ekleme/güncelleme response data modeli
class JobOperationData {
  final int jobID;
  final String message;

  JobOperationData({
    required this.jobID,
    required this.message,
  });

  factory JobOperationData.fromJson(Map<String, dynamic> json) {
    return JobOperationData(
      jobID: json['jobID'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}

/// Çalışma tipi enum'u
enum WorkType {
  fullTime(1, 'Tam Zamanlı'),
  partTime(2, 'Yarı Zamanlı'),
  contract(3, 'Proje Bazlı'),
  intern(4, 'Stajyer'),
  remote(5, 'Uzaktan');

  const WorkType(this.id, this.displayName);
  final int id;
  final String displayName;

  static WorkType fromId(int id) {
    return WorkType.values.firstWhere((type) => type.id == id, orElse: () => WorkType.fullTime);
  }
}

/// Maaş tipi enum'u
enum SalaryType {
  weekly(1, 'Haftalık'),
  monthly(2, 'Aylık'),
  yearly(3, 'Yıllık'),
  hourly(4, 'Saatlik');

  const SalaryType(this.id, this.displayName);
  final int id;
  final String displayName;

  static SalaryType fromId(int id) {
    return SalaryType.values.firstWhere((type) => type.id == id, orElse: () => SalaryType.monthly);
  }
}

/// Yan haklar enum'u
enum BenefitType {
  transportation(1, 'Yol'),
  meal(2, 'Yemek'),
  healthInsurance(3, 'Özel Sağlık Sigortası'),
  bonus(4, 'Performans Primi'),
  vacation(5, 'Ek Tatil');

  const BenefitType(this.id, this.displayName);
  final int id;
  final String displayName;

  static BenefitType fromId(int id) {
    return BenefitType.values.firstWhere((type) => type.id == id, orElse: () => BenefitType.transportation);
  }

  static List<BenefitType> fromIds(List<int> ids) {
    return ids.map((id) => BenefitType.fromId(id)).toList();
  }
} 

/// İş ilanları listesi API isteği modeli
class JobListRequest {
  final String? userToken;
  final int? catID;
  final List<int>? workTypes;
  final int? cityID;
  final int? districtID;
  final String? publishDate;
  final String? sort;
  final String? latitude;
  final String? longitude;
  final int page;

  JobListRequest({
    this.userToken,
    this.catID,
    this.workTypes,
    this.cityID,
    this.districtID,
    this.publishDate,
    this.sort,
    this.latitude,
    this.longitude,
    required this.page,
  });

  /// JSON'dan JobListRequest oluşturur
  factory JobListRequest.fromJson(Map<String, dynamic> json) {
    return JobListRequest(
      userToken: json['userToken'],
      catID: json['catID'],
      workTypes: json['workTypes'] != null 
          ? List<int>.from(json['workTypes'])
          : null,
      cityID: json['cityID'],
      districtID: json['districtID'],
      publishDate: json['publishDate'],
      sort: json['sort'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      page: json['page'] ?? 1,
    );
  }

  /// JobListRequest'i JSON'a çevirir
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'page': page,
    };
    
    if (userToken != null) data['userToken'] = userToken;
    if (catID != null) data['catID'] = catID;
    if (workTypes != null) data['workTypes'] = workTypes;
    if (cityID != null) data['cityID'] = cityID;
    if (districtID != null) data['districtID'] = districtID;
    if (publishDate != null) data['publishDate'] = publishDate;
    if (sort != null) data['sort'] = sort;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    
    return data;
  }
}

/// İş ilanı listesi öğesi modeli
class JobListItem {
  final int compID;
  final int jobID;
  final String jobTitle;
  final String jobDesc;
  final String jobImage;
  final String jobCity;
  final String? jobDistrict;
  final String compName;
  final String workType;
  final String showDate;
  final bool isFavorite;
  final double? distanceKM;

  JobListItem({
    required this.compID,
    required this.jobID,
    required this.jobTitle,
    required this.jobDesc,
    required this.jobImage,
    required this.jobCity,
    this.jobDistrict,
    required this.compName,
    required this.workType,
    required this.showDate,
    required this.isFavorite,
    this.distanceKM,
  });

  /// JSON'dan JobListItem oluşturur
  factory JobListItem.fromJson(Map<String, dynamic> json) {
    return JobListItem(
      compID: json['compID'] ?? 0,
      jobID: json['jobID'] ?? 0,
      jobTitle: json['jobTitle'] ?? '',
      jobDesc: json['jobDesc'] ?? '',
      jobImage: json['jobImage'] ?? '',
      jobCity: json['jobCity'] ?? '',
      jobDistrict: json['jobDistrict'],
      compName: json['compName'] ?? '',
      workType: json['workType'] ?? '',
      showDate: json['showDate'] ?? '',
      isFavorite: json['isFavorite'] ?? false,
      distanceKM: json['distanceKM'] != null 
          ? double.tryParse(json['distanceKM'].toString())
          : null,
    );
  }

  /// JobListItem'i JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'compID': compID,
      'jobID': jobID,
      'jobTitle': jobTitle,
      'jobDesc': jobDesc,
      'jobImage': jobImage,
      'jobCity': jobCity,
      'jobDistrict': jobDistrict,
      'compName': compName,
      'workType': workType,
      'showDate': showDate,
      'isFavorite': isFavorite,
      'distanceKM': distanceKM,
    };
  }
}

/// İş ilanları listesi API yanıtı modeli
class JobListResponse {
  final bool error;
  final bool success;
  final JobListData? data;
  final String? status410;
  final String? status417;
  final String errorMessage;
  final bool isTokenError;

  JobListResponse({
    required this.error,
    required this.success,
    this.data,
    this.status410,
    this.status417,
    required this.errorMessage,
    this.isTokenError = false,
  });

  /// JSON'dan JobListResponse oluşturur
  factory JobListResponse.fromJson(Map<String, dynamic> json, {bool isTokenError = false}) {
    return JobListResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? JobListData.fromJson(json['data']) : null,
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

  /// JobListResponse'u JSON'a çevirir
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
}

/// İş ilanları listesi data modeli
class JobListData {
  final int page;
  final int pageSize;
  final int totalPages;
  final int totalItems;
  final String emptyMessage;
  final List<JobListItem> jobs;

  JobListData({
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.totalItems,
    required this.emptyMessage,
    required this.jobs,
  });

  /// JSON'dan JobListData oluşturur
  factory JobListData.fromJson(Map<String, dynamic> json) {
    return JobListData(
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      emptyMessage: json['emptyMessage'] ?? '',
      jobs: (json['jobs'] as List<dynamic>?)
              ?.map((jobJson) => JobListItem.fromJson(jobJson as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// JobListData'yı JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'pageSize': pageSize,
      'totalPages': totalPages,
      'totalItems': totalItems,
      'emptyMessage': emptyMessage,
      'jobs': jobs.map((job) => job.toJson()).toList(),
    };
  }
} 