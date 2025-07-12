import 'package:flutter/foundation.dart';
import '../models/favorites_models.dart';
import '../services/favorites_service.dart';
import '../services/logger_service.dart';

/// Favori iş ilanları state management'ı
class FavoritesViewModel extends ChangeNotifier {
  final FavoritesService _favoritesService = FavoritesService();

  // Private state variables
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isToggling = false;
  FavoritesData? _favoritesData;
  String? _errorMessage;
  FavoritesFilter _currentFilter = FavoritesFilter.empty();
  final Map<int, bool> _toggleProcessing = {};

  // Public getters
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isToggling => _isToggling;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  FavoritesData? get favoritesData => _favoritesData;
  FavoritesFilter get currentFilter => _currentFilter;
  bool get hasFavorites => _favoritesData?.hasFavorites ?? false;
  int get favoriteCount => _favoritesData?.favoriteCount ?? 0;
  List<FavoriteJobModel> get favorites => _favoritesData?.favorites ?? [];
  bool get hasActiveFilters => _currentFilter.hasActiveFilters;

  /// Filtrelenmiş favorileri döner
  List<FavoriteJobModel> get filteredFavorites {
    if (_favoritesData == null) return [];
    return _currentFilter.applyFilter(_favoritesData!.favorites);
  }

  /// İş türlerine göre gruplama
  Map<String, List<FavoriteJobModel>> get favoritesByWorkType => _favoritesData?.favoritesByWorkType ?? {};

  /// Şirketlere göre gruplama
  Map<String, List<FavoriteJobModel>> get favoritesByCompany => _favoritesData?.favoritesByCompany ?? {};

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

  /// Toggling state'i günceller
  void _setToggling(bool toggling) {
    _isToggling = toggling;
    notifyListeners();
  }

  /// Error mesajını günceller
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Favorites data'yı günceller
  void _setFavoritesData(FavoritesData? favoritesData) {
    _favoritesData = favoritesData;
    notifyListeners();
  }

  /// Error'ı temizler
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Favori iş ilanlarını yükler
  Future<void> loadFavorites(int userId, {bool useCache = true, bool showLoading = true}) async {
    try {
      // Cache kontrolü
      if (useCache && _favoritesService.cachedFavoriteCount > 0) {
        logger.debug('Cache\'den favori iş ilanları yüklendi', extra: {'userId': userId});
        return;
      }

      if (showLoading) {
        _setLoading(true);
      }
      _setError(null);

      logger.info('Favori iş ilanları yükleniyor', extra: {'userId': userId, 'useCache': useCache});

      final response = await _favoritesService.fetchFavorites(userId, useCache: useCache);

      if (response.isSuccessful && response.data != null) {
        _setFavoritesData(response.data);
        logger.info('Favori iş ilanları başarıyla yüklendi', 
                   extra: {'userId': userId, 'favoriteCount': response.data!.favoriteCount});
      } else {
        final errorMsg = response.displayMessage ?? 'Favori iş ilanları yüklenemedi';
        _setError(errorMsg);
        _setFavoritesData(null);
        logger.warning('Favori iş ilanları yüklenemedi', 
                      extra: {'userId': userId, 'error': errorMsg});
      }

    } catch (e, stackTrace) {
      logger.error('Favori iş ilanları yükleme hatası', 
                   error: e, stackTrace: stackTrace, 
                   extra: {'userId': userId});
      _setError('Favori iş ilanları yüklenirken hata oluştu');
      _setFavoritesData(null);
    } finally {
      if (showLoading) {
        _setLoading(false);
      }
    }
  }

  /// Favori iş ilanlarını yeniler (pull-to-refresh)
  Future<void> refreshFavorites(int userId) async {
    _setRefreshing(true);
    await loadFavorites(userId, useCache: false, showLoading: false);
    _setRefreshing(false);
  }

  /// İş favorileme durumunu değiştirir
  Future<bool> toggleJobFavorite(int jobId) async {
    // Eğer bu iş için zaten işlem devam ediyorsa, işlemi reddet
    if (_toggleProcessing[jobId] == true) {
      logger.debug('İş favorileme işlemi zaten devam ediyor', extra: {'jobId': jobId});
      return false;
    }

    try {
      _toggleProcessing[jobId] = true;
      _setToggling(true);

      final currentlyFavorite = isJobFavorite(jobId);
      final newFavoriteStatus = !currentlyFavorite;

      logger.info('İş favorileme durumu değiştiriliyor', 
                  extra: {'jobId': jobId, 'newStatus': newFavoriteStatus});

      final success = await _favoritesService.toggleJobFavorite(jobId, newFavoriteStatus);

      if (success) {
        // UI'yi hemen güncelle (optimistic update)
        _updateFavoriteStatusInState(jobId, newFavoriteStatus);
        logger.info('İş favorileme durumu başarıyla güncellendi', 
                   extra: {'jobId': jobId, 'isFavorite': newFavoriteStatus});
        return true;
      } else {
        final errorMsg = 'Favorileme durumu güncellenemedi';
        _setError(errorMsg);
        logger.warning('İş favorileme hatası', 
                      extra: {'jobId': jobId, 'error': errorMsg});
        return false;
      }

    } catch (e, stackTrace) {
      logger.error('İş favorileme hatası', 
                   error: e, stackTrace: stackTrace, 
                   extra: {'jobId': jobId});
      _setError('Favorileme durumu güncellenirken hata oluştu');
      return false;
    } finally {
      _toggleProcessing[jobId] = false;
      _setToggling(false);
    }
  }

