import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorites_models.dart';
import '../models/auth_models.dart';
import 'auth_services.dart';
import 'logger_service.dart';

/// Favori iş ilanları ile ilgili API servis işlemleri
class FavoritesService {
  static const String _baseUrl = 'https://api.rivorya.com/isport';
  static const String _favoritesEndpoint = '/service/user/account';
  static const String _addFavoriteEndpoint = '/service/user/account/jobFavoriteAdd';
  static const String _removeFavoriteEndpoint = '/service/user/account/jobFavoriteRemove';

  /// Timeout süreleri
  static const Duration _connectTimeout = Duration(seconds: 10);
  static const Duration _receiveTimeout = Duration(seconds: 15);

  /// Cache yönetimi
  static FavoritesData? _cache;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheExpiration = Duration(minutes: 3);

  /// Favori iş ilanlarını getirir
  /// [userId] - Kullanıcı ID'si
  /// [useCache] - Cache kullanılsın mı (varsayılan: true)
  /// Returns FavoritesResponse with status code handling (410 = success, 417 = error)
  Future<FavoritesResponse> fetchFavorites(int userId, {bool useCache = true}) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.info('Favori iş ilanları getiriliyor', extra: {'userId': userId, 'useCache': useCache});
      
      // Cache kontrolü
      if (useCache && _isCacheValid()) {
        logger.debug('Cache\'den favori iş ilanları döndürülüyor', extra: {'userId': userId});
        return FavoritesResponse(
          error: false,
          success: true,
          data: _cache!,
          status410: 'Gone',
          errorMessage: '',
        );
      }

      // Kullanıcı token'ını al
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken') ?? '';
      
      if (userToken.isEmpty) {
        logger.warning('User token bulunamadı');
        return FavoritesResponse(
          error: true,
          success: false,
          errorMessage: 'Oturum açmanız gerekiyor',
          isTokenError: true,
        );
      }

      // API isteği hazırla
      final uri = Uri.parse('$_baseUrl$_favoritesEndpoint/$userId/jobFavorites');
      final headers = AuthService.getHeaders();

      logger.debug('API isteği gönderiliyor', extra: {'url': uri.toString()});

      // HTTP isteği gönder
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(_connectTimeout);

      stopwatch.stop();

      // Network request'i logla
      logger.logNetworkRequest(
        method: 'GET',
        url: uri.toString(),
        statusCode: response.statusCode,
        duration: stopwatch.elapsed,
      );

      logger.debug('API yanıtı alındı', extra: {'statusCode': response.statusCode});

      // Yanıtı parse et
      final favoritesResponse = _parseFavoritesResponse(response);
      
      // Başarılı sonuç ise cache'e ekle
      if (favoritesResponse.isSuccessful && favoritesResponse.data != null) {
        _updateCache(favoritesResponse.data!);
        logger.debug('Favori iş ilanları cache\'e eklendi', extra: {'userId': userId});
      }

