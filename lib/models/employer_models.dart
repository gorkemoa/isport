/// Firma iş ilanları ve başvuruları ile ilgili model sınıfları

/// Firma iş ilanı verilerini temsil eden model
class EmployerJobModel {
  final int jobID;
  final String jobTitle;
  final String jobDesc;
  final String catName;
  final String cityName;
  final String? districtName;
  final String salaryMin;
  final String salaryMax;
  final String salaryType;
  final String workType;
  final bool isHighlighted;
  final bool isActive;
  final String showDate;
  final String createDate;
  final List<String> benefits;

  EmployerJobModel({
    required this.jobID,
    required this.jobTitle,
    required this.jobDesc,
    required this.catName,
    required this.cityName,
    this.districtName,
    required this.salaryMin,
    required this.salaryMax,
    required this.salaryType,
    required this.workType,
    required this.isHighlighted,
    required this.isActive,
    required this.showDate,
    required this.createDate,
    required this.benefits,
  });

  /// JSON'dan EmployerJobModel oluşturur
  factory EmployerJobModel.fromJson(Map<String, dynamic> json) {
    return EmployerJobModel(
      jobID: json['jobID'] ?? 0,
      jobTitle: json['jobTitle'] ?? '',
      jobDesc: json['jobDesc'] ?? '',
      catName: json['catName'] ?? '',
      cityName: json['cityName'] ?? '',
      districtName: json['districtName'],
      salaryMin: json['salaryMin'] ?? '',
      salaryMax: json['salaryMax'] ?? '',
      salaryType: json['salaryType'] ?? '',
      workType: json['workType'] ?? '',
      isHighlighted: json['isHighlighted'] ?? false,
      isActive: json['isActive'] ?? true,
      showDate: json['showDate'] ?? '',
      createDate: json['createDate'] ?? '',
      benefits: (json['benefits'] as List<dynamic>?)
              ?.map((benefit) => benefit.toString())
              .toList() ??
          [],
    );
  }

  /// EmployerJobModel'i JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'jobID': jobID,
      'jobTitle': jobTitle,
      'jobDesc': jobDesc,
      'catName': catName,
      'cityName': cityName,
      'districtName': districtName,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'salaryType': salaryType,
      'workType': workType,
      'isHighlighted': isHighlighted,
      'isActive': isActive,
      'showDate': showDate,
      'createDate': createDate,
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
  String get formattedLocation {
    final List<String> locationParts = [];
    if (districtName != null && districtName!.isNotEmpty) locationParts.add(districtName!);
    if (cityName.isNotEmpty) locationParts.add(cityName);
    return locationParts.join(', ');
  }

  /// İş açıklaması var mı kontrol eder
  bool get hasDescription => jobDesc.isNotEmpty;

  /// İş açıklamasının kısa versiyonunu döner
  String get shortDescription {
    if (!hasDescription) return 'İş açıklaması mevcut değil';
    return jobDesc.length > 100 ? '${jobDesc.substring(0, 100)}...' : jobDesc;
  }

  /// Yan haklar var mı kontrol eder
  bool get hasBenefits => benefits.isNotEmpty;

  /// İş türü rengini döner
  String get workTypeColor {
    switch (workType.toLowerCase()) {
      case 'tam zamanlı':
        return '#059669'; // Green
      case 'yarı zamanlı':
        return '#0891B2'; // Cyan
      case 'proje bazlı':
        return '#7C3AED'; // Purple
      case 'stajyer':
        return '#DC2626'; // Red
      case 'freelance':
        return '#F59E0B'; // Amber
      default:
        return '#6B7280'; // Gray
    }
  }

  /// Tarih formatını kontrol eder
  bool get isRecent {
    final lowerShowDate = showDate.toLowerCase();
    return lowerShowDate.contains('gün') || 
           lowerShowDate.contains('saat') || 
           lowerShowDate.contains('dakika');
  }
}

