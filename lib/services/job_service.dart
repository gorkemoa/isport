import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job_models.dart';
import '../models/auth_models.dart';
import 'auth_services.dart';
import 'logger_service.dart';

/// İş ilanları ile ilgili API servis işlemleri
class JobService {
  static const String _baseUrl = 'https://api.rivorya.com/isport';
  static const String _companyJobsEndpoint = '/service/user/account';

  /// Timeout süreleri
  static const Duration _connectTimeout = Duration(seconds: 10);
  static const Duration _receiveTimeout = Duration(seconds: 15);

  /// İş detayını getirir
  /// [jobId] - İş ID'si
  /// Returns JobDetailResponse with status code handling (410 = success, 417 = error)
  Future<JobDetailResponse> fetchJobDetail(int jobId) async {
    try {
      logger.debug('İş detayı getiriliyor - İş ID: $jobId');
      
      // Kullanıcı token'ını al
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken') ?? '';
      
      if (userToken.isEmpty) {
        logger.warning('User token bulunamadı');
        return JobDetailResponse(
          error: true,
          success: false,
          errorMessage: 'Oturum açmanız gerekiyor',
          isTokenError: true,
        );
      }

      // API isteği hazırla
      final uri = Uri.parse('$_baseUrl$_companyJobsEndpoint/$jobId/jobDetail')
          .replace(queryParameters: {'userToken': userToken});
      final headers = AuthService.getHeaders();

      logger.debug('API isteği gönderiliyor: ${uri.toString()}');

      // HTTP isteği gönder
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(_connectTimeout);

      logger.debug('API yanıtı alındı - Status: ${response.statusCode}');

      // Yanıtı parse et
      return _parseJobDetailResponse(response);

    } catch (e) {
      logger.error('İş detayı getirme hatası: $e');
      return JobDetailResponse(
        error: true,
        success: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Şirket bazlı iş ilanlarını getirir
  /// [companyId] - Şirket ID'si
  /// Returns JobListingResponse with status code handling (410 = success, 417 = error)
  Future<JobListingResponse> fetchCompanyJobs(int companyId) async {
    try {
      logger.debug('İş ilanları getiriliyor - Şirket ID: $companyId');
      
      // Kullanıcı token'ını al
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken') ?? '';
      
      if (userToken.isEmpty) {
        logger.warning('User token bulunamadı');
        return JobListingResponse(
          error: true,
          success: false,
          errorMessage: 'Oturum açmanız gerekiyor',
          isTokenError: true,
        );
      }

      // API isteği hazırla
      final uri = Uri.parse('$_baseUrl$_companyJobsEndpoint/$companyId/companyDetail');
      final headers = AuthService.getHeaders(userToken: userToken);

      logger.debug('API isteği gönderiliyor: ${uri.toString()}');

      // HTTP isteği gönder
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(_connectTimeout);

      logger.debug('API yanıtı alındı - Status: ${response.statusCode}');

      // Yanıtı parse et
      return _parseJobListingResponse(response);

    } catch (e) {
      logger.error('İş ilanları getirme hatası: $e');
      return JobListingResponse(
        error: true,
        success: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Mevcut kullanıcının şirketinin iş ilanlarını getirir
  Future<JobListingResponse> fetchCurrentUserCompanyJobs() async {
    try {
      logger.debug('Mevcut kullanıcının şirket iş ilanları getiriliyor');
      
      // Kullanıcı bilgilerini al
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString == null) {
        return JobListingResponse(
          error: true,
          success: false,
          errorMessage: 'Kullanıcı bilgileri bulunamadı',
          isTokenError: true,
        );
      }

      final userData = jsonDecode(userDataString);
      final user = User.fromJson(userData);
      
      if (!user.isComp) {
        return JobListingResponse(
          error: true,
          success: false,
          errorMessage: 'Sadece şirket hesapları iş ilanlarını görüntüleyebilir',
        );
      }

      // Kullanıcının şirket ID'sini kullan (örnek: userID'yi kullanıyoruz)
      return await fetchCompanyJobs(user.userID);

    } catch (e) {
      logger.error('Mevcut kullanıcı şirket iş ilanları getirme hatası: $e');
      return JobListingResponse(
        error: true,
        success: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Tüm iş ilanlarını getirir (genel listing)
  Future<List<JobListingResponse>> fetchAllJobs({int? limit, int? offset}) async {
    try {
      logger.debug('Tüm iş ilanları getiriliyor');
      
      // Örnek şirket ID'leri - gerçek implementasyonda API'den gelecek
      const exampleCompanyIds = [1, 2, 3, 4, 5];
      final List<JobListingResponse> allJobs = [];

      for (final companyId in exampleCompanyIds) {
        final response = await fetchCompanyJobs(companyId);
        if (response.isSuccessful && response.data != null) {
          allJobs.add(response);
        }
      }

      return allJobs;

    } catch (e) {
      logger.error('Tüm iş ilanları getirme hatası: $e');
      return [];
    }
  }

  /// HTTP yanıtını JobListingResponse'a çevirir
  JobListingResponse _parseJobListingResponse(http.Response response) {
    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      // Özel status kod kontrolü
      final has410 = jsonResponse.containsKey('410');
      final has417 = jsonResponse.containsKey('417');
      
      if (has417) {
        // 417 status kod hata demektir
        return JobListingResponse(
          error: true,
          success: false,
          status417: jsonResponse['417'],
          errorMessage: jsonResponse['417'] ?? 'Bilinmeyen hata',
        );
      }
      
      if (has410 || (!jsonResponse['error'] && jsonResponse['success'])) {
        // 410 status kod başarılı demektir
        return JobListingResponse.fromJson(jsonResponse);
      } else {
        // Normal error handling
        return JobListingResponse.fromJson(jsonResponse);
      }

    } catch (e) {
      logger.error('JSON parse hatası: $e');
      return JobListingResponse(
        error: true,
        success: false,
        errorMessage: 'Veri işleme hatası',
      );
    }
  }

  /// HTTP yanıtını JobDetailResponse'a çevirir
  JobDetailResponse _parseJobDetailResponse(http.Response response) {
    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      // Özel status kod kontrolü
      final has410 = jsonResponse.containsKey('410');
      final has417 = jsonResponse.containsKey('417');
      
      if (has417) {
        // 417 status kod hata demektir
        return JobDetailResponse(
          error: true,
          success: false,
          status417: jsonResponse['417'],
          errorMessage: jsonResponse['417'] ?? 'Bilinmeyen hata',
        );
      }
      
      if (has410 || (!jsonResponse['error'] && jsonResponse['success'])) {
        // 410 status kod başarılı demektir
        return JobDetailResponse.fromJson(jsonResponse);
      } else {
        // Normal error handling
        return JobDetailResponse.fromJson(jsonResponse);
      }

    } catch (e) {
      logger.error('JSON parse hatası: $e');
      return JobDetailResponse(
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

  /// Bir işe başvuru yapar
  /// [jobId] - İş ID'si
  Future<BaseResponse> applyToJob(int jobId) async {
    try {
      logger.debug('İşe başvuru yapılıyor - İş ID: $jobId');

      // Kullanıcı token'ını al
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken') ?? '';

      if (userToken.isEmpty) {
        logger.warning('User token bulunamadı');
        return BaseResponse(
          error: true,
          success: false,
          errorMessage: 'Oturum açmanız gerekiyor',
          isTokenError: true,
        );
      }

      // API isteği hazırla
      final uri = Uri.parse('$_baseUrl$_companyJobsEndpoint/$jobId/apply');
      final headers = AuthService.getHeaders(userToken: userToken);

      logger.debug('API isteği gönderiliyor: ${uri.toString()}');

      // HTTP isteği gönder
      final response = await http.post(
        uri,
        headers: headers,
      ).timeout(_connectTimeout);

      logger.debug('API yanıtı alındı - Status: ${response.statusCode}');
      
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      // Yanıtı parse et
      return BaseResponse.fromJson(jsonResponse);

    } catch (e) {
      logger.error('İşe başvuru hatası: $e');
      return BaseResponse(
        error: true,
        success: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }
} 