import 'package:flutter/material.dart';

/// Favori iş ilanları ile ilgili model sınıfları

/// Favori iş ilanı verilerini temsil eden model
class FavoriteJobModel {
  final int favID;
  final int compID;
  final int jobID;
  final String jobTitle;
  final String jobDesc;
  final String compName;
  final String workType;
  final String showDate;

  FavoriteJobModel({
    required this.favID,
    required this.compID,
    required this.jobID,
    required this.jobTitle,
    required this.jobDesc,
    required this.compName,
    required this.workType,
    required this.showDate,
  });

  /// JSON'dan FavoriteJobModel oluşturur
  factory FavoriteJobModel.fromJson(Map<String, dynamic> json) {
    return FavoriteJobModel(
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

  /// FavoriteJobModel'i JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'favID': favID,
      'compID': compID,
      'jobID': jobID,
      'jobTitle': jobTitle,
      'jobDesc': jobDesc,
      'compName': compName,
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

  /// İş tipi rengini döner
  Color get workTypeColor {
    switch (workType.toLowerCase()) {
      case 'tam zamanlı':
        return const Color(0xFF059669); // Green
      case 'yarı zamanlı':
        return const Color(0xFF0891B2); // Cyan
      case 'proje bazlı':
        return const Color(0xFF7C3AED); // Purple
      case 'stajyer':
        return const Color(0xFFDC2626); // Red
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  /// Tarih formatını kontrol eder
  bool get isRecent {
    final lowerShowDate = showDate.toLowerCase();
    return lowerShowDate.contains('gün') || 
           lowerShowDate.contains('saat') || 
           lowerShowDate.contains('dakika');
  }

  /// Şirket adı kısaltmasını döner
  String get companyInitials {
    if (compName.isEmpty) return 'N/A';
    final words = compName.split(' ').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return 'N/A';
    if (words.length == 1) return words[0].substring(0, 1).toUpperCase();
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}

/// Favori iş ilanları data modeli
class FavoritesData {
  final List<FavoriteJobModel> favorites;

  FavoritesData({
    required this.favorites,
  });

  /// JSON'dan FavoritesData oluşturur
  factory FavoritesData.fromJson(Map<String, dynamic> json) {
    return FavoritesData(
      favorites: (json['favorites'] as List<dynamic>?)
              ?.map((favoriteJson) => FavoriteJobModel.fromJson(favoriteJson as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// FavoritesData'yı JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'favorites': favorites.map((favorite) => favorite.toJson()).toList(),
    };
  }

  /// Favori sayısını döner
  int get favoriteCount => favorites.length;

  /// Favori var mı kontrol eder
  bool get hasFavorites => favorites.isNotEmpty;

  /// İş türlerine göre gruplama
  Map<String, List<FavoriteJobModel>> get favoritesByWorkType {
    final Map<String, List<FavoriteJobModel>> grouped = {};
    for (final favorite in favorites) {
      if (!grouped.containsKey(favorite.workType)) {
        grouped[favorite.workType] = [];
      }
      grouped[favorite.workType]!.add(favorite);
    }
    return grouped;
  }

  /// Şirketlere göre gruplama
  Map<String, List<FavoriteJobModel>> get favoritesByCompany {
    final Map<String, List<FavoriteJobModel>> grouped = {};
    for (final favorite in favorites) {
      if (!grouped.containsKey(favorite.compName)) {
        grouped[favorite.compName] = [];
      }
      grouped[favorite.compName]!.add(favorite);
    }
    return grouped;
  }

  /// Son zamanlarda eklenen favoriler
  List<FavoriteJobModel> get recentFavorites {
    return favorites.where((favorite) => favorite.isRecent).toList();
  }

  /// Belirli bir şirketten favoriler
  List<FavoriteJobModel> getFavoritesByCompany(String companyName) {
    return favorites.where((favorite) => 
      favorite.compName.toLowerCase().contains(companyName.toLowerCase())
    ).toList();
  }

  /// Belirli bir iş türünden favoriler
  List<FavoriteJobModel> getFavoritesByWorkType(String workType) {
    return favorites.where((favorite) => 
      favorite.workType.toLowerCase().contains(workType.toLowerCase())
    ).toList();
  }

  /// Arama yapar
  List<FavoriteJobModel> searchFavorites(String query) {
    final lowerQuery = query.toLowerCase();
    return favorites.where((favorite) => 
      favorite.jobTitle.toLowerCase().contains(lowerQuery) ||
      favorite.compName.toLowerCase().contains(lowerQuery) ||
      favorite.jobDesc.toLowerCase().contains(lowerQuery) ||
      favorite.workType.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}

/// Favori iş ilanları API yanıtını temsil eden model
class FavoritesResponse {
  final bool error;
  final bool success;
  final FavoritesData? data;
  final String? status410;
  final String? status417;
  final String errorMessage;
  final bool isTokenError;

  FavoritesResponse({
    required this.error,
    required this.success,
    this.data,
    this.status410,
    this.status417,
    required this.errorMessage,
    this.isTokenError = false,
  });

  /// JSON'dan FavoritesResponse oluşturur
  factory FavoritesResponse.fromJson(Map<String, dynamic> json, {bool isTokenError = false}) {
    return FavoritesResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? FavoritesData.fromJson(json['data']) : null,
      status410: json['410'],
      status417: json['417'],
      errorMessage: json['error_message'] ?? json['417'] ?? '',
      isTokenError: isTokenError,
    );
  }

  /// FavoritesResponse'u JSON'a çevirir
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

/// Favori ekleme/çıkarma isteği için model
class ToggleFavoriteRequest {
  final String userToken;
  final int jobID;
  final bool isFavorite;

  ToggleFavoriteRequest({
    required this.userToken,
    required this.jobID,
    required this.isFavorite,
  });

  /// JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'jobID': jobID,
      'isFavorite': isFavorite,
    };
  }
}

/// Favori ekleme/çıkarma API yanıtı
class ToggleFavoriteResponse {
  final bool error;
  final bool success;
  final String? message;
  final String errorMessage;
  final bool isTokenError;

  ToggleFavoriteResponse({
    required this.error,
    required this.success,
    this.message,
    required this.errorMessage,
    this.isTokenError = false,
  });

  /// JSON'dan ToggleFavoriteResponse oluşturur
  factory ToggleFavoriteResponse.fromJson(Map<String, dynamic> json, {bool isTokenError = false}) {
    return ToggleFavoriteResponse(
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

/// Favori iş ilanları için filtreleme seçenekleri
class FavoritesFilter {
  final String? workType;
  final String? companyName;
  final bool showRecentOnly;
  final String sortBy; // 'date', 'title', 'company'
  final bool ascending;

  FavoritesFilter({
    this.workType,
    this.companyName,
    this.showRecentOnly = false,
    this.sortBy = 'date',
    this.ascending = false,
  });

  /// Boş filtre oluşturur
  static FavoritesFilter empty() {
    return FavoritesFilter();
  }

  /// Filtreye göre favorileri filtreler
  List<FavoriteJobModel> applyFilter(List<FavoriteJobModel> favorites) {
    List<FavoriteJobModel> filtered = List.from(favorites);

    // İş türü filtresi
    if (workType != null && workType!.isNotEmpty) {
      filtered = filtered.where((fav) => 
        fav.workType.toLowerCase().contains(workType!.toLowerCase())
      ).toList();
    }

    // Şirket adı filtresi
    if (companyName != null && companyName!.isNotEmpty) {
      filtered = filtered.where((fav) => 
        fav.compName.toLowerCase().contains(companyName!.toLowerCase())
      ).toList();
    }

    // Son zamanlarda eklenenler filtresi
    if (showRecentOnly) {
      filtered = filtered.where((fav) => fav.isRecent).toList();
    }

    // Sıralama
    switch (sortBy) {
      case 'title':
        filtered.sort((a, b) => ascending 
          ? a.jobTitle.compareTo(b.jobTitle)
          : b.jobTitle.compareTo(a.jobTitle));
        break;
      case 'company':
        filtered.sort((a, b) => ascending 
          ? a.compName.compareTo(b.compName)
          : b.compName.compareTo(a.compName));
        break;
      case 'date':
      default:
        // Tarih sıralaması için showDate'e göre sıralayabiliriz
        // Şimdilik favID'ye göre sıralayalım (yeni eklenenler üstte)
        filtered.sort((a, b) => ascending 
          ? a.favID.compareTo(b.favID)
          : b.favID.compareTo(a.favID));
        break;
    }

    return filtered;
  }

  /// Kopya oluşturur
  FavoritesFilter copyWith({
    String? workType,
    String? companyName,
    bool? showRecentOnly,
    String? sortBy,
    bool? ascending,
  }) {
    return FavoritesFilter(
      workType: workType ?? this.workType,
      companyName: companyName ?? this.companyName,
      showRecentOnly: showRecentOnly ?? this.showRecentOnly,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }

  /// Aktif filtre var mı kontrol eder
  bool get hasActiveFilters {
    return (workType != null && workType!.isNotEmpty) ||
           (companyName != null && companyName!.isNotEmpty) ||
           showRecentOnly;
  }
} 