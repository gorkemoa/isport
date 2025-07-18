import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/job_models.dart';
import '../services/job_service.dart';
import '../services/favorites_service.dart';
import '../services/logger_service.dart';

/// İş ilanları state management'ı
class JobViewModel extends ChangeNotifier {
  final JobService _jobService = JobService();
  final FavoritesService _favoritesService = FavoritesService();

  // Private state variables
  bool _isLoading = false;
  bool _isRefreshing = false;
  List<JobListingData> _jobListings = [];
  String? _errorMessage;
  JobListingData? _selectedCompanyJobs;
  int? _selectedCompanyId;
  
  // Job detail state variables
  bool _isJobDetailLoading = false;
  JobDetailData? _currentJobDetail;
  String? _jobDetailErrorMessage;
  final Map<int, JobDetailData> _jobDetailCache = {};
  
  // Job apply state variables
  bool _isApplying = false;
  String? _applySuccessMessage;
  String? _applyErrorMessage;

  // Job favorite state variables
  bool _isTogglingFavorite = false;
  final Map<int, bool> _favoriteStates = {};
  final Map<int, bool> _favoriteToggleStates = {};
  String? _favoriteSuccessMessage;
  String? _favoriteErrorMessage;

  // Yeni API endpoint için state variables
  List<JobListItem> _jobListItems = [];
  JobListData? _jobListData;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;

  // Public getters
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  List<JobListingData> get jobListings => _jobListings;
  JobListingData? get selectedCompanyJobs => _selectedCompanyJobs;
  bool get hasJobs => _jobListings.isNotEmpty;
  int get totalJobCount => _jobListings.fold(0, (sum, data) => sum + data.jobs.length);
  
  // Yeni API endpoint için getters
  List<JobListItem> get jobListItems => _jobListItems;
  JobListData? get jobListData => _jobListData;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  bool get hasMorePages => _hasMorePages;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasJobListItems => _jobListItems.isNotEmpty;
  
  // Job detail getters
  bool get isJobDetailLoading => _isJobDetailLoading;
  JobDetailData? get currentJobDetail => _currentJobDetail;
  bool get hasJobDetailError => _jobDetailErrorMessage != null;
  String? get jobDetailErrorMessage => _jobDetailErrorMessage;
  
  // Job apply getters
  bool get isApplying => _isApplying;
  String? get applySuccessMessage => _applySuccessMessage;
  String? get applyErrorMessage => _applyErrorMessage;
  bool get hasApplyError => _applyErrorMessage != null;

  // Job favorite getters
  bool get isTogglingFavorite => _isTogglingFavorite;
  String? get favoriteSuccessMessage => _favoriteSuccessMessage;
  String? get favoriteErrorMessage => _favoriteErrorMessage;
  bool get hasFavoriteError => _favoriteErrorMessage != null;

  /// Belirli bir işin favori durumunu döner
  bool isJobFavorite(int jobId) {
    return _favoriteStates[jobId] ?? false;
  }

  /// Belirli bir işin favori durumu değiştiriliyor mu kontrol eder
  bool isJobFavoriteToggling(int jobId) {
    return _favoriteToggleStates[jobId] ?? false;
  }

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

  /// Job detail loading state'i günceller
  void _setJobDetailLoading(bool loading) {
    _isJobDetailLoading = loading;
    notifyListeners();
  }

  /// Job detail error mesajını günceller
  void _setJobDetailError(String? error) {
    _jobDetailErrorMessage = error;
    notifyListeners();
  }

  /// Job detail error'ı temizler
  void clearJobDetailError() {
    _jobDetailErrorMessage = null;
    notifyListeners();
  }

  /// Apply loading state'i günceller
  void _setApplying(bool applying) {
    _isApplying = applying;
    notifyListeners();
  }

  /// Apply success mesajını günceller
  void _setApplySuccess(String? message) {
    _applySuccessMessage = message;
    _applyErrorMessage = null;
    notifyListeners();
  }

  /// Apply error mesajını günceller
  void _setApplyError(String? error) {
    _applyErrorMessage = error;
    _applySuccessMessage = null;
    notifyListeners();
  }

  /// Apply mesajlarını temizler
  void clearApplyMessages() {
    _applySuccessMessage = null;
    _applyErrorMessage = null;
    notifyListeners();
  }

