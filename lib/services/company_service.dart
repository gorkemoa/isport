import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/company_models.dart';
import '../models/auth_models.dart';
import 'auth_services.dart';
import 'logger_service.dart';

/// Firma detayı ile ilgili API servis işlemleri
class CompanyService {
  static const String _baseUrl = 'https://api.rivorya.com/isport';
  static const String _companyDetailEndpoint = '/service/user/account';
  static const String _companyFavoriteEndpoint = '/service/user/account/favorite';

  /// Timeout süreleri
  static const Duration _connectTimeout = Duration(seconds: 10);
  static const Duration _receiveTimeout = Duration(seconds: 15);

  /// Cache yönetimi
  static final Map<int, CompanyDetailData> _cache = {};
  static final Map<int, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);

  /// Firma detayını getirir
  /// [companyId] - Firma ID'si
  /// [useCache] - Cache kullanılsın mı (varsayılan: true)
  /// Returns CompanyDetailResponse with status code handling (410 = success, 417 = error)
  Future<CompanyDetailResponse> fetchCompanyDetail(int companyId, {bool useCache = true}) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.info('Firma detayı getiriliyor', extra: {'companyId': companyId, 'useCache': useCache});
      
      // Cache kontrolü
      if (useCache && _isCacheValid(companyId)) {
        logger.debug('Cache\'den firma detayı döndürülüyor', extra: {'companyId': companyId});
        return CompanyDetailResponse(
          error: false,
          success: true,
          data: _cache[companyId]!,
          status410: 'Gone',
          errorMessage: '',
        );
      }

      // Kullanıcı token'ını al
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken') ?? '';
      
      if (userToken.isEmpty) {
        logger.warning('User token bulunamadı');
        return CompanyDetailResponse(
          error: true,
          success: false,
          errorMessage: 'Oturum açmanız gerekiyor',
          isTokenError: true,
        );
      }

      // API isteği hazırla
      final uri = Uri.parse('$_baseUrl$_companyDetailEndpoint/$companyId/companyDetail')
          .replace(queryParameters: {'userToken': userToken});
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
      final companyResponse = _parseCompanyDetailResponse(response);
      
      // Başarılı sonuç ise cache'e ekle
      if (companyResponse.isSuccessful && companyResponse.data != null) {
        _updateCache(companyId, companyResponse.data!);
        logger.debug('Firma detayı cache\'e eklendi', extra: {'companyId': companyId});
      }

      return companyResponse;

    } catch (e, stackTrace) {
      stopwatch.stop();
      logger.error('Firma detayı getirme hatası', 
                   error: e, stackTrace: stackTrace, 
                   extra: {'companyId': companyId, 'duration': stopwatch.elapsed.inMilliseconds});
      return CompanyDetailResponse(
        error: true,
        success: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Firma favorileme durumunu değiştirir
  /// [companyId] - Firma ID'si
  /// [isFavorite] - Favorileme durumu
  Future<CompanyFavoriteResponse> toggleCompanyFavorite(int companyId, bool isFavorite) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.info('Firma favorileme durumu değiştiriliyor', 
                  extra: {'companyId': companyId, 'isFavorite': isFavorite});
      
      // Kullanıcı token'ını al
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken') ?? '';
      
      if (userToken.isEmpty) {
        logger.warning('User token bulunamadı');
        return CompanyFavoriteResponse(
          error: true,
          success: false,
          errorMessage: 'Oturum açmanız gerekiyor',
          isTokenError: true,
        );
      }

      // API isteği hazırla
      final uri = Uri.parse('$_baseUrl$_companyFavoriteEndpoint');
      final headers = AuthService.getHeaders(userToken: userToken);
      
      final request = CompanyFavoriteRequest(
        userToken: userToken,
        compID: companyId,
        isFavorite: isFavorite,
      );

      logger.debug('API isteği gönderiliyor', extra: {'url': uri.toString(), 'body': request.toJson()});

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

      logger.debug('API yanıtı alındı', extra: {'statusCode': response.statusCode});

      // Yanıtı parse et
      final favoriteResponse = _parseFavoriteResponse(response);
      
      // Başarılı sonuç ise cache'i güncelle
      if (favoriteResponse.success && _cache.containsKey(companyId)) {
        final cachedData = _cache[companyId]!;
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
        
        _updateCache(companyId, CompanyDetailData(
          company: updatedCompany,
          jobs: cachedData.jobs,
        ));
        
        logger.debug('Firma favorileme durumu cache\'de güncellendi', extra: {'companyId': companyId});
      }

      return favoriteResponse;

    } catch (e, stackTrace) {
      stopwatch.stop();
      logger.error('Firma favorileme hatası', 
                   error: e, stackTrace: stackTrace, 
                   extra: {'companyId': companyId, 'duration': stopwatch.elapsed.inMilliseconds});
      return CompanyFavoriteResponse(
        error: true,
        success: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Birden fazla firma detayını getirir (batch işlemi)
  /// [companyIds] - Firma ID'leri listesi
  /// [useCache] - Cache kullanılsın mı (varsayılan: true)
  Future<List<CompanyDetailResponse>> fetchMultipleCompanyDetails(
    List<int> companyIds, {
    bool useCache = true,
  }) async {
    logger.info('Birden fazla firma detayı getiriliyor', extra: {'companyCount': companyIds.length});
    
    final responses = <CompanyDetailResponse>[];
    final futures = companyIds.map((id) => fetchCompanyDetail(id, useCache: useCache));
    
    try {
      final results = await Future.wait(futures);
      responses.addAll(results);
      
      logger.info('Birden fazla firma detayı tamamlandı', 
                  extra: {'successCount': results.where((r) => r.isSuccessful).length});
      
    } catch (e, stackTrace) {
      logger.error('Birden fazla firma detayı getirme hatası', error: e, stackTrace: stackTrace);
    }
    
    return responses;
  }

  /// Cache'in geçerli olup olmadığını kontrol eder
  bool _isCacheValid(int companyId) {
    if (!_cache.containsKey(companyId) || !_cacheTimestamps.containsKey(companyId)) {
      return false;
    }
    
    final cacheTime = _cacheTimestamps[companyId]!;
    final now = DateTime.now();
    
    return now.difference(cacheTime) < _cacheExpiration;
  }

  /// Cache'i günceller
  void _updateCache(int companyId, CompanyDetailData data) {
    _cache[companyId] = data;
    _cacheTimestamps[companyId] = DateTime.now();
    
    // Cache boyutunu kontrol et (maksimum 50 firma)
    if (_cache.length > 50) {
      _cleanOldCache();
    }
  }

  /// Eski cache verilerini temizler
  void _cleanOldCache() {
    final now = DateTime.now();
    final keysToRemove = <int>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiration) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    logger.debug('Cache temizlendi', extra: {'removedCount': keysToRemove.length});
  }

  /// Cache'i temizler
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    logger.debug('Cache tamamen temizlendi');
  }

  /// Belirli bir firma için cache'i temizler
  void clearCompanyCache(int companyId) {
    _cache.remove(companyId);
    _cacheTimestamps.remove(companyId);
    logger.debug('Firma cache\'i temizlendi', extra: {'companyId': companyId});
  }

  /// HTTP yanıtını CompanyDetailResponse'a çevirir
  CompanyDetailResponse _parseCompanyDetailResponse(http.Response response) {
    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      // Özel status kod kontrolü
      final has410 = jsonResponse.containsKey('410');
      final has417 = jsonResponse.containsKey('417');
      
      if (has417) {
        // 417 status kod hata demektir
        return CompanyDetailResponse(
          error: true,
          success: false,
          status417: jsonResponse['417'],
          errorMessage: jsonResponse['417'] ?? 'Bilinmeyen hata',
        );
      }
      
      if (has410 || (!jsonResponse['error'] && jsonResponse['success'])) {
        // 410 status kod başarılı demektir
        return CompanyDetailResponse.fromJson(jsonResponse);
      } else {
        // Normal error handling
        return CompanyDetailResponse.fromJson(jsonResponse);
      }

    } catch (e, stackTrace) {
      logger.error('JSON parse hatası', error: e, stackTrace: stackTrace);
      return CompanyDetailResponse(
        error: true,
        success: false,
        errorMessage: 'Veri işleme hatası',
      );
    }
  }

  /// HTTP yanıtını CompanyFavoriteResponse'a çevirir
  CompanyFavoriteResponse _parseFavoriteResponse(http.Response response) {
    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      // Token hatası kontrolü
      if (response.statusCode == 403) {
        return CompanyFavoriteResponse.fromJson(jsonResponse, isTokenError: true);
      }
      
      return CompanyFavoriteResponse.fromJson(jsonResponse);

    } catch (e, stackTrace) {
      logger.error('JSON parse hatası', error: e, stackTrace: stackTrace);
      return CompanyFavoriteResponse(
        error: true,
        success: false,
        errorMessage: 'Veri işleme hatası',
      );
    }
  }

  /// Exception'ı kullanıcı dostu hata mesajına çevirir
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('TimeoutException') || 
        error.toString().contains('timeout')) {
      return 'Bağlantı zaman aşımı. Lütfen tekrar deneyin.';
    } else if (error.toString().contains('SocketException') || 
               error.toString().contains('No address associated')) {
      return 'İnternet bağlantısını kontrol edin.';
    } else if (error.toString().contains('HandshakeException')) {
      return 'Güvenli bağlantı hatası.';
    } else {
      return 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  /// Cache istatistiklerini döner
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _cache.length,
      'cacheCapacity': 50,
      'cacheExpirationMinutes': _cacheExpiration.inMinutes,
      'oldestCacheEntry': _cacheTimestamps.isEmpty 
          ? null 
          : _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String(),
    };
  }
} 