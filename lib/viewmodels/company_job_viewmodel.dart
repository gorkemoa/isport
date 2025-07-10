import 'package:flutter/foundation.dart';
import '../models/company_job_models.dart';
import '../services/job_service.dart';
import '../services/logger_service.dart';

enum CompanyJobStatus { initial, loading, loaded, error, empty }

/// Şirket iş ilanları ViewModel
class CompanyJobViewModel extends ChangeNotifier {
  final JobService _jobService = JobService();

  // Private durumlar
  CompanyJobStatus _status = CompanyJobStatus.initial;
  List<CompanyJob> _jobs = [];
  String? _errorMessage;
  bool _isLoading = false;
  int? _companyId;

  // Public getter'lar
  CompanyJobStatus get status => _status;
  List<CompanyJob> get jobs => _jobs;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get hasJobs => _jobs.isNotEmpty;

  // Filtreleme
  List<CompanyJob> get activeJobs => _jobs.where((job) => job.isActive).toList();
  List<CompanyJob> get inactiveJobs => _jobs.where((job) => !job.isActive).toList();
  List<CompanyJob> get highlightedJobs => _jobs.where((job) => job.isHighlighted).toList();

  // İstatistikler
  int get totalJobsCount => _jobs.length;
  int get activeJobsCount => activeJobs.length;
  int get inactiveJobsCount => inactiveJobs.length;
  int get highlightedJobsCount => highlightedJobs.length;

  /// Company ID'sini ayarla
  void setCompanyId(int companyId) {
    _companyId = companyId;
  }

  /// Şirket iş ilanlarını getir
  Future<void> fetchCompanyJobs({String? userToken, bool isRefresh = false}) async {
    if (_companyId == null) {
      logger.e('Company ID not set');
      _setError('Şirket ID\'si belirtilmedi');
      return;
    }

    if (isRefresh) {
      _jobs.clear();
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _jobService.getCompanyJobs(
        companyId: _companyId!,
        userToken: userToken,
      );

      if (response.success && response.data != null) {
        _jobs = response.data!.jobs;
        
        if (_jobs.isEmpty) {
          _setStatus(CompanyJobStatus.empty);
        } else {
          _setStatus(CompanyJobStatus.loaded);
        }
      } else {
        _setError(response.message410 ?? 'İlanlar getirilemedi');
        _setStatus(CompanyJobStatus.error);
      }
    } catch (e) {
      logger.e('Company jobs fetch error: $e');
      _setError('İlanlar getirilirken hata oluştu: $e');
      _setStatus(CompanyJobStatus.error);
    }

    _setLoading(false);
  }

  /// İlan durumuna göre filtrele
  List<CompanyJob> getJobsByStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return activeJobs;
      case 'inactive':
      case 'pending':
        return inactiveJobs;
      case 'highlighted':
        return highlightedJobs;
      default:
        return _jobs;
    }
  }

  /// İlan kategorisine göre filtrele
  List<CompanyJob> getJobsByCategory(String category) {
    return _jobs.where((job) => job.catName.toLowerCase().contains(category.toLowerCase())).toList();
  }

  /// İlan arama
  List<CompanyJob> searchJobs(String query) {
    if (query.isEmpty) return _jobs;
    
    final lowercaseQuery = query.toLowerCase();
    return _jobs.where((job) {
      return job.jobTitle.toLowerCase().contains(lowercaseQuery) ||
             job.jobDesc.toLowerCase().contains(lowercaseQuery) ||
             job.catName.toLowerCase().contains(lowercaseQuery) ||
             job.cityName.toLowerCase().contains(lowercaseQuery) ||
             job.districtName.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// İlan ID'sine göre ilan bul
  CompanyJob? findJobById(int jobId) {
    try {
      return _jobs.firstWhere((job) => job.jobID == jobId);
    } catch (e) {
      return null;
    }
  }

  /// İlan sil (local olarak)
  void removeJob(int jobId) {
    _jobs.removeWhere((job) => job.jobID == jobId);
    
    if (_jobs.isEmpty) {
      _setStatus(CompanyJobStatus.empty);
    }
    
    notifyListeners();
  }

  /// İlan ekle (local olarak)
  void addJob(CompanyJob job) {
    _jobs.insert(0, job); // En başa ekle
    
    if (_status == CompanyJobStatus.empty) {
      _setStatus(CompanyJobStatus.loaded);
    }
    
    notifyListeners();
  }

  /// İlan güncelle (local olarak)
  void updateJob(CompanyJob updatedJob) {
    final index = _jobs.indexWhere((job) => job.jobID == updatedJob.jobID);
    if (index != -1) {
      _jobs[index] = updatedJob;
      notifyListeners();
    }
  }

  /// İlan durumunu değiştir (local olarak)
  void toggleJobStatus(int jobId) {
    final index = _jobs.indexWhere((job) => job.jobID == jobId);
    if (index != -1) {
      final job = _jobs[index];
      final updatedJob = CompanyJob(
        jobID: job.jobID,
        jobTitle: job.jobTitle,
        jobDesc: job.jobDesc,
        catName: job.catName,
        cityName: job.cityName,
        districtName: job.districtName,
        salaryMin: job.salaryMin,
        salaryMax: job.salaryMax,
        salaryType: job.salaryType,
        workType: job.workType,
        isHighlighted: job.isHighlighted,
        isActive: !job.isActive, // Durumu tersine çevir
        showDate: job.showDate,
        createDate: job.createDate,
        benefits: job.benefits,
      );
      _jobs[index] = updatedJob;
      notifyListeners();
    }
  }

  /// Verileri temizle
  void clearData() {
    _jobs.clear();
    _setStatus(CompanyJobStatus.initial);
    _clearError();
    notifyListeners();
  }

  // Private helper metodlar
  void _setStatus(CompanyJobStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setStatus(CompanyJobStatus.error);
  }

  void _clearError() {
    _errorMessage = null;
  }
} 