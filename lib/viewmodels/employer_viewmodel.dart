import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/employer_models.dart';
import '../services/employer_service.dart';
import '../services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/employer_models.dart';
import 'dart:convert';

/// İşveren state management'ı
class EmployerViewModel extends ChangeNotifier {
  final EmployerService _employerService = EmployerService();

  // Private state variables
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  
  // İş ilanları state variables
  bool _isJobsLoading = false;
  EmployerJobsData? _jobsData;
  String? _jobsErrorMessage;
  
  // Başvurular state variables
  bool _isApplicationsLoading = false;
  EmployerApplicationsData? _applicationsData;
  String? _applicationsErrorMessage;
  
  // Favori adaylar state variables
  bool _isFavoriteApplicantsLoading = false;
  EmployerFavoriteApplicantsData? _favoriteApplicantsData;
  String? _favoriteApplicantsErrorMessage;

  // Public getters
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  
  // İş ilanları getters
  bool get isJobsLoading => _isJobsLoading;
  EmployerJobsData? get jobsData => _jobsData;
  String? get jobsErrorMessage => _jobsErrorMessage;
  bool get hasJobsError => _jobsErrorMessage != null;
  bool get hasJobs => _jobsData?.jobs.isNotEmpty ?? false;
  int get jobsCount => _jobsData?.jobCount ?? 0;
  
  // Başvurular getters
  bool get isApplicationsLoading => _isApplicationsLoading;
  EmployerApplicationsData? get applicationsData => _applicationsData;
  String? get applicationsErrorMessage => _applicationsErrorMessage;
  bool get hasApplicationsError => _applicationsErrorMessage != null;
  bool get hasApplications => _applicationsData?.hasApplications ?? false;
  int get applicationsCount => _applicationsData?.applicationCount ?? 0;
  
  // Favori adaylar getters
  bool get isFavoriteApplicantsLoading => _isFavoriteApplicantsLoading;
  EmployerFavoriteApplicantsData? get favoriteApplicantsData => _favoriteApplicantsData;
  String? get favoriteApplicantsErrorMessage => _favoriteApplicantsErrorMessage;
  bool get hasFavoriteApplicantsError => _favoriteApplicantsErrorMessage != null;
  bool get hasFavoriteApplicants => _favoriteApplicantsData?.hasFavorites ?? false;
  int get favoriteApplicantsCount => _favoriteApplicantsData?.favoriteCount ?? 0;

  /// Loading state'i günceller
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Refreshing state'i günceller
  void _setRefreshing(bool refreshing) {
    _isRefreshing = refreshing;
    notifyListeners();
  }

  /// Error mesajını günceller
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Error'ı temizler
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// İş ilanları loading state'i günceller
  void _setJobsLoading(bool loading) {
    _isJobsLoading = loading;
    notifyListeners();
  }

  /// İş ilanları error mesajını günceller
  void _setJobsError(String? error) {
    _jobsErrorMessage = error;
    notifyListeners();
  }

  /// İş ilanları error'ı temizler
  void clearJobsError() {
    _jobsErrorMessage = null;
    notifyListeners();
  }

  /// Başvurular loading state'i günceller
  void _setApplicationsLoading(bool loading) {
    _isApplicationsLoading = loading;
    notifyListeners();
  }

  /// Başvurular error mesajını günceller
  void _setApplicationsError(String? error) {
    _applicationsErrorMessage = error;
    notifyListeners();
  }

  /// Başvurular error'ı temizler
  void clearApplicationsError() {
    _applicationsErrorMessage = null;
    notifyListeners();
  }

  /// Favori adaylar loading state'i günceller
  void _setFavoriteApplicantsLoading(bool loading) {
    _isFavoriteApplicantsLoading = loading;
    notifyListeners();
  }

  /// Favori adaylar error mesajını günceller
  void _setFavoriteApplicantsError(String? error) {
    _favoriteApplicantsErrorMessage = error;
    notifyListeners();
  }

  /// Favori adaylar error'ı temizler
  void clearFavoriteApplicantsError() {
    _favoriteApplicantsErrorMessage = null;
    notifyListeners();
  }

