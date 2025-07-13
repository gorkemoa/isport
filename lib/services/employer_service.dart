import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employer_models.dart';
import '../models/auth_models.dart';
import 'auth_services.dart';
import 'logger_service.dart';

/// Firma iş ilanları ve başvuruları ile ilgili API servis işlemleri
class EmployerService {
  static const String _baseUrl = 'https://api.rivorya.com/isport';
  static const String _companyJobsEndpoint = '/service/user/company';
  static const String _companyApplicationsEndpoint = '/service/user/company';

  /// Timeout süreleri
  static const Duration _connectTimeout = Duration(seconds: 10);
  static const Duration _receiveTimeout = Duration(seconds: 15);

  /// Cache yönetimi
  static final Map<int, EmployerJobsData> _jobsCache = {};
  static final Map<int, DateTime> _jobsCacheTimestamps = {};
  static final Map<int, EmployerApplicationsData> _applicationsCache = {};
  static final Map<int, DateTime> _applicationsCacheTimestamps = {};
  static final Map<int, EmployerFavoriteApplicantsData> _favoriteApplicantsCache = {};
  static final Map<int, DateTime> _favoriteApplicantsCacheTimestamps = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);

  /// Firma iş ilanlarını getirir
  /// [companyId] - Firma ID'si
  /// [useCache] - Cache kullanılsın mı (varsayılan: true)
  /// Returns EmployerJobsResponse with status code handling (410 = success, 417 = error)
  Future<EmployerJobsResponse> fetchCompanyJobs(int companyId, {bool useCache = true}) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.info('Firma iş ilanları getiriliyor', extra: {'companyId': companyId, 'useCache': useCache});
      
      // Cache kontrolü
      if (useCache && _isJobsCacheValid(companyId)) {
        logger.debug('Cache\'den firma iş ilanları döndürülüyor', extra: {'companyId': companyId});
        return EmployerJobsResponse(
          error: false,
          success: true,
          data: _jobsCache[companyId]!,
          status410: 'Gone',
          errorMessage: '',
        );
      }

      // Kullanıcı token'ını al
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken') ?? '';
      
      if (userToken.isEmpty) {
        logger.warning('User token bulunamadı');
        return EmployerJobsResponse(
          error: true,
          success: false,
          errorMessage: 'Oturum açmanız gerekiyor',
          isTokenError: true,
        );
      }

      // API isteği hazırla
      final uri = Uri.parse('$_baseUrl$_companyJobsEndpoint/$companyId/companyJobList');
      final headers = AuthService.getHeaders(userToken: userToken);

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
      final jobsResponse = _parseEmployerJobsResponse(response);
      
      // Başarılı sonuç ise cache'e ekle
      if (jobsResponse.isSuccessful && jobsResponse.data != null) {
        _updateJobsCache(companyId, jobsResponse.data!);
        logger.debug('Firma iş ilanları cache\'e eklendi', extra: {'companyId': companyId});
      }

      return jobsResponse;

    } catch (e, stackTrace) {
      stopwatch.stop();
      logger.error('Firma iş ilanları getirme hatası', 
                   error: e, stackTrace: stackTrace, 
                   extra: {'companyId': companyId, 'duration': stopwatch.elapsed.inMilliseconds});
      return EmployerJobsResponse(
        error: true,
        success: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Firma iş başvurularını getirir
  /// [companyId] - Firma ID'si
  /// [jobId] - İş ID'si (opsiyonel, belirli bir iş için başvurular)
  /// [useCache] - Cache kullanılsın mı (varsayılan: true)
  /// Returns EmployerApplicationsResponse with status code handling (410 = success, 417 = error)
  Future<EmployerApplicationsResponse> fetchCompanyApplications(
    int companyId, {
    int? jobId,
    bool useCache = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.info('Firma iş başvuruları getiriliyor', 
                  extra: {'companyId': companyId, 'jobId': jobId, 'useCache': useCache});
      
      // Cache kontrolü
      final cacheKey = jobId ?? 0;
      if (useCache && _isApplicationsCacheValid(cacheKey)) {
        logger.debug('Cache\'den firma iş başvuruları döndürülüyor', 
                    extra: {'companyId': companyId, 'jobId': jobId});
        return EmployerApplicationsResponse(
          error: false,
          success: true,
          data: _applicationsCache[cacheKey]!,
          status410: 'Gone',
          errorMessage: '',
        );
      }

      // Kullanıcı token'ını al
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken') ?? '';
      
      if (userToken.isEmpty) {
        logger.warning('User token bulunamadı');
        return EmployerApplicationsResponse(
          error: true,
          success: false,
          errorMessage: 'Oturum açmanız gerekiyor',
          isTokenError: true,
        );
      }

      // API isteği hazırla
      String endpoint = '$_baseUrl$_companyApplicationsEndpoint/$companyId/jobApplications';
      if (jobId != null) {
        endpoint += '?jobID=$jobId';
      }
      
      final uri = Uri.parse(endpoint);
      final headers = AuthService.getHeaders(userToken: userToken);

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
      final applicationsResponse = _parseEmployerApplicationsResponse(response);
      
      // Başarılı sonuç ise cache'e ekle
      if (applicationsResponse.isSuccessful && applicationsResponse.data != null) {
        _updateApplicationsCache(cacheKey, applicationsResponse.data!);
        logger.debug('Firma iş başvuruları cache\'e eklendi', 
                    extra: {'companyId': companyId, 'jobId': jobId});
      }

      return applicationsResponse;

    } catch (e, stackTrace) {
      stopwatch.stop();
      logger.error('Firma iş başvuruları getirme hatası', 
                   error: e, stackTrace: stackTrace, 
                   extra: {'companyId': companyId, 'jobId': jobId, 'duration': stopwatch.elapsed.inMilliseconds});
      return EmployerApplicationsResponse(
        error: true,
        success: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Firma favori adaylarını getirir
  /// [companyId] - Firma ID'si
  /// [useCache] - Cache kullanılsın mı (varsayılan: true)
  /// Returns EmployerFavoriteApplicantsResponse with status code handling (410 = success, 417 = error)
  Future<EmployerFavoriteApplicantsResponse> fetchCompanyFavoriteApplicants(
    int companyId, {
    bool useCache = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.info('Firma favori adayları getiriliyor', 
                  extra: {'companyId': companyId, 'useCache': useCache});
      
      // Cache kontrolü
      if (useCache && _isFavoriteApplicantsCacheValid(companyId)) {
        logger.debug('Cache\'den firma favori adayları döndürülüyor', 
                    extra: {'companyId': companyId});
        return EmployerFavoriteApplicantsResponse(
          error: false,
          success: true,
          data: _favoriteApplicantsCache[companyId]!,
          status410: 'Gone',
          errorMessage: '',
        );
      }

      // Kullanıcı token'ını al
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken') ?? '';
      
      if (userToken.isEmpty) {
        logger.warning('User token bulunamadı');
        return EmployerFavoriteApplicantsResponse(
          error: true,
          success: false,
          errorMessage: 'Oturum açmanız gerekiyor',
          isTokenError: true,
        );
      }

      // API isteği hazırla
      final uri = Uri.parse('$_baseUrl$_companyApplicationsEndpoint/$companyId/favoriteApplicants');
      final headers = AuthService.getHeaders(userToken: userToken);

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
      final favoriteApplicantsResponse = _parseEmployerFavoriteApplicantsResponse(response);
      
      // Başarılı sonuç ise cache'e ekle
      if (favoriteApplicantsResponse.isSuccessful && favoriteApplicantsResponse.data != null) {
        _updateFavoriteApplicantsCache(companyId, favoriteApplicantsResponse.data!);
        logger.debug('Firma favori adayları cache\'e eklendi', 
                    extra: {'companyId': companyId});
      }

      return favoriteApplicantsResponse;

    } catch (e, stackTrace) {
      stopwatch.stop();
      logger.error('Firma favori adayları getirme hatası', 
                   error: e, stackTrace: stackTrace, 
                   extra: {'companyId': companyId, 'duration': stopwatch.elapsed.inMilliseconds});
      return EmployerFavoriteApplicantsResponse(
        error: true,
        success: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Mevcut kullanıcının şirketinin iş ilanlarını getirir
  Future<EmployerJobsResponse> fetchCurrentUserCompanyJobs({bool useCache = true}) async {
    try {
      logger.debug('Mevcut kullanıcının şirket iş ilanları getiriliyor');
      
      // Kullanıcı bilgilerini al
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString == null) {
        return EmployerJobsResponse(
          error: true,
          success: false,
          errorMessage: 'Kullanıcı bilgileri bulunamadı',
          isTokenError: true,
        );
      }

      final userData = jsonDecode(userDataString);
      final user = User.fromJson(userData);
      
      if (!user.isComp) {
        return EmployerJobsResponse(
          error: true,
          success: false,
          errorMessage: 'Sadece şirket hesapları iş ilanlarını görüntüleyebilir',
        );
      }

      // Kullanıcının şirket ID'sini kullan
      return await fetchCompanyJobs(user.userID, useCache: useCache);

    } catch (e) {
      logger.error('Mevcut kullanıcı şirket iş ilanları getirme hatası: $e');
      return EmployerJobsResponse(
        error: true,
        success: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Mevcut kullanıcının şirketinin iş başvurularını getirir
  Future<EmployerApplicationsResponse> fetchCurrentUserCompanyApplications({
    int? jobId,
    bool useCache = true,
  }) async {
    try {
      logger.debug('Mevcut kullanıcının şirket iş başvuruları getiriliyor');
      
      // Kullanıcı bilgilerini al
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString == null) {
        return EmployerApplicationsResponse(
          error: true,
          success: false,
          errorMessage: 'Kullanıcı bilgileri bulunamadı',
          isTokenError: true,
        );
      }

      final userData = jsonDecode(userDataString);
      final user = User.fromJson(userData);
      
      if (!user.isComp) {
        return EmployerApplicationsResponse(
          error: true,
          success: false,
          errorMessage: 'Sadece şirket hesapları iş başvurularını görüntüleyebilir',
        );
      }

      // Kullanıcının şirket ID'sini kullan
      return await fetchCompanyApplications(user.userID, jobId: jobId, useCache: useCache);

    } catch (e) {
      logger.error('Mevcut kullanıcı şirket iş başvuruları getirme hatası: $e');
      return EmployerApplicationsResponse(
        error: true,
        success: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Mevcut kullanıcının şirketinin favori adaylarını getirir
  Future<EmployerFavoriteApplicantsResponse> fetchCurrentUserCompanyFavoriteApplicants({bool useCache = true}) async {
    try {
      logger.debug('Mevcut kullanıcının şirket favori adayları getiriliyor');
      
      // Kullanıcı bilgilerini al
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString == null) {
        return EmployerFavoriteApplicantsResponse(
          error: true,
          success: false,
          errorMessage: 'Kullanıcı bilgileri bulunamadı',
          isTokenError: true,
        );
      }

      final userData = jsonDecode(userDataString);
      final user = User.fromJson(userData);
      
      if (!user.isComp) {
        return EmployerFavoriteApplicantsResponse(
          error: true,
          success: false,
          errorMessage: 'Sadece şirket hesapları favori adayları görüntüleyebilir',
        );
      }

      // Kullanıcının şirket ID'sini kullan
      return await fetchCompanyFavoriteApplicants(user.userID, useCache: useCache);

    } catch (e) {
      logger.error('Mevcut kullanıcı şirket favori adayları getirme hatası: $e');
      return EmployerFavoriteApplicantsResponse(
        error: true,
        success: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// İş ilanlarını yeniler (cache bypass)
  Future<EmployerJobsResponse> refreshCompanyJobs(int companyId) async {
    return await fetchCompanyJobs(companyId, useCache: false);
  }

  /// İş başvurularını yeniler (cache bypass)
  Future<EmployerApplicationsResponse> refreshCompanyApplications(int companyId, {int? jobId}) async {
    return await fetchCompanyApplications(companyId, jobId: jobId, useCache: false);
  }

  /// Favori adayları yeniler (cache bypass)
  Future<EmployerFavoriteApplicantsResponse> refreshCompanyFavoriteApplicants(int companyId) async {
    return await fetchCompanyFavoriteApplicants(companyId, useCache: false);
  }

  /// Favori aday ekler veya çıkarır
  /// [jobId] - İş ID'si
  /// [applicantId] - Aday ID'si
  /// Returns FavoriteApplicantResponse with status code handling (410 = success, 417 = error)
  Future<FavoriteApplicantResponse> toggleFavoriteApplicant(int jobId, int applicantId) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.info('Favori aday durumu değiştiriliyor', 
                  extra: {'jobId': jobId, 'applicantId': applicantId});
      
      // Kullanıcı token'ını al
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken') ?? '';
      
      if (userToken.isEmpty) {
        logger.warning('User token bulunamadı');
        return FavoriteApplicantResponse(
          error: true,
          success: false,
          errorMessage: 'Oturum açmanız gerekiyor',
          isTokenError: true,
        );
      }

      // API isteği hazırla
      final uri = Uri.parse('$_baseUrl/service/user/company/favoriteApplicant');
      final headers = AuthService.getHeaders(userToken: userToken);
      
      final request = FavoriteApplicantRequest(
        userToken: userToken,
        jobID: jobId,
        applicantID: applicantId,
      );

      logger.debug('Favori aday API isteği gönderiliyor', 
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

      logger.debug('Favori aday API yanıtı alındı', 
                   extra: {'statusCode': response.statusCode});

      // Yanıtı parse et
      final favoriteResponse = _parseFavoriteApplicantResponse(response);
      
      // Başarılı sonuç ise cache'i temizle
      if (favoriteResponse.isSuccessful) {
        // Favori adaylar cache'ini temizle ki yeniden çekilsin
        _clearFavoriteApplicantsCache();
        logger.debug('Favori aday durumu değiştirildi - cache temizlendi', 
                    extra: {'jobId': jobId, 'applicantId': applicantId});
      }

      return favoriteResponse;

    } catch (e, stackTrace) {
      stopwatch.stop();
      logger.error('Favori aday durumu değiştirme hatası', 
                   error: e, stackTrace: stackTrace, 
                   extra: {'jobId': jobId, 'applicantId': applicantId, 'duration': stopwatch.elapsed.inMilliseconds});
      return FavoriteApplicantResponse(
        error: true,
        success: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Başvuru detayını getirir ve günceller
  /// [companyId] - Firma ID'si
  /// [appId] - Başvuru ID'si
  /// [newStatus] - Yeni durum ID'si (opsiyonel)
  /// Returns ApplicationDetailUpdateResponse with status code handling (410 = success, 417 = error)
  Future<ApplicationDetailUpdateResponse> getApplicationDetailUpdate(
    int companyId, 
    int appId, {
    int? newStatus,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.info('Başvuru detayı getiriliyor/güncelleniyor', 
                  extra: {'companyId': companyId, 'appId': appId, 'newStatus': newStatus});
      
      // Kullanıcı token'ını al
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken') ?? '';
      
      if (userToken.isEmpty) {
        logger.warning('User token bulunamadı');
        return ApplicationDetailUpdateResponse(
          error: true,
          success: false,
          errorMessage: 'Oturum açmanız gerekiyor',
          isTokenError: true,
        );
      }

      // API isteği hazırla
      final uri = Uri.parse('$_baseUrl$_companyApplicationsEndpoint/$companyId/applicationDetailUpdate');
      final headers = AuthService.getHeaders(userToken: userToken);
      
      final request = ApplicationDetailUpdateRequest(
        userToken: userToken,
        appID: appId,
        newStatus: newStatus,
      );

      logger.debug('Başvuru detayı API isteği gönderiliyor', 
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

      logger.debug('Başvuru detayı API yanıtı alındı', 
                   extra: {'statusCode': response.statusCode});

      // Yanıtı parse et
      final detailResponse = _parseApplicationDetailUpdateResponse(response);
      
      // Başarılı sonuç ise cache'i temizle
      if (detailResponse.isSuccessful) {
        // Başvurular cache'ini temizle ki yeniden çekilsin
        _clearApplicationsCache();
        logger.debug('Başvuru detayı güncellendi - cache temizlendi', 
                    extra: {'companyId': companyId, 'appId': appId});
      }

      return detailResponse;

    } catch (e, stackTrace) {
      stopwatch.stop();
      logger.error('Başvuru detayı getirme/güncelleme hatası', 
                   error: e, stackTrace: stackTrace, 
                   extra: {'companyId': companyId, 'appId': appId, 'duration': stopwatch.elapsed.inMilliseconds});
      return ApplicationDetailUpdateResponse(
        error: true,
        success: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Cache'in geçerli olup olmadığını kontrol eder (iş ilanları)
  bool _isJobsCacheValid(int companyId) {
    if (!_jobsCache.containsKey(companyId) || !_jobsCacheTimestamps.containsKey(companyId)) {
      return false;
    }
    
    final cacheTime = _jobsCacheTimestamps[companyId]!;
    final now = DateTime.now();
    
    return now.difference(cacheTime) < _cacheExpiration;
  }

  /// Cache'in geçerli olup olmadığını kontrol eder (başvurular)
  bool _isApplicationsCacheValid(int cacheKey) {
    if (!_applicationsCache.containsKey(cacheKey) || !_applicationsCacheTimestamps.containsKey(cacheKey)) {
      return false;
    }
    
    final cacheTime = _applicationsCacheTimestamps[cacheKey]!;
    final now = DateTime.now();
    
    return now.difference(cacheTime) < _cacheExpiration;
  }

  /// Favori adayları cache'inin geçerli olup olmadığını kontrol eder
  bool _isFavoriteApplicantsCacheValid(int companyId) {
    if (!_favoriteApplicantsCache.containsKey(companyId) || !_favoriteApplicantsCacheTimestamps.containsKey(companyId)) {
      return false;
    }
    
    final cacheTime = _favoriteApplicantsCacheTimestamps[companyId]!;
    final now = DateTime.now();
    
    return now.difference(cacheTime) < _cacheExpiration;
  }

  /// İş ilanları cache'ini günceller
  void _updateJobsCache(int companyId, EmployerJobsData data) {
    _jobsCache[companyId] = data;
    _jobsCacheTimestamps[companyId] = DateTime.now();
    
    // Cache boyutunu kontrol et (maksimum 20 şirket)
    if (_jobsCache.length > 20) {
      _cleanOldJobsCache();
    }
  }

  /// Başvurular cache'ini günceller
  void _updateApplicationsCache(int cacheKey, EmployerApplicationsData data) {
    _applicationsCache[cacheKey] = data;
    _applicationsCacheTimestamps[cacheKey] = DateTime.now();
    
    // Cache boyutunu kontrol et (maksimum 50 başvuru seti)
    if (_applicationsCache.length > 50) {
      _cleanOldApplicationsCache();
    }
  }

  /// Favori adaylar cache'ini günceller
  void _updateFavoriteApplicantsCache(int companyId, EmployerFavoriteApplicantsData data) {
    _favoriteApplicantsCache[companyId] = data;
    _favoriteApplicantsCacheTimestamps[companyId] = DateTime.now();
    
    // Cache boyutunu kontrol et (maksimum 20 şirket)
    if (_favoriteApplicantsCache.length > 20) {
      _cleanOldFavoriteApplicantsCache();
    }
  }

  /// Eski iş ilanları cache verilerini temizler
  void _cleanOldJobsCache() {
    final now = DateTime.now();
    final keysToRemove = <int>[];
    
    for (final entry in _jobsCacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiration) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _jobsCache.remove(key);
      _jobsCacheTimestamps.remove(key);
    }
    
    logger.debug('İş ilanları cache temizlendi', extra: {'removedCount': keysToRemove.length});
  }

  /// Eski başvurular cache verilerini temizler
  void _cleanOldApplicationsCache() {
    final now = DateTime.now();
    final keysToRemove = <int>[];
    
    for (final entry in _applicationsCacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiration) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _applicationsCache.remove(key);
      _applicationsCacheTimestamps.remove(key);
    }
    
    logger.debug('Başvurular cache temizlendi', extra: {'removedCount': keysToRemove.length});
  }

  /// Eski favori adaylar cache verilerini temizler
  void _cleanOldFavoriteApplicantsCache() {
    final now = DateTime.now();
    final keysToRemove = <int>[];
    
    for (final entry in _favoriteApplicantsCacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiration) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _favoriteApplicantsCache.remove(key);
      _favoriteApplicantsCacheTimestamps.remove(key);
    }
    
    logger.debug('Favori adaylar cache temizlendi', extra: {'removedCount': keysToRemove.length});
  }

  /// Tüm cache'i temizler (güncellenmiş versiyon)
  void clearAllCache() {
    _jobsCache.clear();
    _jobsCacheTimestamps.clear();
    _applicationsCache.clear();
    _applicationsCacheTimestamps.clear();
    _favoriteApplicantsCache.clear();
    _favoriteApplicantsCacheTimestamps.clear();
    logger.debug('Tüm employer cache temizlendi');
  }

  /// Belirli bir şirket için favori adaylar cache'ini temizler
  void clearCompanyFavoriteApplicantsCache(int companyId) {
    _favoriteApplicantsCache.remove(companyId);
    _favoriteApplicantsCacheTimestamps.remove(companyId);
    logger.debug('Şirket favori adaylar cache\'i temizlendi', extra: {'companyId': companyId});
  }

  /// Belirli bir şirket için cache'i temizler (güncellenmiş versiyon)
  void clearCompanyCache(int companyId) {
    _jobsCache.remove(companyId);
    _jobsCacheTimestamps.remove(companyId);
    
    // Bu şirkete ait tüm başvuru cache'lerini de temizle
    final keysToRemove = <int>[];
    for (final key in _applicationsCache.keys) {
      // Basit bir yaklaşım: tüm başvuru cache'lerini temizle
      // Gerçek implementasyonda daha spesifik olabilir
      keysToRemove.add(key);
    }
    
    for (final key in keysToRemove) {
      _applicationsCache.remove(key);
      _applicationsCacheTimestamps.remove(key);
    }
    
    // Favori adaylar cache'ini de temizle
    clearCompanyFavoriteApplicantsCache(companyId);
    
    logger.debug('Şirket cache\'i temizlendi', extra: {'companyId': companyId});
  }

  /// HTTP yanıtını EmployerJobsResponse'a çevirir
  EmployerJobsResponse _parseEmployerJobsResponse(http.Response response) {
    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      // Özel status kod kontrolü
      final has410 = jsonResponse.containsKey('410');
      final has417 = jsonResponse.containsKey('417');
      
      if (has417) {
        // 417 status kod hata demektir
        return EmployerJobsResponse(
          error: true,
          success: false,
          status417: jsonResponse['417'],
          errorMessage: jsonResponse['417'] ?? 'Bilinmeyen hata',
        );
      }
      
      if (has410 || (!jsonResponse['error'] && jsonResponse['success'])) {
        // 410 status kod başarılı demektir
        return EmployerJobsResponse.fromJson(jsonResponse);
      } else {
        // Normal error handling
        return EmployerJobsResponse.fromJson(jsonResponse);
      }

    } catch (e, stackTrace) {
      logger.error('JSON parse hatası', error: e, stackTrace: stackTrace);
      return EmployerJobsResponse(
        error: true,
        success: false,
        errorMessage: 'Veri işleme hatası',
      );
    }
  }

  /// HTTP yanıtını EmployerApplicationsResponse'a çevirir
  EmployerApplicationsResponse _parseEmployerApplicationsResponse(http.Response response) {
    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      // Özel status kod kontrolü
      final has410 = jsonResponse.containsKey('410');
      final has417 = jsonResponse.containsKey('417');
      
      if (has417) {
        // 417 status kod hata demektir
        return EmployerApplicationsResponse(
          error: true,
          success: false,
          status417: jsonResponse['417'],
          errorMessage: jsonResponse['417'] ?? 'Bilinmeyen hata',
        );
      }
      
      if (has410 || (!jsonResponse['error'] && jsonResponse['success'])) {
        // 410 status kod başarılı demektir
        return EmployerApplicationsResponse.fromJson(jsonResponse);
      } else {
        // Normal error handling
        return EmployerApplicationsResponse.fromJson(jsonResponse);
      }

    } catch (e, stackTrace) {
      logger.error('JSON parse hatası', error: e, stackTrace: stackTrace);
      return EmployerApplicationsResponse(
        error: true,
        success: false,
        errorMessage: 'Veri işleme hatası',
      );
    }
  }

  /// HTTP yanıtını EmployerFavoriteApplicantsResponse'a çevirir
  EmployerFavoriteApplicantsResponse _parseEmployerFavoriteApplicantsResponse(http.Response response) {
    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      // Özel status kod kontrolü
      final has410 = jsonResponse.containsKey('410');
      final has417 = jsonResponse.containsKey('417');
      
      if (has417) {
        // 417 status kod hata demektir
        return EmployerFavoriteApplicantsResponse(
          error: true,
          success: false,
          status417: jsonResponse['417'],
          errorMessage: jsonResponse['417'] ?? 'Bilinmeyen hata',
        );
      }
      
      if (has410 || (!jsonResponse['error'] && jsonResponse['success'])) {
        // 410 status kod başarılı demektir
        return EmployerFavoriteApplicantsResponse.fromJson(jsonResponse);
      } else {
        // Normal error handling
        return EmployerFavoriteApplicantsResponse.fromJson(jsonResponse);
      }

    } catch (e, stackTrace) {
      logger.error('JSON parse hatası', error: e, stackTrace: stackTrace);
      return EmployerFavoriteApplicantsResponse(
        error: true,
        success: false,
        errorMessage: 'Veri işleme hatası',
      );
    }
  }

  /// HTTP yanıtını FavoriteApplicantResponse'a çevirir
  FavoriteApplicantResponse _parseFavoriteApplicantResponse(http.Response response) {
    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      // Özel status kod kontrolü
      final has410 = jsonResponse.containsKey('410');
      final has417 = jsonResponse.containsKey('417');
      
      if (has417) {
        // 417 status kod hata demektir
        return FavoriteApplicantResponse(
          error: true,
          success: false,
          status417: jsonResponse['417'],
          errorMessage: jsonResponse['417'] ?? 'Bilinmeyen hata',
        );
      }
      
      if (has410 || (!jsonResponse['error'] && jsonResponse['success'])) {
        // 410 status kod başarılı demektir
        return FavoriteApplicantResponse.fromJson(jsonResponse);
      } else {
        // Normal error handling
        return FavoriteApplicantResponse.fromJson(jsonResponse);
      }

    } catch (e, stackTrace) {
      logger.error('JSON parse hatası', error: e, stackTrace: stackTrace);
      return FavoriteApplicantResponse(
        error: true,
        success: false,
        errorMessage: 'Veri işleme hatası',
      );
    }
  }

  /// HTTP yanıtını ApplicationDetailUpdateResponse'a çevirir
  ApplicationDetailUpdateResponse _parseApplicationDetailUpdateResponse(http.Response response) {
    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      // Özel status kod kontrolü
      final has410 = jsonResponse.containsKey('410');
      final has417 = jsonResponse.containsKey('417');
      
      if (has417) {
        // 417 status kod hata demektir
        return ApplicationDetailUpdateResponse(
          error: true,
          success: false,
          status417: jsonResponse['417'],
          errorMessage: jsonResponse['417'] ?? 'Bilinmeyen hata',
        );
      }
      
      if (has410 || (!jsonResponse['error'] && jsonResponse['success'])) {
        // 410 status kod başarılı demektir
        return ApplicationDetailUpdateResponse.fromJson(jsonResponse);
      } else {
        // Normal error handling
        return ApplicationDetailUpdateResponse.fromJson(jsonResponse);
      }

    } catch (e, stackTrace) {
      logger.error('JSON parse hatası', error: e, stackTrace: stackTrace);
      return ApplicationDetailUpdateResponse(
        error: true,
        success: false,
        errorMessage: 'Veri işleme hatası',
      );
    }
  }

  /// Başvurular cache'ini temizler
  void _clearApplicationsCache() {
    _applicationsCache.clear();
    _applicationsCacheTimestamps.clear();
    logger.debug('Başvurular cache temizlendi');
  }

  /// Favori adaylar cache'ini temizler
  void _clearFavoriteApplicantsCache() {
    _favoriteApplicantsCache.clear();
    _favoriteApplicantsCacheTimestamps.clear();
    logger.debug('Favori adaylar cache temizlendi');
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

  /// Cache istatistiklerini döner (güncellenmiş versiyon)
  Map<String, dynamic> getCacheStats() {
    return {
      'jobsCacheSize': _jobsCache.length,
      'applicationsCacheSize': _applicationsCache.length,
      'favoriteApplicantsCacheSize': _favoriteApplicantsCache.length,
      'jobsCacheCapacity': 20,
      'applicationsCacheCapacity': 50,
      'favoriteApplicantsCacheCapacity': 20,
      'cacheExpirationMinutes': _cacheExpiration.inMinutes,
      'oldestJobsCacheEntry': _jobsCacheTimestamps.isEmpty 
          ? null 
          : _jobsCacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String(),
      'oldestApplicationsCacheEntry': _applicationsCacheTimestamps.isEmpty 
          ? null 
          : _applicationsCacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String(),
      'oldestFavoriteApplicantsCacheEntry': _favoriteApplicantsCacheTimestamps.isEmpty 
          ? null 
          : _favoriteApplicantsCacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String(),
    };
  }
} 