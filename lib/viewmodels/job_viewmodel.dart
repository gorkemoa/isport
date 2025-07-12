import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/job_models.dart';
import '../services/job_service.dart';
import '../services/logger_service.dart';

/// İş ilanları state management'ı
class JobViewModel extends ChangeNotifier {
  final JobService _jobService = JobService();

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

  // Public getters
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  List<JobListingData> get jobListings => _jobListings;
  JobListingData? get selectedCompanyJobs => _selectedCompanyJobs;
  bool get hasJobs => _jobListings.isNotEmpty;
  int get totalJobCount => _jobListings.fold(0, (sum, data) => sum + data.jobs.length);
  
  // Job detail getters
  bool get isJobDetailLoading => _isJobDetailLoading;
  JobDetailData? get currentJobDetail => _currentJobDetail;
  bool get hasJobDetailError => _jobDetailErrorMessage != null;
  String? get jobDetailErrorMessage => _jobDetailErrorMessage;

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
  Future<bool> applyToJob(int jobId) async {
    try {
      logger.debug('İşe başvuru yapılıyor - ViewModel - İş ID: $jobId');
      final response = await _jobService.applyToJob(jobId);

      if (response.success) {
        logger.debug('İşe başvuru başarılı');
        // State'i güncelle
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
        _setJobDetailError(response.displayMessage ?? 'Başvuru sırasında bir hata oluştu.');
        return false;
      }
    } catch (e) {
      logger.error('İşe başvuru hatası - ViewModel: $e');
      _setJobDetailError('Başvuru sırasında beklenmedik bir hata oluştu.');
      return false;
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

  /// Tüm iş ilanlarını yükler
  Future<void> loadAllJobs({bool showLoading = true}) async {
    try {
      if (showLoading) {
        _setLoading(true);
      }
      _setError(null);

      logger.debug('Tüm iş ilanları yükleniyor...');

      final responses = await _jobService.fetchAllJobs();
      final List<JobListingData> newJobListings = [];

      for (final response in responses) {
        if (response.isSuccessful && response.data != null) {
          newJobListings.add(response.data!);
        } else if (response.displayMessage != null) {
          logger.warning('İş ilanı yükleme uyarısı: ${response.displayMessage}');
        }
      }

      _jobListings = newJobListings;
      logger.debug('${_jobListings.length} şirketin iş ilanları yüklendi');

      if (_jobListings.isEmpty) {
        _setError('Henüz iş ilanı bulunmuyor');
      }

    } catch (e) {
      logger.error('İş ilanları yükleme hatası: $e');
      _setError('İş ilanları yüklenirken hata oluştu: $e');
    } finally {
      if (showLoading) {
        _setLoading(false);
      }
    }
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

  /// State'i temizler
  void clearData() {
    _jobListings.clear();
    _selectedCompanyJobs = null;
    _selectedCompanyId = null;
    _errorMessage = null;
    _isLoading = false;
    _isRefreshing = false;
    clearJobDetailCache();
    notifyListeners();
  }
} 