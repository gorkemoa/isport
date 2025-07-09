import 'package:flutter/foundation.dart';
import '../models/job_models.dart';
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

  /// Hata durumunu ayarlar
  void _setError(String message) {
    _status = JobStatus.error;
    _errorMessage = message;
  }
} 