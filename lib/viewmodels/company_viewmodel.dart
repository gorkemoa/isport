import 'package:flutter/foundation.dart';
import '../models/company_models.dart';
import '../services/company_service.dart';
import '../services/logger_service.dart';

/// Firma detayı state management'ı
class CompanyViewModel extends ChangeNotifier {
  final CompanyService _companyService = CompanyService();

  // Private state variables
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isFavoriteToggling = false;
  CompanyDetailData? _currentCompanyDetail;
  String? _errorMessage;
  final Map<int, CompanyDetailData> _companyCache = {};
  final Map<int, bool> _favoriteProcessing = {};

  // Public getters
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isFavoriteToggling => _isFavoriteToggling;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  CompanyDetailData? get currentCompanyDetail => _currentCompanyDetail;
  bool get hasCompanyData => _currentCompanyDetail != null;
  bool get hasCompanyJobs => _currentCompanyDetail?.hasJobs ?? false;
  int get companyJobCount => _currentCompanyDetail?.activeJobCount ?? 0;

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

  /// Favorite toggling state'i günceller
  void _setFavoriteToggling(bool toggling) {
    _isFavoriteToggling = toggling;
    notifyListeners();
  }

  /// Error mesajını günceller
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Company detail'i günceller
  void _setCompanyDetail(CompanyDetailData? companyDetail) {
    _currentCompanyDetail = companyDetail;
    notifyListeners();
  }

  /// Error'ı temizler
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Firma detayını yükler
  Future<void> loadCompanyDetail(int companyId, {bool useCache = true, bool showLoading = true}) async {
    try {
      // Cache kontrolü
      if (useCache && _companyCache.containsKey(companyId)) {
        _setCompanyDetail(_companyCache[companyId]);
        _setError(null);
        logger.debug('Firma detayı cache\'den yüklendi', extra: {'companyId': companyId});
        return;
      }

      if (showLoading) {
        _setLoading(true);
      }
      _setError(null);

      logger.info('Firma detayı yükleniyor', extra: {'companyId': companyId, 'useCache': useCache});

      final response = await _companyService.fetchCompanyDetail(companyId, useCache: useCache);

      if (response.isSuccessful && response.data != null) {
        _setCompanyDetail(response.data);
        _companyCache[companyId] = response.data!;
        logger.info('Firma detayı başarıyla yüklendi', 
                   extra: {'companyId': companyId, 'companyName': response.data!.company.compName});
      } else {
        final errorMsg = response.displayMessage ?? 'Firma detayı yüklenemedi';
        _setError(errorMsg);
        _setCompanyDetail(null);
        logger.warning('Firma detayı yüklenemedi', 
                      extra: {'companyId': companyId, 'error': errorMsg});
      }

    } catch (e, stackTrace) {
      logger.error('Firma detayı yükleme hatası', 
                   error: e, stackTrace: stackTrace, 
                   extra: {'companyId': companyId});
      _setError('Firma detayı yüklenirken hata oluştu');
      _setCompanyDetail(null);
    } finally {
      if (showLoading) {
        _setLoading(false);
      }
    }
  }

  /// Firma favorileme durumunu değiştirir
  Future<bool> toggleCompanyFavorite(int companyId) async {
    // Eğer bu firma için zaten işlem devam ediyorsa, işlemi reddet
    if (_favoriteProcessing[companyId] == true) {
      logger.debug('Firma favorileme işlemi zaten devam ediyor', extra: {'companyId': companyId});
      return false;
    }

    try {
      _favoriteProcessing[companyId] = true;
      _setFavoriteToggling(true);

      final currentFavoriteStatus = _currentCompanyDetail?.company.isFavorite ?? false;
      final newFavoriteStatus = !currentFavoriteStatus;

      logger.info('Firma favorileme durumu değiştiriliyor', 
                  extra: {'companyId': companyId, 'newStatus': newFavoriteStatus});

      final response = await _companyService.toggleCompanyFavorite(companyId, newFavoriteStatus);

      if (response.success) {
        // UI'yi hemen güncelle (optimistic update)
        _updateFavoriteStatusInState(companyId, newFavoriteStatus);
        logger.info('Firma favorileme durumu başarıyla güncellendi', 
                   extra: {'companyId': companyId, 'isFavorite': newFavoriteStatus});
        return true;
      } else {
        final errorMsg = response.displayMessage ?? 'Favorileme durumu güncellenemedi';
        _setError(errorMsg);
        logger.warning('Firma favorileme hatası', 
                      extra: {'companyId': companyId, 'error': errorMsg});
        return false;
      }

    } catch (e, stackTrace) {
      logger.error('Firma favorileme hatası', 
                   error: e, stackTrace: stackTrace, 
                   extra: {'companyId': companyId});
      _setError('Favorileme durumu güncellenirken hata oluştu');
      return false;
    } finally {
      _favoriteProcessing[companyId] = false;
      _setFavoriteToggling(false);
    }
  }