  /// İş detayını yükler
  Future<void> loadJobDetail(int jobId, {bool useCache = true}) async {
    try {
      // Cache kontrolü
      if (useCache && _jobDetailCache.containsKey(jobId)) {
        _currentJobDetail = _jobDetailCache[jobId];
        _setJobDetailError(null);
        notifyListeners();
        return;
      }

      _setJobDetailLoading(true);
      _setJobDetailError(null);

      logger.debug('İş detayı yükleniyor - ID: $jobId');

      final response = await _jobService.fetchJobDetail(jobId);

      // API'den gelen tüm yanıtı logla
      logger.info('API Yanıtı (Job ID: $jobId): ${jsonEncode(response.toJson())}');

      if (response.isSuccessful && response.data != null) {
        _currentJobDetail = response.data;
        _jobDetailCache[jobId] = response.data!;
        
        // Favori durumunu güncelle
        updateFavoriteStateFromJobDetail(jobId, response.data!.job.isFavorite);
        
        logger.debug('İş detayı başarıyla yüklendi: ${response.data!.job.jobTitle}');
      } else {
        final errorMsg = response.displayMessage ?? 'İş detayı yüklenemedi';
        _setJobDetailError(errorMsg);
        _currentJobDetail = null;
      }

    } catch (e) {
      logger.error('İş detayı yükleme hatası: $e');
      _setJobDetailError('İş detayı yüklenirken hata oluştu');
      _currentJobDetail = null;
    } finally {
      _setJobDetailLoading(false);
    }
  }

  /// Bir işe başvuru yapar
  /// [jobId] - İş ID'si
  /// [appNote] - Başvuru notu
  Future<bool> applyToJob(int jobId, String appNote) async {
    try {
      _setApplying(true);
      clearApplyMessages();
      
      logger.debug('İşe başvuru yapılıyor - ViewModel - İş ID: $jobId');
      final response = await _jobService.applyToJob(jobId, appNote);

      if (response.isSuccessful) {
        logger.debug('İşe başvuru başarılı');
        
        // Başarı mesajını göster
        _setApplySuccess(response.displaySuccessMessage);
        
        // State'i güncelle (optimistic update)
        if (_currentJobDetail != null && _currentJobDetail!.job.jobID == jobId) {
          _currentJobDetail!.job.isApplied = true;
          notifyListeners();
        }
        
        // Cache'i de güncelle
        if (_jobDetailCache.containsKey(jobId)) {
          _jobDetailCache[jobId]!.job.isApplied = true;
        }
        
        return true;
      } else {
        logger.warning('İşe başvuru başarısız: ${response.errorMessage}');
        _setApplyError(response.displayMessage ?? 'Başvuru sırasında bir hata oluştu.');
        return false;
      }
    } catch (e) {
      logger.error('İşe başvuru hatası - ViewModel: $e');
      _setApplyError('Başvuru sırasında beklenmedik bir hata oluştu.');
      return false;
    } finally {
      _setApplying(false);
    }
  }

  /// Cache'den iş detayını getirir
  JobDetailData? getCachedJobDetail(int jobId) {
    return _jobDetailCache[jobId];
  }

  /// Job detail cache'ini temizler
  void clearJobDetailCache() {
    _jobDetailCache.clear();
    _currentJobDetail = null;
    _jobDetailErrorMessage = null;
  }

  /// Yeni API endpoint ile tüm iş ilanlarını yükler
  Future<void> loadAllJobListings({
    int? catID,
    List<int>? workTypes,
    int? cityID,
    int? districtID,
    String? publishDate,
    String? sort,
    String? latitude,
    String? longitude,
    bool refresh = false,
    bool showLoading = true,
  }) async {
    try {
      if (refresh) {
        _setRefreshing(true);
        _currentPage = 1;
        _jobListItems.clear();
        _jobListData = null;
      } else if (showLoading) {
        _setLoading(true);
      }
      
      _setError(null);

      logger.debug('Tüm iş ilanları yükleniyor - Sayfa: $_currentPage');

      final response = await _jobService.fetchAllJobListings(
        catID: catID,
        workTypes: workTypes,
        cityID: cityID,
        districtID: districtID,
        publishDate: publishDate,
        sort: sort,
        latitude: latitude,
        longitude: longitude,
        page: _currentPage,
      );

      if (response.isSuccessful && response.data != null) {
        _jobListData = response.data;
        _totalPages = response.data!.totalPages;
        _totalItems = response.data!.totalItems;
        _hasMorePages = _currentPage < _totalPages;
        
        if (refresh) {
          _jobListItems = response.data!.jobs;
        } else {
          _jobListItems.addAll(response.data!.jobs);
        }
        
        // Favori durumlarını güncelle
        for (final job in response.data!.jobs) {
          _favoriteStates[job.jobID] = job.isFavorite;
        }
        
        logger.debug('İş ilanları başarıyla yüklendi: ${response.data!.jobs.length} ilan');
      } else {
        final errorMsg = response.displayMessage ?? 'İş ilanları yüklenemedi';
        _setError(errorMsg);
        
        if (refresh) {
          _jobListItems.clear();
          _jobListData = null;
        }
      }

    } catch (e) {
      logger.error('İş ilanları yükleme hatası: $e');
      _setError('İş ilanları yüklenirken hata oluştu');
      
      if (refresh) {
        _jobListItems.clear();
        _jobListData = null;
      }
    } finally {
      if (refresh) {
        _setRefreshing(false);
      } else if (showLoading) {
        _setLoading(false);
      }
    }
  }

