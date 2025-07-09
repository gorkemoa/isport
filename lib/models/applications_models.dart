/// Başvuru verilerini temsil eden model
class Application {
  final int appID;
  final int jobID;
  final String jobTitle;
  final String jobDesc;
  final String statusName;
  final String statusColor;
  final String appliedAt;

  Application({
    required this.appID,
    required this.jobID,
    required this.jobTitle,
    required this.jobDesc,
    required this.statusName,
    required this.statusColor,
    required this.appliedAt,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      appID: json['appID'] ?? 0,
      jobID: json['jobID'] ?? 0,
      jobTitle: json['jobTitle'] ?? '',
      jobDesc: json['jobDesc'] ?? '',
      statusName: json['statusName'] ?? '',
      statusColor: json['statusColor'] ?? '#666666',
      appliedAt: json['appliedAt'] ?? '',
    );
  }
}

/// Başvuru listesi verilerini temsil eden model
class ApplicationsData {
  final List<Application> applications;

  ApplicationsData({required this.applications});

  factory ApplicationsData.fromJson(Map<String, dynamic> json) {
    return ApplicationsData(
      applications: json['applications'] != null
          ? (json['applications'] as List).map((item) => Application.fromJson(item)).toList()
          : <Application>[],
    );
  }
}

/// Başvuru API yanıtını temsil eden model
class ApplicationsResponse {
  final bool error;
  final bool success;
  final ApplicationsData? data;
  final String? message410;

  ApplicationsResponse({
    required this.error,
    required this.success,
    this.data,
    this.message410,
  });

  factory ApplicationsResponse.fromJson(Map<String, dynamic> json) {
    return ApplicationsResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? ApplicationsData.fromJson(json['data']) : null,
      message410: json['410'],
    );
  }
}

/// Favori ilanı temsil eden model
class Favorite {
  final int favID;
  final int compID;
  final int jobID;
  final String jobTitle;
  final String jobDesc;
  final String compName;
  final String workType;
  final String showDate;

  Favorite({
    required this.favID,
    required this.compID,
    required this.jobID,
    required this.jobTitle,
    required this.jobDesc,
    required this.compName,
    required this.workType,
    required this.showDate,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      favID: json['favID'] ?? 0,
      compID: json['compID'] ?? 0,
      jobID: json['jobID'] ?? 0,
      jobTitle: json['jobTitle'] ?? '',
      jobDesc: json['jobDesc'] ?? '',
      compName: json['compName'] ?? '',
      workType: json['workType'] ?? '',
      showDate: json['showDate'] ?? '',
    );
  }
}

/// Favori listesi verilerini temsil eden model
class FavoritesData {
  final List<Favorite> favorites;

  FavoritesData({required this.favorites});

  factory FavoritesData.fromJson(Map<String, dynamic> json) {
    return FavoritesData(
      favorites: json['favorites'] != null
          ? (json['favorites'] as List).map((item) => Favorite.fromJson(item)).toList()
          : <Favorite>[],
    );
  }
}

/// Favori API yanıtını temsil eden model
class FavoritesResponse {
  final bool error;
  final bool success;
  final FavoritesData? data;
  final String? message410;

  FavoritesResponse({
    required this.error,
    required this.success,
    this.data,
    this.message410,
  });

  factory FavoritesResponse.fromJson(Map<String, dynamic> json) {
    return FavoritesResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? FavoritesData.fromJson(json['data']) : null,
      message410: json['410'],
    );
  }
} 