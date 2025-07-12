/// İş başvurusu verilerini temsil eden model
class ApplicationModel {
  final int appID;
  final int jobID;
  final String jobTitle;
  final String jobDesc;
  final String statusName;
  final String statusColor;
  final String appliedAt;

  ApplicationModel({
    required this.appID,
    required this.jobID,
    required this.jobTitle,
    required this.jobDesc,
    required this.statusName,
    required this.statusColor,
    required this.appliedAt,
  });

  /// JSON'dan ApplicationModel oluşturur
  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      appID: json['appID'] ?? 0,
      jobID: json['jobID'] ?? 0,
      jobTitle: json['jobTitle'] ?? '',
      jobDesc: json['jobDesc'] ?? '',
      statusName: json['statusName'] ?? '',
      statusColor: json['statusColor'] ?? '#999999',
      appliedAt: json['appliedAt'] ?? '',
    );
  }

  /// ApplicationModel'i JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'appID': appID,
      'jobID': jobID,
      'jobTitle': jobTitle,
      'jobDesc': jobDesc,
      'statusName': statusName,
      'statusColor': statusColor,
      'appliedAt': appliedAt,
    };
  }
}

/// Başvuru listesi data modeli
class ApplicationListData {
  final List<ApplicationModel> applications;

  ApplicationListData({
    required this.applications,
  });

  /// JSON'dan ApplicationListData oluşturur
  factory ApplicationListData.fromJson(Map<String, dynamic> json) {
    return ApplicationListData(
      applications: (json['applications'] as List<dynamic>?)
              ?.map((appJson) => ApplicationModel.fromJson(appJson as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// ApplicationListData'yı JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'applications': applications.map((app) => app.toJson()).toList(),
    };
  }
}

/// Başvuru listesi API yanıtını temsil eden model
class ApplicationListResponse {
  final bool error;
  final bool success;
  final ApplicationListData? data;
  final String? status410;
  final String? status417;
  final String errorMessage;
  final bool isTokenError;

  ApplicationListResponse({
    required this.error,
    required this.success,
    this.data,
    this.status410,
    this.status417,
    required this.errorMessage,
    this.isTokenError = false,
  });

  /// JSON'dan ApplicationListResponse oluşturur
  factory ApplicationListResponse.fromJson(Map<String, dynamic> json, {bool isTokenError = false}) {
    return ApplicationListResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? ApplicationListData.fromJson(json['data']) : null,
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

  /// Başvuru listesi var mı kontrol eder
  bool get hasApplications => data?.applications.isNotEmpty ?? false;

  /// ApplicationListResponse'u JSON'a çevirir
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