  /// İş ilanlarını yükler
  Future<void> loadJobs({bool showLoading = true}) async {
    try {
      if (showLoading) {
        _setJobsLoading(true);
      }
      clearJobsError();

      logger.debug('İş ilanları yükleniyor...');

      final response = await _employerService.fetchCurrentUserCompanyJobs();

      if (response.isTokenError) {
        _setJobsError('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
        return;
      }

      if (response.isSuccessful && response.data != null) {
        _jobsData = response.data;
        logger.debug('İş ilanları başarıyla yüklendi: ${response.data!.jobCount} ilan');
      } else {
        final errorMsg = response.displayMessage ?? 'İş ilanları yüklenemedi';
        _setJobsError(errorMsg);
        _jobsData = null;
      }

    } catch (e) {
      logger.error('İş ilanları yükleme hatası: $e');
      _setJobsError('İş ilanları yüklenirken hata oluştu');
      _jobsData = null;
    } finally {
      if (showLoading) {
        _setJobsLoading(false);
      }
    }
  }

  /// İş ilanlarını yeniler
  Future<void> refreshJobs() async {
    _setRefreshing(true);
    clearJobsError();
    
    try {
      final response = await _employerService.fetchCurrentUserCompanyJobs(useCache: false);

      if (response.isTokenError) {
        _setJobsError('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
        return;
      }

      if (response.isSuccessful && response.data != null) {
        _jobsData = response.data;
        logger.debug('İş ilanları başarıyla yenilendi: ${response.data!.jobCount} ilan');
      } else {
        final errorMsg = response.displayMessage ?? 'İş ilanları yenilenemedi';
        _setJobsError(errorMsg);
      }

    } catch (e) {
      logger.error('İş ilanları yenileme hatası: $e');
      _setJobsError('İş ilanları yenilenirken hata oluştu');
    } finally {
      _setRefreshing(false);
    }
  }

  /// Başvuruları yükler
  Future<void> loadApplications({int? jobId, bool showLoading = true}) async {
    try {
      if (showLoading) {
        _setApplicationsLoading(true);
      }
      clearApplicationsError();

      logger.debug('Başvurular yükleniyor...');

      final response = await _employerService.fetchCurrentUserCompanyApplications(jobId: jobId);

      if (response.isTokenError) {
        _setApplicationsError('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
        return;
      }

      if (response.isSuccessful && response.data != null) {
        _applicationsData = response.data;
        logger.debug('Başvurular başarıyla yüklendi: ${response.data!.applicationCount} başvuru');
      } else {
        final errorMsg = response.displayMessage ?? 'Başvurular yüklenemedi';
        _setApplicationsError(errorMsg);
        _applicationsData = null;
      }

    } catch (e) {
      logger.error('Başvurular yükleme hatası: $e');
      _setApplicationsError('Başvurular yüklenirken hata oluştu');
      _applicationsData = null;
    } finally {
      if (showLoading) {
        _setApplicationsLoading(false);
      }
    }
  }

  /// Başvuruları yeniler
  Future<void> refreshApplications({int? jobId}) async {
    _setRefreshing(true);
    clearApplicationsError();
    
    try {
      final response = await _employerService.fetchCurrentUserCompanyApplications(jobId: jobId, useCache: false);

      if (response.isTokenError) {
        _setApplicationsError('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
        return;
      }

      if (response.isSuccessful && response.data != null) {
        _applicationsData = response.data;
        logger.debug('Başvurular başarıyla yenilendi: ${response.data!.applicationCount} başvuru');
      } else {
        final errorMsg = response.displayMessage ?? 'Başvurular yenilenemedi';
        _setApplicationsError(errorMsg);
      }

    } catch (e) {
      logger.error('Başvurular yenileme hatası: $e');
      _setApplicationsError('Başvurular yenilenirken hata oluştu');
    } finally {
      _setRefreshing(false);
    }
  }

  /// Favori adayları yükler
  Future<void> loadFavoriteApplicants({bool showLoading = true}) async {
    try {
      if (showLoading) {
        _setFavoriteApplicantsLoading(true);
      }
      clearFavoriteApplicantsError();

      logger.debug('Favori adaylar yükleniyor...');

      final response = await _employerService.fetchCurrentUserCompanyFavoriteApplicants();

      if (response.isTokenError) {
        _setFavoriteApplicantsError('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
        return;
      }

      if (response.isSuccessful && response.data != null) {
        _favoriteApplicantsData = response.data;
        logger.debug('Favori adaylar başarıyla yüklendi: ${response.data!.favoriteCount} aday');
      } else {
        final errorMsg = response.displayMessage ?? 'Favori adaylar yüklenemedi';
        _setFavoriteApplicantsError(errorMsg);
        _favoriteApplicantsData = null;
      }

    } catch (e) {
      logger.error('Favori adaylar yükleme hatası: $e');
      _setFavoriteApplicantsError('Favori adaylar yüklenirken hata oluştu');
      _favoriteApplicantsData = null;
    } finally {
      if (showLoading) {
        _setFavoriteApplicantsLoading(false);
      }
    }
  }

  /// Favori adayları yeniler
  Future<void> refreshFavoriteApplicants() async {
    _setRefreshing(true);
    clearFavoriteApplicantsError();
    
    try {
      final response = await _employerService.fetchCurrentUserCompanyFavoriteApplicants(useCache: false);

      if (response.isTokenError) {
        _setFavoriteApplicantsError('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
        return;
      }

      if (response.isSuccessful && response.data != null) {
        _favoriteApplicantsData = response.data;
        logger.debug('Favori adaylar başarıyla yenilendi: ${response.data!.favoriteCount} aday');
      } else {
        final errorMsg = response.displayMessage ?? 'Favori adaylar yenilenemedi';
        _setFavoriteApplicantsError(errorMsg);
      }

    } catch (e) {
      logger.error('Favori adaylar yenileme hatası: $e');
      _setFavoriteApplicantsError('Favori adaylar yenilenirken hata oluştu');
    } finally {
      _setRefreshing(false);
    }
  }

  /// Favori aday ekler veya çıkarır
  Future<bool> toggleFavoriteApplicant(int jobId, int applicantId) async {
    try {
      logger.debug('Favori aday durumu değiştiriliyor', 
                   extra: {'jobId': jobId, 'applicantId': applicantId});
      
      final response = await _employerService.toggleFavoriteApplicant(jobId, applicantId);

      if (response.isTokenError) {
        _setError('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
        return false;
      }

      if (response.isSuccessful) {
        logger.debug('Favori aday durumu başarıyla değiştirildi', 
                     extra: {'jobId': jobId, 'applicantId': applicantId});
        return true;
      } else {
        final errorMsg = response.displayMessage ?? 'Favori aday durumu değiştirilemedi';
        _setError(errorMsg);
        return false;
      }

    } catch (e) {
      logger.error('Favori aday durumu değiştirme hatası: $e');
      _setError('Favori aday durumu değiştirilirken hata oluştu');
      return false;
    }
  }

  /// Başvuru detayını getirir ve günceller
  Future<ApplicationDetailModel?> getApplicationDetailUpdate(
    int companyId, 
    int appId, {
    int? newStatus,
  }) async {
    try {
      logger.debug('Başvuru detayı getiriliyor/güncelleniyor', 
                   extra: {'companyId': companyId, 'appId': appId, 'newStatus': newStatus});
      
      final response = await _employerService.getApplicationDetailUpdate(
        companyId, 
        appId, 
        newStatus: newStatus,
      );

      if (response.isTokenError) {
        _setError('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
        return null;
      }

      if (response.isSuccessful && response.data != null) {
        logger.debug('Başvuru detayı başarıyla getirildi/güncellendi', 
                     extra: {'companyId': companyId, 'appId': appId});
        return response.data;
      } else {
        final errorMsg = response.displayMessage ?? 'Başvuru detayı alınamadı';
        _setError(errorMsg);
        return null;
      }

    } catch (e) {
      logger.error('Başvuru detayı getirme/güncelleme hatası: $e');
      _setError('Başvuru detayı alınırken hata oluştu');
      return null;
    }
  }

  /// Başvuru durumunu günceller
  Future<bool> updateApplicationStatus(int appId, int newStatus) async {
    try {
      logger.debug('Başvuru durumu güncelleniyor', 
                   extra: {'appId': appId, 'newStatus': newStatus});
      
      // Mevcut kullanıcının şirket ID'sini al
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString == null) {
        _setError('Kullanıcı bilgileri bulunamadı');
        return false;
      }

      final userData = jsonDecode(userDataString);
      final user = UserModel.fromJson(userData);
      
      if (!user.isComp) {
        _setError('Sadece şirket hesapları başvuru durumu güncelleyebilir');
        return false;
      }

      final response = await _employerService.getApplicationDetailUpdate(
        user.userID, 
        appId, 
        newStatus: newStatus,
      );

      if (response.isTokenError) {
        _setError('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
        return false;
      }

      if (response.isSuccessful) {
        logger.debug('Başvuru durumu başarıyla güncellendi', 
                     extra: {'appId': appId, 'newStatus': newStatus});
        return true;
      } else {
        final errorMsg = response.displayMessage ?? 'Başvuru durumu güncellenemedi';
        _setError(errorMsg);
        return false;
      }

    } catch (e) {
      logger.error('Başvuru durumu güncelleme hatası: $e');
      _setError('Başvuru durumu güncellenirken hata oluştu');
      return false;
    }
  }

  /// Başvuru detayını getirir (sadece görüntüleme)
  Future<ApplicationDetailModel?> getApplicationDetail(int appId) async {
    try {
      logger.debug('Başvuru detayı getiriliyor', extra: {'appId': appId});
      
      // Mevcut kullanıcının şirket ID'sini al
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString == null) {
        _setError('Kullanıcı bilgileri bulunamadı');
        return null;
      }

      final userData = jsonDecode(userDataString);
      final user = UserModel.fromJson(userData);
      
      if (!user.isComp) {
        _setError('Sadece şirket hesapları başvuru detayı görüntüleyebilir');
        return null;
      }

      final response = await _employerService.getApplicationDetailUpdate(
        user.userID, 
        appId,
      );

      if (response.isTokenError) {
        _setError('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
        return null;
      }

      if (response.isSuccessful && response.data != null) {
        logger.debug('Başvuru detayı başarıyla getirildi', extra: {'appId': appId});
        return response.data;
      } else {
        final errorMsg = response.displayMessage ?? 'Başvuru detayı alınamadı';
        _setError(errorMsg);
        return null;
      }

    } catch (e) {
      logger.error('Başvuru detayı getirme hatası: $e');
      _setError('Başvuru detayı alınırken hata oluştu');
      return null;
    }
  }

  /// Belirli bir iş ilanını bulur
  EmployerJobModel? findJobById(int jobId) {
    return _jobsData?.jobs.firstWhere(
      (job) => job.jobID == jobId,
      orElse: () => throw StateError('Job not found'),
    );
  }

  /// Belirli bir başvuruyu bulur
  EmployerApplicationModel? findApplicationById(int appId) {
    return _applicationsData?.applications.firstWhere(
      (app) => app.appID == appId,
      orElse: () => throw StateError('Application not found'),
    );
  }

  /// Belirli bir favori adayı bulur
  EmployerFavoriteApplicantModel? findFavoriteApplicantById(int favId) {
    return _favoriteApplicantsData?.favorites.firstWhere(
      (fav) => fav.favID == favId,
      orElse: () => throw StateError('Favorite applicant not found'),
    );
  }

  /// İş ilanlarını filtreler
  List<EmployerJobModel> filterJobsByStatus(String status) {
    if (_jobsData == null) return [];
    return _jobsData!.jobs.where((job) => job.isActive.toString().toLowerCase().contains(status.toLowerCase())).toList();
  }

  /// Başvuruları filtreler
  List<EmployerApplicationModel> filterApplicationsByStatus(String status) {
    if (_applicationsData == null) return [];
    return _applicationsData!.applications.where((app) => app.statusName.toLowerCase().contains(status.toLowerCase())).toList();
  }

  /// Favori adayları filtreler
  List<EmployerFavoriteApplicantModel> filterFavoriteApplicantsByJob(int jobId) {
    if (_favoriteApplicantsData == null) return [];
    return _favoriteApplicantsData!.favorites.where((fav) => fav.jobID == jobId).toList();
  }

  /// State'i temizler
  void clearData() {
    _jobsData = null;
    _applicationsData = null;
    _favoriteApplicantsData = null;
    _errorMessage = null;
    _jobsErrorMessage = null;
    _applicationsErrorMessage = null;
    _favoriteApplicantsErrorMessage = null;
    _isLoading = false;
    _isRefreshing = false;
    _isJobsLoading = false;
    _isApplicationsLoading = false;
    _isFavoriteApplicantsLoading = false;
    notifyListeners();
  }

  /// Cache'i temizler
  void clearCache() {
    _employerService.clearAllCache();
    logger.debug('Employer cache temizlendi');
  }
} 