  /// State'deki favorileme durumunu günceller
  void _updateFavoriteStatusInState(int jobId, bool isFavorite) {
    if (_favoritesData == null) return;

    List<FavoriteJobModel> updatedFavorites = List.from(_favoritesData!.favorites);

    if (isFavorite) {
      // Favorilere ekleme - Bu durumda tam job bilgisi olmadığından yeniden yükle
      // Cache'i temizle ve güncelle
      _favoritesService.clearCache();
    } else {
      // Favorilerden çıkarma
      updatedFavorites.removeWhere((fav) => fav.jobID == jobId);
      _setFavoritesData(FavoritesData(favorites: updatedFavorites));
    }
  }

  /// Belirli bir işin favori olup olmadığını kontrol eder
  bool isJobFavorite(int jobId) {
    if (_favoritesData == null) return false;
    return _favoritesData!.favorites.any((fav) => fav.jobID == jobId);
  }

  /// Favorileme işleminin devam edip etmediğini kontrol eder
  bool isFavoriteProcessingForJob(int jobId) {
    return _toggleProcessing[jobId] ?? false;
  }

  /// Favori iş ilanlarında arama yapar
  List<FavoriteJobModel> searchFavorites(String query) {
    if (_favoritesData == null) return [];
    return _favoritesData!.searchFavorites(query);
  }

  /// Filtre uygular
  void applyFilter(FavoritesFilter filter) {
    _currentFilter = filter;
    logger.debug('Favori filtresi uygulandı', extra: {
      'workType': filter.workType,
      'companyName': filter.companyName,
      'showRecentOnly': filter.showRecentOnly,
      'sortBy': filter.sortBy,
    });
    notifyListeners();
  }

  /// Filtreyi temizler
  void clearFilter() {
    _currentFilter = FavoritesFilter.empty();
    logger.debug('Favori filtresi temizlendi');
    notifyListeners();
  }

  /// İş türüne göre filtreler
  void filterByWorkType(String workType) {
    _currentFilter = _currentFilter.copyWith(workType: workType);
    notifyListeners();
  }

  /// Şirkete göre filtreler
  void filterByCompany(String companyName) {
    _currentFilter = _currentFilter.copyWith(companyName: companyName);
    notifyListeners();
  }

  /// Sadece son zamanlarda eklenenler
  void filterByRecent(bool showRecentOnly) {
    _currentFilter = _currentFilter.copyWith(showRecentOnly: showRecentOnly);
    notifyListeners();
  }

  /// Sıralama değiştirir
  void changeSorting(String sortBy, {bool? ascending}) {
    _currentFilter = _currentFilter.copyWith(
      sortBy: sortBy,
      ascending: ascending ?? _currentFilter.ascending,
    );
    notifyListeners();
  }

  /// Belirli bir favoriyi ID'ye göre bulur
  FavoriteJobModel? getFavoriteById(int jobId) {
    if (_favoritesData == null) return null;
    try {
      return _favoritesData!.favorites.firstWhere((fav) => fav.jobID == jobId);
    } catch (e) {
      return null;
    }
  }

  /// Belirli bir şirketten favorileri getirir
  List<FavoriteJobModel> getFavoritesByCompany(String companyName) {
    if (_favoritesData == null) return [];
    return _favoritesData!.getFavoritesByCompany(companyName);
  }

  /// Belirli bir iş türünden favorileri getirir
  List<FavoriteJobModel> getFavoritesByWorkType(String workType) {
    if (_favoritesData == null) return [];
    return _favoritesData!.getFavoritesByWorkType(workType);
  }

  /// Son zamanlarda eklenen favorileri getirir
  List<FavoriteJobModel> getRecentFavorites() {
    if (_favoritesData == null) return [];
    return _favoritesData!.recentFavorites;
  }

  /// İstatistikleri döner
  Map<String, dynamic> getStats() {
    if (_favoritesData == null) {
      return {
        'totalFavorites': 0,
        'workTypeBreakdown': <String, int>{},
        'companyBreakdown': <String, int>{},
        'recentCount': 0,
      };
    }

    final workTypeBreakdown = <String, int>{};
    final companyBreakdown = <String, int>{};

    for (final favorite in _favoritesData!.favorites) {
      workTypeBreakdown[favorite.workType] = (workTypeBreakdown[favorite.workType] ?? 0) + 1;
      companyBreakdown[favorite.compName] = (companyBreakdown[favorite.compName] ?? 0) + 1;
    }

    return {
      'totalFavorites': _favoritesData!.favoriteCount,
      'workTypeBreakdown': workTypeBreakdown,
      'companyBreakdown': companyBreakdown,
      'recentCount': _favoritesData!.recentFavorites.length,
      'filteredCount': filteredFavorites.length,
    };
  }

  /// Cache istatistiklerini döner
  Map<String, dynamic> getCacheStats() {
    return _favoritesService.getCacheStats();
  }

  /// Cache'i temizler
  void clearCache() {
    _favoritesService.clearCache();
    logger.debug('Favoriler cache\'i temizlendi');
  }

  /// State'i temizler
  void clearData() {
    _favoritesData = null;
    _errorMessage = null;
    _isLoading = false;
    _isRefreshing = false;
    _isToggling = false;
    _currentFilter = FavoritesFilter.empty();
    _toggleProcessing.clear();
    clearCache();
    notifyListeners();
  }

  /// ViewModel'i temizler
  @override
  void dispose() {
    clearData();
    super.dispose();
  }
} 