  /// Daha fazla iş ilanı yükler (pagination)
  Future<void> loadMoreJobs({
    int? catID,
    List<int>? workTypes,
    int? cityID,
    int? districtID,
    String? publishDate,
    String? sort,
    String? latitude,
    String? longitude,
  }) async {
    if (_isLoadingMore || !_hasMorePages) return;

    try {
      _isLoadingMore = true;
      notifyListeners();

      _currentPage++;

      logger.debug('Daha fazla iş ilanı yükleniyor - Sayfa: $_currentPage');

      final response = await _jobService.fetchAllJobListings(
        catID: catID,
        workTypes: workTypes,
        cityID: cityID,
        districtID: districtID,
        publishDate: publishDate,
        sort: sort,
        latitude: latitude,
        longitude: longitude,
        page: _currentPage,
      );

      if (response.isSuccessful && response.data != null) {
        _jobListData = response.data;
        _totalPages = response.data!.totalPages;
        _totalItems = response.data!.totalItems;
        _hasMorePages = _currentPage < _totalPages;
        
        _jobListItems.addAll(response.data!.jobs);
        
        // Favori durumlarını güncelle
        for (final job in response.data!.jobs) {
          _favoriteStates[job.jobID] = job.isFavorite;
        }
        
        logger.debug('Daha fazla iş ilanı yüklendi: ${response.data!.jobs.length} ilan');
      } else {
        // Hata durumunda sayfa numarasını geri al
        _currentPage--;
        final errorMsg = response.displayMessage ?? 'Daha fazla ilan yüklenemedi';
        _setError(errorMsg);
      }

    } catch (e) {
      // Hata durumunda sayfa numarasını geri al
      _currentPage--;
      logger.error('Daha fazla iş ilanı yükleme hatası: $e');
      _setError('Daha fazla ilan yüklenirken hata oluştu');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// İş ilanlarını yeniler
  Future<void> refreshJobListings({
    int? catID,
    List<int>? workTypes,
    int? cityID,
    int? districtID,
    String? publishDate,
    String? sort,
    String? latitude,
    String? longitude,
  }) async {
    await loadAllJobListings(
      catID: catID,
      workTypes: workTypes,
      cityID: cityID,
      districtID: districtID,
      publishDate: publishDate,
      sort: sort,
      latitude: latitude,
      longitude: longitude,
      refresh: true,
    );
  }

  /// Tüm iş ilanlarını yükler (geriye uyumluluk için)
  Future<void> loadAllJobs({bool showLoading = true}) async {
    await loadAllJobListings(showLoading: showLoading);
  }

  /// Belirli bir şirketin iş ilanlarını yükler
  Future<void> loadCompanyJobs(int companyId, {bool showLoading = true}) async {
    try {
      if (showLoading) {
        _setLoading(true);
      }
      _setError(null);
      _selectedCompanyId = companyId;

      logger.debug('Şirket iş ilanları yükleniyor - ID: $companyId');

      final response = await _jobService.fetchCompanyJobs(companyId);

      if (response.isSuccessful && response.data != null) {
        _selectedCompanyJobs = response.data;
        logger.debug('Şirket iş ilanları başarıyla yüklendi: ${response.data!.jobs.length} ilan');
      } else {
        final errorMsg = response.displayMessage ?? 'Şirket iş ilanları yüklenemedi';
        _setError(errorMsg);
        _selectedCompanyJobs = null;
      }

    } catch (e) {
      logger.error('Şirket iş ilanları yükleme hatası: $e');
      _setError('Şirket iş ilanları yüklenirken hata oluştu');
      _selectedCompanyJobs = null;
    } finally {
      if (showLoading) {
        _setLoading(false);
      }
    }
  }

  /// Mevcut kullanıcının şirket iş ilanlarını yükler
  Future<void> loadCurrentUserCompanyJobs({bool showLoading = true}) async {
    try {
      if (showLoading) {
        _setLoading(true);
      }
      _setError(null);

      logger.debug('Mevcut kullanıcının şirket iş ilanları yükleniyor...');

      final response = await _jobService.fetchCurrentUserCompanyJobs();

      if (response.isSuccessful && response.data != null) {
        _selectedCompanyJobs = response.data;
        logger.debug('Kullanıcının şirket iş ilanları başarıyla yüklendi');
      } else {
        final errorMsg = response.displayMessage ?? 'Şirket iş ilanları yüklenemedi';
        _setError(errorMsg);
        _selectedCompanyJobs = null;
      }

    } catch (e) {
      logger.error('Kullanıcı şirket iş ilanları yükleme hatası: $e');
      _setError('Şirket iş ilanları yüklenirken hata oluştu');
      _selectedCompanyJobs = null;
    } finally {
      if (showLoading) {
        _setLoading(false);
      }
    }
  }

  /// İş ilanlarını yeniler (pull-to-refresh)
  Future<void> refreshJobs() async {
    _setRefreshing(true);
    _setError(null);
    
    try {
      if (_selectedCompanyId != null) {
        await loadCompanyJobs(_selectedCompanyId!, showLoading: false);
      } else {
        await loadAllJobs(showLoading: false);
      }
    } finally {
      _setRefreshing(false);
    }
  }

  /// Belirli bir işi ID'ye göre bulur
  JobModel? findJobById(int jobId) {
    for (final companyData in _jobListings) {
      for (final job in companyData.jobs) {
        if (job.jobID == jobId) {
          return job;
        }
      }
    }
    
    // Seçili şirket işlerinde de ara
    if (_selectedCompanyJobs != null) {
      for (final job in _selectedCompanyJobs!.jobs) {
        if (job.jobID == jobId) {
          return job;
        }
      }
    }
    
    return null;
  }

  /// Belirli bir şirketi ID'ye göre bulur
  CompanyDetailModel? findCompanyById(int companyId) {
    for (final companyData in _jobListings) {
      if (companyData.company.compID == companyId) {
        return companyData.company;
      }
    }
    
    if (_selectedCompanyJobs?.company.compID == companyId) {
      return _selectedCompanyJobs!.company;
    }
    
    return null;
  }

  /// İş türüne göre filtreler
  List<JobModel> filterJobsByWorkType(String workType) {
    final List<JobModel> filteredJobs = [];
    
    for (final companyData in _jobListings) {
      for (final job in companyData.jobs) {
        if (job.workType.toLowerCase().contains(workType.toLowerCase())) {
          filteredJobs.add(job);
        }
      }
    }
    
    return filteredJobs;
  }

  /// Şehire göre filtreler
  List<JobListingData> filterCompaniesByCity(String city) {
    return _jobListings.where((companyData) => 
      companyData.company.compCity.toLowerCase().contains(city.toLowerCase())
    ).toList();
  }

  /// Favori state'i güncellemek için metodlar
  void _setFavoriteTogglingState(bool toggling) {
    _isTogglingFavorite = toggling;
    notifyListeners();
  }

  /// Belirli bir işin favori toggle state'ini günceller
  void _setJobFavoriteToggling(int jobId, bool toggling) {
    _favoriteToggleStates[jobId] = toggling;
    notifyListeners();
  }

  /// Favori success mesajını günceller
  void _setFavoriteSuccess(String? message) {
    _favoriteSuccessMessage = message;
    _favoriteErrorMessage = null;
    notifyListeners();
  }

  /// Favori error mesajını günceller
  void _setFavoriteError(String? error) {
    _favoriteErrorMessage = error;
    _favoriteSuccessMessage = null;
    notifyListeners();
  }

  /// Favori mesajlarını temizler
  void clearFavoriteMessages() {
    _favoriteSuccessMessage = null;
    _favoriteErrorMessage = null;
    notifyListeners();
  }

  /// Belirli bir işin favori durumunu günceller
  void _updateJobFavoriteState(int jobId, bool isFavorite) {
    _favoriteStates[jobId] = isFavorite;
    
    // Job detail'deki favori durumunu da güncelle
    if (_currentJobDetail != null && _currentJobDetail!.job.jobID == jobId) {
      _currentJobDetail!.job.isFavorite = isFavorite;
    }
    
    // Cache'deki favori durumunu da güncelle
    if (_jobDetailCache.containsKey(jobId)) {
      _jobDetailCache[jobId]!.job.isFavorite = isFavorite;
    }
    
    notifyListeners();
  }

  /// İş ilanının favori durumunu toggle eder
  /// [jobId] - İş ID'si
  /// [currentFavoriteState] - Mevcut favori durumu
  Future<bool> toggleJobFavorite(int jobId, bool currentFavoriteState) async {
    try {
      _setJobFavoriteToggling(jobId, true);
      clearFavoriteMessages();
      
      final newFavoriteState = !currentFavoriteState;
      
      logger.debug('İş favorileme durumu değiştiriliyor - ID: $jobId, Yeni durum: $newFavoriteState');
      
      // Optimistic update
      _updateJobFavoriteState(jobId, newFavoriteState);
      
      // API çağrısı
      final success = await _favoritesService.toggleJobFavorite(jobId, newFavoriteState);
      
      if (success) {
        logger.debug('İş favorileme durumu başarıyla değiştirildi');
        final message = newFavoriteState ? 'İlan favorilere eklendi' : 'İlan favorilerden çıkarıldı';
        _setFavoriteSuccess(message);
        return true;
      } else {
        logger.warning('İş favorileme durumu değiştirilemedi');
        // Rollback optimistic update
        _updateJobFavoriteState(jobId, currentFavoriteState);
        _setFavoriteError('Favori durumu değiştirilemedi. Lütfen tekrar deneyin.');
        return false;
      }
    } catch (e) {
      logger.error('İş favorileme hatası - ViewModel: $e');
      // Rollback optimistic update
      _updateJobFavoriteState(jobId, currentFavoriteState);
      _setFavoriteError('Favori durumu değiştirilirken beklenmedik bir hata oluştu.');
      return false;
    } finally {
      _setJobFavoriteToggling(jobId, false);
    }
  }

  /// Bir işi favorilere ekler
  Future<bool> addJobToFavorites(int jobId) async {
    try {
      _setJobFavoriteToggling(jobId, true);
      clearFavoriteMessages();
      
      logger.debug('İş favorilere ekleniyor - ID: $jobId');
      
      final response = await _favoritesService.addJobToFavorites(jobId);
      
      if (response.isSuccessful) {
        logger.debug('İş başarıyla favorilere eklendi');
        _updateJobFavoriteState(jobId, true);
        _setFavoriteSuccess(response.displayMessage ?? 'İlan favorilere eklendi');
        return true;
      } else {
        logger.warning('İş favorilere eklenemedi: ${response.errorMessage}');
        _setFavoriteError(response.displayMessage ?? 'İlan favorilere eklenemedi');
        return false;
      }
    } catch (e) {
      logger.error('İş favorilere ekleme hatası - ViewModel: $e');
      _setFavoriteError('İlan favorilere eklenirken beklenmedik bir hata oluştu.');
      return false;
    } finally {
      _setJobFavoriteToggling(jobId, false);
    }
  }

  /// Bir işi favorilerden çıkarır
  Future<bool> removeJobFromFavorites(int jobId) async {
    try {
      _setJobFavoriteToggling(jobId, true);
      clearFavoriteMessages();
      
      logger.debug('İş favorilerden çıkarılıyor - ID: $jobId');
      
      final response = await _favoritesService.removeJobFromFavorites(jobId);
      
      if (response.isSuccessful) {
        logger.debug('İş başarıyla favorilerden çıkarıldı');
        _updateJobFavoriteState(jobId, false);
        _setFavoriteSuccess(response.displayMessage ?? 'İlan favorilerden çıkarıldı');
        return true;
      } else {
        logger.warning('İş favorilerden çıkarılamadı: ${response.errorMessage}');
        _setFavoriteError(response.displayMessage ?? 'İlan favorilerden çıkarılamadı');
        return false;
      }
    } catch (e) {
      logger.error('İş favorilerden çıkarma hatası - ViewModel: $e');
      _setFavoriteError('İlan favorilerden çıkarılırken beklenmedik bir hata oluştu.');
      return false;
    } finally {
      _setJobFavoriteToggling(jobId, false);
    }
  }

  /// Favori durumlarını job detail'dan günceller
  void updateFavoriteStateFromJobDetail(int jobId, bool isFavorite) {
    _favoriteStates[jobId] = isFavorite;
  }

  /// Favori state'lerini temizler
  void clearFavoriteStates() {
    _favoriteStates.clear();
    _favoriteToggleStates.clear();
    _favoriteSuccessMessage = null;
    _favoriteErrorMessage = null;
    notifyListeners();
  }

  /// State'i temizler
  void clearData() {
    _jobListings.clear();
    _selectedCompanyJobs = null;
    _selectedCompanyId = null;
    _errorMessage = null;
    _isLoading = false;
    _isRefreshing = false;
    clearJobDetailCache();
    clearFavoriteStates();
    notifyListeners();
  }
} 