  /// State'deki favorileme durumunu günceller
  void _updateFavoriteStatusInState(int companyId, bool isFavorite) {
    // Mevcut company detail'i güncelle
    if (_currentCompanyDetail != null && _currentCompanyDetail!.company.compID == companyId) {
      final updatedCompany = CompanyDetailModel(
        compID: _currentCompanyDetail!.company.compID,
        compName: _currentCompanyDetail!.company.compName,
        compDesc: _currentCompanyDetail!.company.compDesc,
        compAddress: _currentCompanyDetail!.company.compAddress,
        compCity: _currentCompanyDetail!.company.compCity,
        compDistrict: _currentCompanyDetail!.company.compDistrict,
        compWebSite: _currentCompanyDetail!.company.compWebSite,
        compPersonNumber: _currentCompanyDetail!.company.compPersonNumber,
        compSectorID: _currentCompanyDetail!.company.compSectorID,
        compSector: _currentCompanyDetail!.company.compSector,
        profilePhoto: _currentCompanyDetail!.company.profilePhoto,
        isFavorite: isFavorite,
      );

      _setCompanyDetail(CompanyDetailData(
        company: updatedCompany,
        jobs: _currentCompanyDetail!.jobs,
      ));
    }

    // Cache'i güncelle
    if (_companyCache.containsKey(companyId)) {
      final cachedData = _companyCache[companyId]!;
      final updatedCompany = CompanyDetailModel(
        compID: cachedData.company.compID,
        compName: cachedData.company.compName,
        compDesc: cachedData.company.compDesc,
        compAddress: cachedData.company.compAddress,
        compCity: cachedData.company.compCity,
        compDistrict: cachedData.company.compDistrict,
        compWebSite: cachedData.company.compWebSite,
        compPersonNumber: cachedData.company.compPersonNumber,
        compSectorID: cachedData.company.compSectorID,
        compSector: cachedData.company.compSector,
        profilePhoto: cachedData.company.profilePhoto,
        isFavorite: isFavorite,
      );

      _companyCache[companyId] = CompanyDetailData(
        company: updatedCompany,
        jobs: cachedData.jobs,
      );
    }
  }

  /// Birden fazla firma detayını yükler
  Future<List<CompanyDetailData>> loadMultipleCompanyDetails(List<int> companyIds) async {
    try {
      _setLoading(true);
      _setError(null);

      logger.info('Birden fazla firma detayı yükleniyor', extra: {'companyCount': companyIds.length});

      final responses = await _companyService.fetchMultipleCompanyDetails(companyIds);
      final List<CompanyDetailData> companyDetails = [];

      for (final response in responses) {
        if (response.isSuccessful && response.data != null) {
          companyDetails.add(response.data!);
          _companyCache[response.data!.company.compID] = response.data!;
        }
      }

      logger.info('Birden fazla firma detayı yüklendi', 
                  extra: {'successCount': companyDetails.length, 'totalCount': companyIds.length});

      return companyDetails;

    } catch (e, stackTrace) {
      logger.error('Birden fazla firma detayı yükleme hatası', error: e, stackTrace: stackTrace);
      _setError('Firma detayları yüklenirken hata oluştu');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Firma detayını yeniler (pull-to-refresh)
  Future<void> refreshCompanyDetail(int companyId) async {
    _setRefreshing(true);
    await loadCompanyDetail(companyId, useCache: false, showLoading: false);
    _setRefreshing(false);
  }

  /// Belirli bir firma işini ID'ye göre bulur
  CompanyJobModel? findCompanyJobById(int jobId) {
    if (_currentCompanyDetail == null) return null;
    
    for (final job in _currentCompanyDetail!.jobs) {
      if (job.jobID == jobId) {
        return job;
      }
    }
    return null;
  }

  /// İş türüne göre firma işlerini filtreler
  List<CompanyJobModel> filterJobsByWorkType(String workType) {
    if (_currentCompanyDetail == null) return [];
    
    return _currentCompanyDetail!.jobs.where((job) => 
      job.workType.toLowerCase().contains(workType.toLowerCase())
    ).toList();
  }

  /// Cache'den firma detayını getirir
  CompanyDetailData? getCachedCompanyDetail(int companyId) {
    return _companyCache[companyId];
  }

  /// Cache'deki firma sayısını döner
  int get cachedCompanyCount => _companyCache.length;

  /// Belirli bir firma için cache'i temizler
  void clearCompanyCache(int companyId) {
    _companyCache.remove(companyId);
    _companyService.clearCompanyCache(companyId);
    logger.debug('Firma cache\'i temizlendi', extra: {'companyId': companyId});
  }

  /// Tüm cache'i temizler
  void clearAllCache() {
    _companyCache.clear();
    _companyService.clearCache();
    logger.debug('Tüm firma cache\'i temizlendi');
  }

  /// Cache istatistiklerini döner
  Map<String, dynamic> getCacheStats() {
    final serviceStats = _companyService.getCacheStats();
    return {
      'viewModelCacheSize': _companyCache.length,
      'serviceCacheSize': serviceStats['cacheSize'],
      'totalCacheCapacity': serviceStats['cacheCapacity'],
      'cacheExpirationMinutes': serviceStats['cacheExpirationMinutes'],
    };
  }

  /// Favorileme işleminin devam edip etmediğini kontrol eder
  bool isFavoriteProcessingForCompany(int companyId) {
    return _favoriteProcessing[companyId] ?? false;
  }

  /// State'i temizler
  void clearData() {
    _currentCompanyDetail = null;
    _errorMessage = null;
    _isLoading = false;
    _isRefreshing = false;
    _isFavoriteToggling = false;
    _favoriteProcessing.clear();
    clearAllCache();
    notifyListeners();
  }

  /// ViewModel'i temizler
  @override
  void dispose() {
    clearData();
    super.dispose();
  }
} 