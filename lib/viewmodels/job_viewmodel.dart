import 'package:flutter/foundation.dart';
import 'package:isport/services/logger_service.dart';
import '../models/job_models.dart';
import '../services/auth_services.dart';
import '../services/job_service.dart';
import 'auth_viewmodels.dart';

enum JobStatus { initial, loading, loaded, loadingMore, error, empty }

class JobViewModel extends ChangeNotifier {
  final JobService _jobService = JobService();
  final AuthViewModel _authViewModel; // Auth durumunu bilmek için

  JobViewModel(this._authViewModel);

  // Durumlar
  JobStatus _status = JobStatus.initial;
  List<Job> _jobs = [];
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  bool _isApplying = false;
  bool get isApplying => _isApplying;

  // Getter'lar
  JobStatus get status => _status;
  List<Job> get jobs => _jobs;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  /// İş ilanlarını getirir veya yeniler
  Future<void> fetchJobs({bool isRefresh = false}) async {
    // Eğer zaten yükleniyorsa tekrar çağırma
    if (_status == JobStatus.loading || _status == JobStatus.loadingMore) return;

    if (isRefresh) {
      _currentPage = 1;
      _hasMore = true;
      _jobs = [];
      _status = JobStatus.loading;
    } else {
      if (_currentPage == 1) {
        _status = JobStatus.loading;
      } else {
        _status = JobStatus.loadingMore;
      }
    }
    notifyListeners();

    try {
      final token = await _authViewModel.getToken();
      
      final request = JobListRequest(
        page: _currentPage,
        userToken: token,
        // Diğer filtreleri buraya ekleyebilirsiniz
      );
      
      final response = await _jobService.getJobList(request);
      
      if (response.success && response.data != null) {
        if (response.data!.jobs.isEmpty && _currentPage == 1) {
          _status = JobStatus.empty;
          _jobs = [];
        } else {
          _jobs.addAll(response.data!.jobs);
          _totalPages = response.data!.totalPages;
          _hasMore = _currentPage < _totalPages;
          _status = JobStatus.loaded;
        }
      } else {
        _setError(response.message410 ?? 'İlanlar getirilemedi.');
      }
    } catch (e) {
      _setError('Bir hata oluştu: $e');
    }
    
    notifyListeners();
  }

  /// Daha fazla iş ilanı yükler
  Future<void> loadMoreJobs() async {
    if (_hasMore && _status != JobStatus.loadingMore && _status != JobStatus.loading) {
      _currentPage++;
      await fetchJobs();
    }
  }

  Future<bool> applyToJob({required int jobId, required String token}) async {
    _isApplying = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _jobService.applyToJob(
        ApplyJobRequest(userToken: token, jobID: jobId, appNote: ''),
      );
      if (response.success) {
        return true;
      } else {
        _errorMessage = response.successMessage ?? 'Başvuru yapılamadı.';
        return false;
      }
    } catch (e, s) {
      logger.e('Başvuru yapılırken hata oluştu', error: e, stackTrace: s);
      _errorMessage = e.toString();
      return false;
    } finally {
      _isApplying = false;
      notifyListeners();
    }
  }

  /// İlanın favori durumunu değiştirir
  Future<bool> toggleJobFavorite(int jobID) async {
    try {
      final token = await _authViewModel.getToken();
      if (token == null) {
        _setError('Giriş yapmanız gerekiyor.');
        return false;
      }

      // Önce local state'i güncelle (optimistic update)
      final jobIndex = _jobs.indexWhere((job) => job.jobID == jobID);
      if (jobIndex != -1) {
        final currentFavoriteStatus = _jobs[jobIndex].isFavorite;
        _jobs[jobIndex] = _jobs[jobIndex].copyWith(isFavorite: !currentFavoriteStatus);
        notifyListeners();

        // API çağrısını yap
        final response = currentFavoriteStatus
            ? await _jobService.removeJobFromFavorites(userToken: token, jobID: jobID)
            : await _jobService.addJobToFavorites(userToken: token, jobID: jobID);

        if (response.success) {
          return true;
        } else {
          // API başarısızsa değişikliği geri al
          _jobs[jobIndex] = _jobs[jobIndex].copyWith(isFavorite: currentFavoriteStatus);
          notifyListeners();
          _setError(response.message ?? 'Favori durumu güncellenemedi.');
          return false;
        }
      }
      return false;
    } catch (e) {
      _setError('Favori güncellenirken hata oluştu: $e');
      return false;
    }
  }

  /// Belirli bir ilanın favori durumunu döndürür
  bool isJobFavorite(int jobID) {
    final job = _jobs.firstWhere((job) => job.jobID == jobID, orElse: () => Job.empty());
    return job.isFavorite;
  }

  /// Hata durumunu ayarlar
  void _setError(String message) {
    _status = JobStatus.error;
    _errorMessage = message;
  }

  /// Hata mesajını temizler
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
} 