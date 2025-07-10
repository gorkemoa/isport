import 'package:flutter/foundation.dart';
import '../models/company_applications_models.dart';
import '../services/job_service.dart';
import '../services/logger_service.dart';

enum CompanyApplicationsStatus { initial, loading, loaded, error, empty }

/// Şirket başvuruları ViewModel
class CompanyApplicationsViewModel extends ChangeNotifier {
  final JobService _jobService = JobService();

  // Private durumlar
  CompanyApplicationsStatus _status = CompanyApplicationsStatus.initial;
  List<CompanyApplication> _applications = [];
  List<FavoriteApplicant> _favoriteApplicants = [];
  String? _errorMessage;
  bool _isLoading = false;
  int? _companyId;

  // Public getter'lar
  CompanyApplicationsStatus get status => _status;
  List<CompanyApplication> get applications => _applications;
  List<FavoriteApplicant> get favoriteApplicants => _favoriteApplicants;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get hasApplications => _applications.isNotEmpty;
  bool get hasFavorites => _favoriteApplicants.isNotEmpty;

  // Filtreleme - Başvuru durumuna göre
  List<CompanyApplication> get newApplications => 
      _applications.where((app) => app.jobStatusID == 1).toList();
  
  List<CompanyApplication> get reviewedApplications => 
      _applications.where((app) => app.jobStatusID == 2).toList();
  
  List<CompanyApplication> get approvedApplications => 
      _applications.where((app) => app.jobStatusID == 3).toList();
  
  List<CompanyApplication> get rejectedApplications => 
      _applications.where((app) => app.jobStatusID == 4).toList();

  // İstatistikler
  int get totalApplicationsCount => _applications.length;
  int get newApplicationsCount => newApplications.length;
  int get reviewedApplicationsCount => reviewedApplications.length;
  int get approvedApplicationsCount => approvedApplications.length;
  int get rejectedApplicationsCount => rejectedApplications.length;
  int get totalFavoritesCount => _favoriteApplicants.length;

  /// Company ID'sini ayarla
  void setCompanyId(int companyId) {
    _companyId = companyId;
  }

  /// Şirket başvurularını getir
  Future<void> fetchCompanyApplications({
    String? userToken, 
    int? jobID,
    bool isRefresh = false,
  }) async {
    if (_companyId == null) {
      logger.e('Company ID not set');
      _setError('Şirket ID\'si belirtilmedi');
      return;
    }

    if (isRefresh) {
      _applications.clear();
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _jobService.getCompanyApplications(
        companyId: _companyId!,
        userToken: userToken,
        jobID: jobID,
      );

      if (response.success && response.data != null) {
        _applications = response.data!.applications;
        
        if (_applications.isEmpty) {
          _setStatus(CompanyApplicationsStatus.empty);
        } else {
          _setStatus(CompanyApplicationsStatus.loaded);
        }
      } else {
        _setError(response.message410 ?? 'Başvurular getirilemedi');
        _setStatus(CompanyApplicationsStatus.error);
      }
    } catch (e) {
      logger.e('Company applications fetch error: $e');
      _setError('Başvurular getirilirken hata oluştu: $e');
      _setStatus(CompanyApplicationsStatus.error);
    }

    _setLoading(false);
  }

  /// Favori adayları getir
  Future<void> fetchFavoriteApplicants({String? userToken, bool isRefresh = false}) async {
    if (_companyId == null) {
      logger.e('Company ID not set');
      return;
    }

    if (isRefresh) {
      _favoriteApplicants.clear();
    }

    try {
      final response = await _jobService.getFavoriteApplicants(
        companyId: _companyId!,
        userToken: userToken,
      );

      if (response.success && response.data != null) {
        _favoriteApplicants = response.data!.favorites;
        notifyListeners();
      }
    } catch (e) {
      logger.e('Favorite applicants fetch error: $e');
    }
  }

  /// Başvuru durumuna göre filtrele
  List<CompanyApplication> getApplicationsByStatus(int statusId) {
    return _applications.where((app) => app.jobStatusID == statusId).toList();
  }

  /// İlan ID'sine göre başvuruları filtrele
  List<CompanyApplication> getApplicationsByJobId(int jobId) {
    return _applications.where((app) => app.jobID == jobId).toList();
  }

  /// Kullanıcı ID'sine göre başvuruları filtrele
  List<CompanyApplication> getApplicationsByUserId(int userId) {
    return _applications.where((app) => app.userID == userId).toList();
  }