      return favoritesResponse;

    } catch (e, stackTrace) {
      stopwatch.stop();
      logger.error('Favori iş ilanları getirme hatası', 
                   error: e, stackTrace: stackTrace, 
                   extra: {'userId': userId, 'duration': stopwatch.elapsed.inMilliseconds});
      return FavoritesResponse(
        error: true,
        success: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// İş ilanını favoriye ekler
  /// [jobId] - İş ID'si
  /// Returns JobFavoriteAddResponse with status code handling (410 = success, 417 = error)
  Future<JobFavoriteAddResponse> addJobToFavorites(int jobId) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.info('İş ilanı favoriye ekleniyor', extra: {'jobId': jobId});
      
      // Kullanıcı token'ını al
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken') ?? '';
      
      if (userToken.isEmpty) {
        logger.warning('User token bulunamadı - favoriye ekleme');
        return JobFavoriteAddResponse(
          error: true,
          success: false,
          errorMessage: 'Oturum açmanız gerekiyor',
          isTokenError: true,
        );
      }

      // API isteği hazırla
      final uri = Uri.parse('$_baseUrl$_addFavoriteEndpoint');
      final headers = AuthService.getHeaders();
      
      final request = JobFavoriteAddRequest(
        userToken: userToken,
        jobID: jobId,
      );

      logger.debug('Favoriye ekleme API isteği gönderiliyor', 
                   extra: {'url': uri.toString(), 'body': request.toJson()});

      // HTTP isteği gönder
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(request.toJson()),
      ).timeout(_connectTimeout);

      stopwatch.stop();

      // Network request'i logla
      logger.logNetworkRequest(
        method: 'POST',
        url: uri.toString(),
        statusCode: response.statusCode,
        duration: stopwatch.elapsed,
      );

      logger.debug('Favoriye ekleme API yanıtı alındı', 
                   extra: {'statusCode': response.statusCode});

      // Yanıtı parse et
      final favoriteResponse = _parseJobFavoriteAddResponse(response);
      
      // Başarılı sonuç ise cache'i güncelle
      if (favoriteResponse.isSuccessful) {
        _clearCache(); // Cache'i temizle ki yeniden çekilsin
        logger.debug('İş favoriye eklendi - cache temizlendi', extra: {'jobId': jobId});
      }

      return favoriteResponse;

    } catch (e, stackTrace) {
      stopwatch.stop();
      logger.error('İş favoriye ekleme hatası', 
                   error: e, stackTrace: stackTrace, 
                   extra: {'jobId': jobId, 'duration': stopwatch.elapsed.inMilliseconds});
      return JobFavoriteAddResponse(
        error: true,
        success: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// İş ilanını favoriden çıkarır
  /// [jobId] - İş ID'si
  /// Returns JobFavoriteRemoveResponse with status code handling (410 = success, 417 = error)
  Future<JobFavoriteRemoveResponse> removeJobFromFavorites(int jobId) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.info('İş ilanı favoriden çıkarılıyor', extra: {'jobId': jobId});
      
      // Kullanıcı token'ını al
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken') ?? '';
      
      if (userToken.isEmpty) {
        logger.warning('User token bulunamadı - favoriden çıkarma');
        return JobFavoriteRemoveResponse(
          error: true,
          success: false,
          errorMessage: 'Oturum açmanız gerekiyor',
          isTokenError: true,
        );
      }

      // API isteği hazırla
      final uri = Uri.parse('$_baseUrl$_removeFavoriteEndpoint');
      final headers = AuthService.getHeaders();
      
      final request = JobFavoriteRemoveRequest(
        userToken: userToken,
        jobID: jobId,
      );

      logger.debug('Favoriden çıkarma API isteği gönderiliyor', 
                   extra: {'url': uri.toString(), 'body': request.toJson()});

      // HTTP isteği gönder
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(request.toJson()),
      ).timeout(_connectTimeout);

      stopwatch.stop();

      // Network request'i logla
      logger.logNetworkRequest(
        method: 'POST',
        url: uri.toString(),
        statusCode: response.statusCode,
        duration: stopwatch.elapsed,
      );

      logger.debug('Favoriden çıkarma API yanıtı alındı', 
                   extra: {'statusCode': response.statusCode});

      // Yanıtı parse et
      final favoriteResponse = _parseJobFavoriteRemoveResponse(response);
      
      // Başarılı sonuç ise cache'i güncelle
      if (favoriteResponse.isSuccessful) {
        _clearCache(); // Cache'i temizle ki yeniden çekilsin
        logger.debug('İş favoriden çıkarıldı - cache temizlendi', extra: {'jobId': jobId});
      }

      return favoriteResponse;

    } catch (e, stackTrace) {
      stopwatch.stop();
      logger.error('İş favoriden çıkarma hatası', 
                   error: e, stackTrace: stackTrace, 
                   extra: {'jobId': jobId, 'duration': stopwatch.elapsed.inMilliseconds});
      return JobFavoriteRemoveResponse(
        error: true,
        success: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Favori ekleme/çıkarma durumunu optimize edilmiş şekilde değiştirir
  /// [jobId] - İş ID'si
  /// [isFavorite] - Favorileme durumu (true: ekle, false: çıkar)
  Future<bool> toggleJobFavorite(int jobId, bool isFavorite) async {
    try {
      logger.info('İş favorileme durumu değiştiriliyor', 
                  extra: {'jobId': jobId, 'isFavorite': isFavorite});
      
      if (isFavorite) {
        // Favoriye ekle
        final response = await addJobToFavorites(jobId);
        if (response.isSuccessful) {
          logger.debug('İş başarıyla favoriye eklendi', extra: {'jobId': jobId});
          return true;
        } else {
          logger.warning('İş favoriye eklenemedi', 
                        extra: {'jobId': jobId, 'error': response.displayMessage});
          return false;
        }
      } else {
        // Favoriden çıkar
        final response = await removeJobFromFavorites(jobId);
        if (response.isSuccessful) {
          logger.debug('İş başarıyla favoriden çıkarıldı', extra: {'jobId': jobId});
          return true;
        } else {
          logger.warning('İş favoriden çıkarılamadı', 
                        extra: {'jobId': jobId, 'error': response.displayMessage});
          return false;
        }
      }
    } catch (e, stackTrace) {
      logger.error('İş favorileme durumu değiştirme hatası', 
                   error: e, stackTrace: stackTrace, 
                   extra: {'jobId': jobId, 'isFavorite': isFavorite});
      return false;
    }
  }

  /// Favori iş ilanlarını yeniler (cache bypass)
  Future<FavoritesResponse> refreshFavorites(int userId) async {
    return await fetchFavorites(userId, useCache: false);
  }

  /// Cache'in geçerli olup olmadığını kontrol eder
  bool _isCacheValid() {
    if (_cache == null || _cacheTimestamp == null) {
      return false;
    }
    
    final now = DateTime.now();
    return now.difference(_cacheTimestamp!) < _cacheExpiration;
  }

  /// Cache'i günceller
  void _updateCache(FavoritesData data) {
    _cache = data;
    _cacheTimestamp = DateTime.now();
  }

  /// Cache'deki favori durumunu günceller
  void _updateFavoriteInCache(int jobId, bool isFavorite) {
    if (_cache == null) return;

    if (isFavorite) {
      // Favorilere ekleme - Bu durumda tam job bilgisi olmadığından cache'i temizle
      clearCache();
    } else {
      // Favorilerden çıkarma
      final updatedFavorites = _cache!.favorites.where((fav) => fav.jobID != jobId).toList();
      _cache = FavoritesData(favorites: updatedFavorites);
    }
  }

  /// Cache'i temizler
  void clearCache() {
    _cache = null;
    _cacheTimestamp = null;
    logger.debug('Favoriler cache\'i temizlendi');
  }

  /// HTTP yanıtını FavoritesResponse'a çevirir
  FavoritesResponse _parseFavoritesResponse(http.Response response) {
    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      // Özel status kod kontrolü
      final has410 = jsonResponse.containsKey('410');
      final has417 = jsonResponse.containsKey('417');
      
      if (has417) {
        // 417 status kod hata demektir
        return FavoritesResponse(
          error: true,
          success: false,
          status417: jsonResponse['417'],
          errorMessage: jsonResponse['417'] ?? 'Bilinmeyen hata',
        );
      }
      
      if (has410 || (!jsonResponse['error'] && jsonResponse['success'])) {
        // 410 status kod başarılı demektir
        return FavoritesResponse.fromJson(jsonResponse);
      } else {
        // Normal error handling
        return FavoritesResponse.fromJson(jsonResponse);
      }

    } catch (e, stackTrace) {
      logger.error('JSON parse hatası', error: e, stackTrace: stackTrace);
      return FavoritesResponse(
        error: true,
        success: false,
        errorMessage: 'Veri işleme hatası',
      );
    }
  }

  /// Exception'ı kullanıcı dostu hata mesajına çevirir
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('TimeoutException')) {
      return 'Bağlantı zaman aşımına uğradı';
    } else if (error.toString().contains('SocketException')) {
      return 'İnternet bağlantınızı kontrol edin';
    } else if (error.toString().contains('HttpException')) {
      return 'Sunucu hatası';
    } else if (error.toString().contains('FormatException')) {
      return 'Veri formatı hatası';
    } else {
      return 'Bilinmeyen hata oluştu';
    }
  }

  /// HTTP yanıtını JobFavoriteAddResponse'a çevirir
  JobFavoriteAddResponse _parseJobFavoriteAddResponse(http.Response response) {
    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      // Özel status kod kontrolü
      final has410 = jsonResponse.containsKey('410');
      final has417 = jsonResponse.containsKey('417');
      
      if (has417) {
        // 417 status kod hata demektir
        return JobFavoriteAddResponse(
          error: true,
          success: false,
          status417: jsonResponse['417'],
          errorMessage: jsonResponse['417'] ?? 'Bilinmeyen hata',
        );
      }
      
      if (has410 || (!jsonResponse['error'] && jsonResponse['success'])) {
        // 410 status kod başarılı demektir
        return JobFavoriteAddResponse.fromJson(jsonResponse);
      }
      
      // Varsayılan hata durumu
      return JobFavoriteAddResponse(
        error: true,
        success: false,
        errorMessage: jsonResponse['error_message'] ?? 'Bilinmeyen hata',
      );
      
    } catch (e) {
      logger.error('JobFavoriteAddResponse parse hatası: $e');
      return JobFavoriteAddResponse(
        error: true,
        success: false,
        errorMessage: 'Veri işleme hatası',
      );
    }
  }

  /// HTTP yanıtını JobFavoriteRemoveResponse'a çevirir
  JobFavoriteRemoveResponse _parseJobFavoriteRemoveResponse(http.Response response) {
    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      // Özel status kod kontrolü
      final has410 = jsonResponse.containsKey('410');
      final has417 = jsonResponse.containsKey('417');
      
      if (has417) {
        // 417 status kod hata demektir
        return JobFavoriteRemoveResponse(
          error: true,
          success: false,
          status417: jsonResponse['417'],
          errorMessage: jsonResponse['417'] ?? 'Bilinmeyen hata',
        );
      }
      
      if (has410 || (!jsonResponse['error'] && jsonResponse['success'])) {
        // 410 status kod başarılı demektir
        return JobFavoriteRemoveResponse.fromJson(jsonResponse);
      }
      
      // Varsayılan hata durumu
      return JobFavoriteRemoveResponse(
        error: true,
        success: false,
        errorMessage: jsonResponse['error_message'] ?? 'Bilinmeyen hata',
      );
      
    } catch (e) {
      logger.error('JobFavoriteRemoveResponse parse hatası: $e');
      return JobFavoriteRemoveResponse(
        error: true,
        success: false,
        errorMessage: 'Veri işleme hatası',
      );
    }
  }



  /// Cache istatistiklerini döner
  Map<String, dynamic> getCacheStats() {
    return {
      'hasCachedData': _cache != null,
      'cacheSize': _cache?.favoriteCount ?? 0,
      'cacheExpirationMinutes': _cacheExpiration.inMinutes,
      'cacheTimestamp': _cacheTimestamp?.toIso8601String(),
      'isCacheValid': _isCacheValid(),
    };
  }

  /// Mevcut cache'deki favori sayısını döner
  int get cachedFavoriteCount => _cache?.favoriteCount ?? 0;

  /// Cache'de belirli bir job'ın favori olup olmadığını kontrol eder
  bool isJobFavoriteInCache(int jobId) {
    if (_cache == null) return false;
    return _cache!.favorites.any((fav) => fav.jobID == jobId);
  }

  /// Cache'den belirli bir favoriyi getirir
  FavoriteJobModel? getFavoriteFromCache(int jobId) {
    if (_cache == null) return null;
    try {
      return _cache!.favorites.firstWhere((fav) => fav.jobID == jobId);
    } catch (e) {
      return null;
    }
  }

  /// Cache'den arama yapar
  List<FavoriteJobModel> searchFavoritesInCache(String query) {
    if (_cache == null) return [];
    return _cache!.searchFavorites(query);
  }

  /// Cache'den filtreli favorileri getirir
  List<FavoriteJobModel> getFilteredFavoritesFromCache(FavoritesFilter filter) {
    if (_cache == null) return [];
    return filter.applyFilter(_cache!.favorites);
  }

  /// Cache'i temizler
  void _clearCache() {
    _cache = null;
    _cacheTimestamp = null;
    logger.debug('Favoriler cache temizlendi');
  }
} 