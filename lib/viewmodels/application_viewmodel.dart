import 'package:flutter/foundation.dart';
import '../models/application_models.dart';
import '../services/application_service.dart';
import '../services/logger_service.dart';

/// İş başvuruları ile ilgili state management
class ApplicationViewModel extends ChangeNotifier {
  final ApplicationService _applicationService = ApplicationService();

  // State değişkenleri
  List<ApplicationModel> _applications = [];
  bool _isLoading = false;
  String _errorMessage = '';
  bool _hasError = false;
  DateTime? _lastUpdateTime;
  bool _isRefreshing = false;

  // Getters
  List<ApplicationModel> get applications => _applications;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _hasError;
  bool get hasApplications => _applications.isNotEmpty;
  DateTime? get lastUpdateTime => _lastUpdateTime;
  bool get isRefreshing => _isRefreshing;

  /// Başvuru sayısını döndürür
  int get applicationCount => _applications.length;

  /// Durum bazlı başvuru sayılarını döndürür
  Map<String, int> get statusCounts {
    final Map<String, int> counts = {};
    for (final app in _applications) {
      counts[app.statusName] = (counts[app.statusName] ?? 0) + 1;
    }
    return counts;
  }

  /// En son başvuru tarihini döndürür
  String? get lastApplicationDate {
    if (_applications.isEmpty) return null;
    
    // En son başvuru tarihini bul
    final sortedApps = List<ApplicationModel>.from(_applications);
    sortedApps.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
    
    return sortedApps.first.appliedAt;
  }

  /// Kullanıcının başvurularını yükler
  Future<void> loadApplications({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    try {
      _setLoading(true);
      _clearError();

      logger.debug('Başvurular yükleniyor...');

      final response = await _applicationService.fetchUserApplications();
      
      if (response.isTokenError) {
        _setError('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
        return;
      }

      if (response.isSuccessful && response.hasApplications) {
        _applications = response.data!.applications;
        _lastUpdateTime = DateTime.now();
        
        logger.debug('${_applications.length} başvuru yüklendi');
        notifyListeners();
      } else {
        final errorMsg = response.displayMessage ?? 'Başvurular yüklenirken bir hata oluştu';
        _setError(errorMsg);
      }

    } catch (e) {
      logger.error('Başvurular yükleme hatası: $e');
      _setError('Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.');
    } finally {
      _setLoading(false);
    }
  }

  /// Başvuruları yeniler (pull to refresh)
  Future<void> refreshApplications() async {
    if (_isRefreshing) return;

    try {
      _isRefreshing = true;
      notifyListeners();

      logger.debug('Başvurular yenileniyor...');

      final response = await _applicationService.fetchUserApplications();
      
      if (response.isTokenError) {
        _setError('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
        return;
      }

      if (response.isSuccessful && response.hasApplications) {
        _applications = response.data!.applications;
        _lastUpdateTime = DateTime.now();
        _clearError();
        
        logger.debug('${_applications.length} başvuru yenilendi');
      } else {
        final errorMsg = response.displayMessage ?? 'Başvurular yenilenirken bir hata oluştu';
        _setError(errorMsg);
      }

    } catch (e) {
      logger.error('Başvurular yenileme hatası: $e');
      _setError('Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// ID'ye göre başvuru bulur
  ApplicationModel? getApplicationById(int appId) {
    try {
      return _applications.firstWhere((app) => app.appID == appId);
    } catch (e) {
      return null;
    }
  }

  /// Belirli bir işe ait başvuru bulur
  ApplicationModel? getApplicationByJobId(int jobId) {
    try {
      return _applications.firstWhere((app) => app.jobID == jobId);
    } catch (e) {
      return null;
    }
  }

  /// Belirli durumda olan başvuruları filtreler
  List<ApplicationModel> getApplicationsByStatus(String status) {
    return _applications.where((app) => app.statusName == status).toList();
  }

  /// Başvuruları tarihe göre sıralar (en yeni önce)
  List<ApplicationModel> getApplicationsSortedByDate() {
    final sortedApps = List<ApplicationModel>.from(_applications);
    sortedApps.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
    return sortedApps;
  }

  /// Başvuruları duruma göre sıralar
  List<ApplicationModel> getApplicationsSortedByStatus() {
    final sortedApps = List<ApplicationModel>.from(_applications);
    sortedApps.sort((a, b) => a.statusName.compareTo(b.statusName));
    return sortedApps;
  }

  /// Arama metni ile başvuruları filtreler
  List<ApplicationModel> searchApplications(String query) {
    if (query.isEmpty) return _applications;
    
    final lowerQuery = query.toLowerCase();
    return _applications.where((app) {
      return app.jobTitle.toLowerCase().contains(lowerQuery) ||
             app.jobDesc.toLowerCase().contains(lowerQuery) ||
             app.statusName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Loading state'i ayarlar
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Error state'i ayarlar
  void _setError(String message) {
    _errorMessage = message;
    _hasError = true;
    notifyListeners();
  }

  /// Error state'i temizler
  void _clearError() {
    _errorMessage = '';
    _hasError = false;
    notifyListeners();
  }

  /// ViewModel'i sıfırlar
  void reset() {
    _applications = [];
    _isLoading = false;
    _errorMessage = '';
    _hasError = false;
    _lastUpdateTime = null;
    _isRefreshing = false;
    notifyListeners();
  }

  /// Bellek temizleme
  @override
  void dispose() {
    reset();
    super.dispose();
  }
} 