  /// Başvuru arama
  List<CompanyApplication> searchApplications(String query) {
    if (query.isEmpty) return _applications;
    
    final lowercaseQuery = query.toLowerCase();
    return _applications.where((app) {
      return app.userName.toLowerCase().contains(lowercaseQuery) ||
             app.jobTitle.toLowerCase().contains(lowercaseQuery) ||
             app.statusName.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Favori aday arama
  List<FavoriteApplicant> searchFavoriteApplicants(String query) {
    if (query.isEmpty) return _favoriteApplicants;
    
    final lowercaseQuery = query.toLowerCase();
    return _favoriteApplicants.where((fav) {
      return fav.userName.toLowerCase().contains(lowercaseQuery) ||
             fav.jobTitle.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Başvuru ID'sine göre başvuru bul
  CompanyApplication? findApplicationById(int appId) {
    try {
      return _applications.firstWhere((app) => app.appID == appId);
    } catch (e) {
      return null;
    }
  }

  /// Favori aday ID'sine göre favori bul
  FavoriteApplicant? findFavoriteById(int favId) {
    try {
      return _favoriteApplicants.firstWhere((fav) => fav.favID == favId);
    } catch (e) {
      return null;
    }
  }

  /// Başvuru durumunu değiştir (local olarak)
  void updateApplicationStatus(int appId, int newStatusId, String newStatusName, String newStatusColor) {
    final index = _applications.indexWhere((app) => app.appID == appId);
    if (index != -1) {
      final app = _applications[index];
      final updatedApp = CompanyApplication(
        appID: app.appID,
        userID: app.userID,
        jobID: app.jobID,
        jobStatusID: newStatusId,
        jobTitle: app.jobTitle,
        jobDesc: app.jobDesc,
        userName: app.userName,
        statusName: newStatusName,
        statusColor: newStatusColor,
        isFavorite: app.isFavorite,
        appliedAt: app.appliedAt,
      );
      _applications[index] = updatedApp;
      notifyListeners();
    }
  }

  /// Başvuru favori durumunu değiştir (API call ile)
  Future<bool> toggleApplicationFavorite(int appId, String userToken) async {
    final application = findApplicationById(appId);
    if (application == null) {
      logger.e('Application not found with ID: $appId');
      return false;
    }

    try {
      final request = FavoriteApplicantRequest(
        userToken: userToken,
        jobID: application.jobID,
        applicantID: application.userID,
      );

      final response = await _jobService.toggleFavoriteApplicant(request);

      if (response.success) {
        // API başarılı olduğunda local state'i güncelle
        final index = _applications.indexWhere((app) => app.appID == appId);
        if (index != -1) {
          final app = _applications[index];
          final updatedApp = CompanyApplication(
            appID: app.appID,
            userID: app.userID,
            jobID: app.jobID,
            jobStatusID: app.jobStatusID,
            jobTitle: app.jobTitle,
            jobDesc: app.jobDesc,
            userName: app.userName,
            statusName: app.statusName,
            statusColor: app.statusColor,
            isFavorite: !app.isFavorite,
            appliedAt: app.appliedAt,
          );
          _applications[index] = updatedApp;
          
          // Favori listesini güncelle
          if (updatedApp.isFavorite) {
            // Favorilere ekle
            final favoriteApplicant = FavoriteApplicant(
              favID: DateTime.now().millisecondsSinceEpoch, // Geçici ID
              userID: updatedApp.userID,
              jobID: updatedApp.jobID,
              userName: updatedApp.userName,
              jobTitle: updatedApp.jobTitle,
              favDate: DateTime.now().toString(),
            );
            _favoriteApplicants.add(favoriteApplicant);
          } else {
            // Favorilerden kaldır
            _favoriteApplicants.removeWhere((fav) => 
                fav.userID == updatedApp.userID && fav.jobID == updatedApp.jobID);
          }
          
          notifyListeners();
          return true;
        }
      } else {
        logger.e('Failed to toggle favorite: ${response.message410}');
        return false;
      }
    } catch (e) {
      logger.e('Error toggling favorite: $e');
      return false;
    }
    
    return false;
  }

  /// Başvuru sil (local olarak)
  void removeApplication(int appId) {
    _applications.removeWhere((app) => app.appID == appId);
    
    if (_applications.isEmpty) {
      _setStatus(CompanyApplicationsStatus.empty);
    }
    
    notifyListeners();
  }

  /// Favori adayı sil (local olarak)
  void removeFavoriteApplicant(int favId) {
    _favoriteApplicants.removeWhere((fav) => fav.favID == favId);
    notifyListeners();
  }

  /// Verileri temizle
  void clearData() {
    _applications.clear();
    _favoriteApplicants.clear();
    _setStatus(CompanyApplicationsStatus.initial);
    _clearError();
    notifyListeners();
  }

  /// Hem başvurular hem de favori adayları yükle
  Future<void> loadAllData({String? userToken, bool isRefresh = false}) async {
    await Future.wait([
      fetchCompanyApplications(userToken: userToken, isRefresh: isRefresh),
      fetchFavoriteApplicants(userToken: userToken, isRefresh: isRefresh),
    ]);
  }

  // Private helper metodlar
  void _setStatus(CompanyApplicationsStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setStatus(CompanyApplicationsStatus.error);
  }

  void _clearError() {
    _errorMessage = null;
  }
} 