/// Firma iş ilanları data modeli
class EmployerJobsData {
  final List<EmployerJobModel> jobs;

  EmployerJobsData({
    required this.jobs,
  });

  /// JSON'dan EmployerJobsData oluşturur
  factory EmployerJobsData.fromJson(Map<String, dynamic> json) {
    return EmployerJobsData(
      jobs: (json['jobs'] as List<dynamic>?)
              ?.map((jobJson) => EmployerJobModel.fromJson(jobJson as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// EmployerJobsData'yı JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'jobs': jobs.map((job) => job.toJson()).toList(),
    };
  }

  /// İş sayısını döner
  int get jobCount => jobs.length;

  /// Aktif iş sayısını döner
  int get activeJobCount => jobs.where((job) => job.isActive).length;

  /// Pasif iş sayısını döner
  int get passiveJobCount => jobs.where((job) => !job.isActive).length;

  /// Vurgulanan iş sayısını döner
  int get highlightedJobCount => jobs.where((job) => job.isHighlighted).length;

  /// İş türlerine göre gruplama
  Map<String, List<EmployerJobModel>> get jobsByWorkType {
    final Map<String, List<EmployerJobModel>> grouped = {};
    for (final job in jobs) {
      if (!grouped.containsKey(job.workType)) {
        grouped[job.workType] = [];
      }
      grouped[job.workType]!.add(job);
    }
    return grouped;
  }

  /// Kategorilere göre gruplama
  Map<String, List<EmployerJobModel>> get jobsByCategory {
    final Map<String, List<EmployerJobModel>> grouped = {};
    for (final job in jobs) {
      if (!grouped.containsKey(job.catName)) {
        grouped[job.catName] = [];
      }
      grouped[job.catName]!.add(job);
    }
    return grouped;
  }

  /// Şehirlere göre gruplama
  Map<String, List<EmployerJobModel>> get jobsByCity {
    final Map<String, List<EmployerJobModel>> grouped = {};
    for (final job in jobs) {
      if (!grouped.containsKey(job.cityName)) {
        grouped[job.cityName] = [];
      }
      grouped[job.cityName]!.add(job);
    }
    return grouped;
  }

  /// Son zamanlarda eklenen işler
  List<EmployerJobModel> get recentJobs {
    return jobs.where((job) => job.isRecent).toList();
  }

  /// Aktif işler
  List<EmployerJobModel> get activeJobs {
    return jobs.where((job) => job.isActive).toList();
  }

  /// Vurgulanan işler
  List<EmployerJobModel> get highlightedJobs {
    return jobs.where((job) => job.isHighlighted).toList();
  }

  /// Arama yapar
  List<EmployerJobModel> searchJobs(String query) {
    final lowerQuery = query.toLowerCase();
    return jobs.where((job) => 
      job.jobTitle.toLowerCase().contains(lowerQuery) ||
      job.jobDesc.toLowerCase().contains(lowerQuery) ||
      job.catName.toLowerCase().contains(lowerQuery) ||
      job.cityName.toLowerCase().contains(lowerQuery) ||
      job.workType.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}

/// Firma iş ilanları API yanıtını temsil eden model
class EmployerJobsResponse {
  final bool error;
  final bool success;
  final EmployerJobsData? data;
  final String? status410;
  final String? status417;
  final String errorMessage;
  final bool isTokenError;

  EmployerJobsResponse({
    required this.error,
    required this.success,
    this.data,
    this.status410,
    this.status417,
    required this.errorMessage,
    this.isTokenError = false,
  });

  /// JSON'dan EmployerJobsResponse oluşturur
  factory EmployerJobsResponse.fromJson(Map<String, dynamic> json, {bool isTokenError = false}) {
    return EmployerJobsResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? EmployerJobsData.fromJson(json['data']) : null,
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

  /// İş ilanları var mı kontrol eder
  bool get hasJobs => data?.jobs.isNotEmpty ?? false;

  /// EmployerJobsResponse'u JSON'a çevirir
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

/// Firma iş başvurusu verilerini temsil eden model
class EmployerApplicationModel {
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

  EmployerApplicationModel({
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

  /// JSON'dan EmployerApplicationModel oluşturur
  factory EmployerApplicationModel.fromJson(Map<String, dynamic> json) {
    return EmployerApplicationModel(
      appID: json['appID'] ?? 0,
      userID: json['userID'] ?? 0,
      jobID: json['jobID'] ?? 0,
      jobStatusID: json['jobStatusID'] ?? 0,
      jobTitle: json['jobTitle'] ?? '',
      jobDesc: json['jobDesc'] ?? '',
      userName: json['userName'] ?? '',
      statusName: json['statusName'] ?? '',
      statusColor: json['statusColor'] ?? '#999999',
      isFavorite: json['isFavorite'] ?? false,
      appliedAt: json['appliedAt'] ?? '',
    );
  }

  /// EmployerApplicationModel'i JSON'a çevirir
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

  /// İş açıklaması var mı kontrol eder
  bool get hasDescription => jobDesc.isNotEmpty;

  /// İş açıklamasının kısa versiyonunu döner
  String get shortDescription {
    if (!hasDescription) return 'İş açıklaması mevcut değil';
    return jobDesc.length > 100 ? '${jobDesc.substring(0, 100)}...' : jobDesc;
  }

  /// Kullanıcı adı kısaltmasını döner
  String get userInitials {
    if (userName.isEmpty) return 'N/A';
    final words = userName.split(' ').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return 'N/A';
    if (words.length == 1) return words[0].substring(0, 1).toUpperCase();
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }

  /// Tarih formatını kontrol eder
  bool get isRecent {
    final lowerAppliedAt = appliedAt.toLowerCase();
    return lowerAppliedAt.contains('gün') || 
           lowerAppliedAt.contains('saat') || 
           lowerAppliedAt.contains('dakika');
  }
}

/// Firma iş başvuruları data modeli
class EmployerApplicationsData {
  final List<EmployerApplicationModel> applications;

  EmployerApplicationsData({
    required this.applications,
  });

  /// JSON'dan EmployerApplicationsData oluşturur
  factory EmployerApplicationsData.fromJson(Map<String, dynamic> json) {
    return EmployerApplicationsData(
      applications: (json['applications'] as List<dynamic>?)
              ?.map((appJson) => EmployerApplicationModel.fromJson(appJson as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// EmployerApplicationsData'yı JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'applications': applications.map((app) => app.toJson()).toList(),
    };
  }

  /// Başvuru sayısını döner
  int get applicationCount => applications.length;

  /// Başvuru var mı kontrol eder
  bool get hasApplications => applications.isNotEmpty;

  /// Durumlara göre gruplama
  Map<String, List<EmployerApplicationModel>> get applicationsByStatus {
    final Map<String, List<EmployerApplicationModel>> grouped = {};
    for (final app in applications) {
      if (!grouped.containsKey(app.statusName)) {
        grouped[app.statusName] = [];
      }
      grouped[app.statusName]!.add(app);
    }
    return grouped;
  }

  /// İş ilanlarına göre gruplama
  Map<String, List<EmployerApplicationModel>> get applicationsByJob {
    final Map<String, List<EmployerApplicationModel>> grouped = {};
    for (final app in applications) {
      if (!grouped.containsKey(app.jobTitle)) {
        grouped[app.jobTitle] = [];
      }
      grouped[app.jobTitle]!.add(app);
    }
    return grouped;
  }

  /// Kullanıcılara göre gruplama
  Map<String, List<EmployerApplicationModel>> get applicationsByUser {
    final Map<String, List<EmployerApplicationModel>> grouped = {};
    for (final app in applications) {
      if (!grouped.containsKey(app.userName)) {
        grouped[app.userName] = [];
      }
      grouped[app.userName]!.add(app);
    }
    return grouped;
  }

  /// Son zamanlarda yapılan başvurular
  List<EmployerApplicationModel> get recentApplications {
    return applications.where((app) => app.isRecent).toList();
  }

  /// Favori başvurular
  List<EmployerApplicationModel> get favoriteApplications {
    return applications.where((app) => app.isFavorite).toList();
  }

  /// Arama yapar
  List<EmployerApplicationModel> searchApplications(String query) {
    final lowerQuery = query.toLowerCase();
    return applications.where((app) => 
      app.jobTitle.toLowerCase().contains(lowerQuery) ||
      app.jobDesc.toLowerCase().contains(lowerQuery) ||
      app.userName.toLowerCase().contains(lowerQuery) ||
      app.statusName.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}

/// Firma iş başvuruları API yanıtını temsil eden model
class EmployerApplicationsResponse {
  final bool error;
  final bool success;
  final EmployerApplicationsData? data;
  final String? status410;
  final String? status417;
  final String errorMessage;
  final bool isTokenError;

  EmployerApplicationsResponse({
    required this.error,
    required this.success,
    this.data,
    this.status410,
    this.status417,
    required this.errorMessage,
    this.isTokenError = false,
  });

  /// JSON'dan EmployerApplicationsResponse oluşturur
  factory EmployerApplicationsResponse.fromJson(Map<String, dynamic> json, {bool isTokenError = false}) {
    return EmployerApplicationsResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? EmployerApplicationsData.fromJson(json['data']) : null,
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

  /// Başvuru var mı kontrol eder
  bool get hasApplications => data?.applications.isNotEmpty ?? false;

  /// EmployerApplicationsResponse'u JSON'a çevirir
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

/// Firma favori adayı modeli
class EmployerFavoriteApplicantModel {
  final int favID;
  final int userID;
  final int jobID;
  final String userName;
  final String jobTitle;
  final String favDate;

  EmployerFavoriteApplicantModel({
    required this.favID,
    required this.userID,
    required this.jobID,
    required this.userName,
    required this.jobTitle,
    required this.favDate,
  });

  /// JSON'dan EmployerFavoriteApplicantModel oluşturur
  factory EmployerFavoriteApplicantModel.fromJson(Map<String, dynamic> json) {
    return EmployerFavoriteApplicantModel(
      favID: json['favID'] ?? 0,
      userID: json['userID'] ?? 0,
      jobID: json['jobID'] ?? 0,
      userName: json['userName'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      favDate: json['favDate'] ?? '',
    );
  }

  /// EmployerFavoriteApplicantModel'i JSON'a çevirir
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

  /// Kullanıcı baş harflerini döner
  String get userInitials {
    if (userName.isEmpty) return '?';
    final names = userName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return userName[0].toUpperCase();
  }

  /// Favori tarihini formatlar
  String get formattedDate {
    try {
      final date = DateTime.parse(favDate);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return favDate;
    }
  }

  /// Favori saatini formatlar
  String get formattedTime {
    try {
      final date = DateTime.parse(favDate);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}

/// Firma favori adayları data modeli
class EmployerFavoriteApplicantsData {
  final List<EmployerFavoriteApplicantModel> favorites;

  EmployerFavoriteApplicantsData({
    required this.favorites,
  });

  /// JSON'dan EmployerFavoriteApplicantsData oluşturur
  factory EmployerFavoriteApplicantsData.fromJson(Map<String, dynamic> json) {
    return EmployerFavoriteApplicantsData(
      favorites: (json['favorites'] as List<dynamic>?)
              ?.map((favJson) => EmployerFavoriteApplicantModel.fromJson(favJson as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// EmployerFavoriteApplicantsData'yı JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'favorites': favorites.map((fav) => fav.toJson()).toList(),
    };
  }

  /// Favori aday sayısını döner
  int get favoriteCount => favorites.length;

  /// Favori adaylar var mı kontrol eder
  bool get hasFavorites => favorites.isNotEmpty;

  /// Tarihe göre sıralanmış favori adayları döner
  List<EmployerFavoriteApplicantModel> get sortedFavorites {
    final sorted = List<EmployerFavoriteApplicantModel>.from(favorites);
    sorted.sort((a, b) => b.favDate.compareTo(a.favDate));
    return sorted;
  }
}

/// Firma favori adayları API yanıtını temsil eden model
class EmployerFavoriteApplicantsResponse {
  final bool error;
  final bool success;
  final EmployerFavoriteApplicantsData? data;
  final String? status410;
  final String? status417;
  final String errorMessage;
  final bool isTokenError;

  EmployerFavoriteApplicantsResponse({
    required this.error,
    required this.success,
    this.data,
    this.status410,
    this.status417,
    required this.errorMessage,
    this.isTokenError = false,
  });

  /// JSON'dan EmployerFavoriteApplicantsResponse oluşturur
  factory EmployerFavoriteApplicantsResponse.fromJson(Map<String, dynamic> json, {bool isTokenError = false}) {
    return EmployerFavoriteApplicantsResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? EmployerFavoriteApplicantsData.fromJson(json['data']) : null,
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

  /// Favori aday listesi var mı kontrol eder
  bool get hasFavorites => data?.hasFavorites ?? false;

  /// EmployerFavoriteApplicantsResponse'u JSON'a çevirir
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

/// Favori aday ekleme/çıkarma isteği modeli
class FavoriteApplicantRequest {
  final String userToken;
  final int jobID;
  final int applicantID;

  FavoriteApplicantRequest({
    required this.userToken,
    required this.jobID,
    required this.applicantID,
  });

  /// JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'jobID': jobID,
      'applicantID': applicantID,
    };
  }
}

/// Favori aday ekleme/çıkarma yanıtı data modeli
class FavoriteApplicantData {
  final String message;

  FavoriteApplicantData({
    required this.message,
  });

  /// JSON'dan FavoriteApplicantData oluşturur
  factory FavoriteApplicantData.fromJson(Map<String, dynamic> json) {
    return FavoriteApplicantData(
      message: json['message'] ?? '',
    );
  }

  /// JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'message': message,
    };
  }
}

/// Favori aday ekleme/çıkarma API yanıtını temsil eden model
class FavoriteApplicantResponse {
  final bool error;
  final bool success;
  final FavoriteApplicantData? data;
  final String? status410;
  final String? status417;
  final String errorMessage;
  final bool isTokenError;

  FavoriteApplicantResponse({
    required this.error,
    required this.success,
    this.data,
    this.status410,
    this.status417,
    required this.errorMessage,
    this.isTokenError = false,
  });

  /// JSON'dan FavoriteApplicantResponse oluşturur
  factory FavoriteApplicantResponse.fromJson(Map<String, dynamic> json, {bool isTokenError = false}) {
    return FavoriteApplicantResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? FavoriteApplicantData.fromJson(json['data']) : null,
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

  /// Başarı mesajını alır
  String get displaySuccessMessage {
    if (data != null && data!.message.isNotEmpty) return data!.message;
    return 'İşlem başarıyla tamamlandı.';
  }

  /// FavoriteApplicantResponse'u JSON'a çevirir
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

/// CV verilerini temsil eden model
class CvData {
  final int cvID;
  final String cvTitle;
  final String cvSummary;

  CvData({
    required this.cvID,
    required this.cvTitle,
    required this.cvSummary,
  });

  /// JSON'dan CvData oluşturur
  factory CvData.fromJson(Map<String, dynamic> json) {
    return CvData(
      cvID: json['cvID'] ?? 0,
      cvTitle: json['cvTitle'] ?? '',
      cvSummary: json['cvSummary'] ?? '',
    );
  }

  /// CvData'yı JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'cvID': cvID,
      'cvTitle': cvTitle,
      'cvSummary': cvSummary,
    };
  }

  /// CV başlığı var mı kontrol eder
  bool get hasTitle => cvTitle.isNotEmpty;

  /// CV özeti var mı kontrol eder
  bool get hasSummary => cvSummary.isNotEmpty;
}

/// Başvuru detayı verilerini temsil eden model
class ApplicationDetailModel {
  final int appID;
  final int jobID;
  final int cvID;
  final int userID;
  final String jobTitle;
  final String userName;
  final String userEmail;
  final String userPhone;
  final int statusID;
  final String statusName;
  final String statusColor;
  final String appliedAt;
  final bool isShowContact;
  final CvData cvData;

  ApplicationDetailModel({
    required this.appID,
    required this.jobID,
    required this.cvID,
    required this.userID,
    required this.jobTitle,
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

  /// JSON'dan ApplicationDetailModel oluşturur
  factory ApplicationDetailModel.fromJson(Map<String, dynamic> json) {
    return ApplicationDetailModel(
      appID: json['appID'] ?? 0,
      jobID: json['jobID'] ?? 0,
      cvID: json['cvID'] ?? 0,
      userID: json['userID'] ?? 0,
      jobTitle: json['jobTitle'] ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      userPhone: json['userPhone'] ?? '',
      statusID: json['statusID'] ?? 0,
      statusName: json['statusName'] ?? '',
      statusColor: json['statusColor'] ?? '#999999',
      appliedAt: json['appliedAt'] ?? '',
      isShowContact: json['isShowContact'] ?? false,
      cvData: json['cvData'] != null ? CvData.fromJson(json['cvData']) : CvData(cvID: 0, cvTitle: '', cvSummary: ''),
    );
  }

  /// ApplicationDetailModel'i JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'appID': appID,
      'jobID': jobID,
      'cvID': cvID,
      'userID': userID,
      'jobTitle': jobTitle,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'statusID': statusID,
      'statusName': statusName,
      'statusColor': statusColor,
      'appliedAt': appliedAt,
      'isShowContact': isShowContact,
      'cvData': cvData.toJson(),
    };
  }

  /// Kullanıcı baş harflerini döner
  String get userInitials {
    if (userName.isEmpty) return '?';
    final names = userName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return userName[0].toUpperCase();
  }

  /// Başvuru tarihini formatlar
  String get formattedAppliedAt {
    try {
      final date = DateTime.parse(appliedAt);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return appliedAt;
    }
  }

  /// Başvuru saatini formatlar
  String get formattedAppliedTime {
    try {
      final date = DateTime.parse(appliedAt);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  /// İletişim bilgileri görünür mü kontrol eder
  bool get canShowContact => isShowContact;

  /// CV var mı kontrol eder
  bool get hasCv => cvID > 0;
}

/// Başvuru detayı güncelleme isteği modeli
class ApplicationDetailUpdateRequest {
  final String userToken;
  final int appID;
  final int? newStatus;

  ApplicationDetailUpdateRequest({
    required this.userToken,
    required this.appID,
    this.newStatus,
  });

  /// JSON'a çevirir
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

/// Başvuru detayı güncelleme API yanıtını temsil eden model
class ApplicationDetailUpdateResponse {
  final bool error;
  final bool success;
  final ApplicationDetailModel? data;
  final String? status410;
  final String? status417;
  final String errorMessage;
  final bool isTokenError;

  ApplicationDetailUpdateResponse({
    required this.error,
    required this.success,
    this.data,
    this.status410,
    this.status417,
    required this.errorMessage,
    this.isTokenError = false,
  });

  /// JSON'dan ApplicationDetailUpdateResponse oluşturur
  factory ApplicationDetailUpdateResponse.fromJson(Map<String, dynamic> json, {bool isTokenError = false}) {
    return ApplicationDetailUpdateResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? ApplicationDetailModel.fromJson(json['data']) : null,
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

  /// ApplicationDetailUpdateResponse'u JSON'a çevirir
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