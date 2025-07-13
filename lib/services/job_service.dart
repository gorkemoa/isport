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

  /// Tüm iş ilanlarını getirir (yeni API endpoint)
  Future<JobListResponse> fetchAllJobListings({
    int? catID,
    List<int>? workTypes,
    int? cityID,
    int? districtID,
    String? publishDate,
    String? sort,
    String? latitude,
    String? longitude,
    int page = 1,
  }) async {
    try {
      logger.debug('Tüm iş ilanları getiriliyor - Sayfa: $page');
      
      // Kullanıcı token'ını al
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken');
      
      // API isteği parametrelerini hazırla
      final requestData = JobListRequest(
        userToken: userToken,
        catID: catID,
        workTypes: workTypes,
        cityID: cityID,
        districtID: districtID,
        publishDate: publishDate,
        sort: sort,
        latitude: latitude,
        longitude: longitude,
        page: page,
      );

      // API isteği hazırla
      final uri = Uri.parse('$_baseUrl$_companyJobsEndpoint/jobListAll');
      final headers = AuthService.getHeaders();
      final body = jsonEncode(requestData.toJson());

      logger.debug('API isteği gönderiliyor: ${uri.toString()}');
      logger.debug('Request body: $body');

      // HTTP POST isteği gönder
      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      ).timeout(_connectTimeout);

      logger.debug('API yanıtı alındı - Status: ${response.statusCode}');

      // Yanıtı parse et
      return _parseJobListResponse(response);

    } catch (e) {
      logger.error('Tüm iş ilanları getirme hatası: $e');
      return JobListResponse(
        error: true,
        success: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// HTTP yanıtını JobListResponse'a çevirir
  JobListResponse _parseJobListResponse(http.Response response) {
    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      // Özel status kod kontrolü
      final has410 = jsonResponse.containsKey('410');
      final has417 = jsonResponse.containsKey('417');
      
      if (has417) {
        // 417 status kod hata demektir
        return JobListResponse(
          error: true,
          success: false,
          status417: jsonResponse['417'],
          errorMessage: jsonResponse['417'] ?? 'Bilinmeyen hata',
        );
      }
      
      if (has410 || (!jsonResponse['error'] && jsonResponse['success'])) {
        // 410 status kod başarılı demektir
        return JobListResponse.fromJson(jsonResponse);
      } else {
        // Normal error handling
        return JobListResponse.fromJson(jsonResponse);
      }

    } catch (e) {
      logger.error('JSON parse hatası: $e');
      return JobListResponse(
        error: true,
        success: false,
        errorMessage: 'Veri işleme hatası',
      );
    }
  }

  /// Tüm iş ilanlarını getirir (genel listing) - Eski metod, geriye uyumluluk için
  Future<List<JobListingResponse>> fetchAllJobs({int? limit, int? offset}) async {
    try {
      logger.debug('Tüm iş ilanları getiriliyor (eski metod)');
      
      // Yeni API endpoint'ini kullan
      final response = await fetchAllJobListings();
      
      if (response.isSuccessful && response.data != null) {
        // Yeni formatı eski formata çevir
        final List<JobListingResponse> convertedResponses = [];
        
        // JobListItem'ları şirket bazında grupla
        final Map<int, List<JobListItem>> companyGroups = {};
        
        for (final job in response.data!.jobs) {
          if (!companyGroups.containsKey(job.compID)) {
            companyGroups[job.compID] = [];
          }
          companyGroups[job.compID]!.add(job);
        }
        
        // Her şirket için JobListingResponse oluştur
        for (final entry in companyGroups.entries) {
          final companyId = entry.key;
          final jobs = entry.value;
          
          if (jobs.isNotEmpty) {
            // Şirket bilgilerini ilk iş ilanından al
            final firstJob = jobs.first;
            
            // CompanyDetailModel oluştur
            final company = CompanyDetailModel(
              compID: firstJob.compID,
              compName: firstJob.compName,
              compDesc: '',
              compAddress: '',
              compCity: firstJob.jobCity,
              compDistrict: firstJob.jobDistrict ?? '',
              profilePhoto: firstJob.jobImage,
            );
            
            // JobModel listesi oluştur
            final jobModels = jobs.map((job) => JobModel(
              jobID: job.jobID,
              jobTitle: job.jobTitle,
              workType: job.workType,
              showDate: job.showDate,
            )).toList();
            
            // JobListingData oluştur
            final listingData = JobListingData(
              company: company,
              jobs: jobModels,
            );
            
            // JobListingResponse oluştur
            final listingResponse = JobListingResponse(
              error: false,
              success: true,
              data: listingData,
              errorMessage: '',
            );
            
            convertedResponses.add(listingResponse);
          }
        }
        
        return convertedResponses;
      } else {
        return [];
      }

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
  /// [appNote] - Başvuru notu
  Future<ApplyJobResponse> applyToJob(int jobId, String appNote) async {
    try {
      logger.debug('İşe başvuru yapılıyor - İş ID: $jobId');

      // Kullanıcı token'ını al
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken') ?? '';

      if (userToken.isEmpty) {
        logger.warning('User token bulunamadı');
        return ApplyJobResponse(
          error: true,
          success: false,
          successMessage: '',
          errorMessage: 'Oturum açmanız gerekiyor',
          isTokenError: true,
        );
      }

      // API isteği hazırla
      final uri = Uri.parse('$_baseUrl/service/user/account/jobApply');
      final headers = AuthService.getHeaders();

      // Request body hazırla
      final requestBody = ApplyJobRequest(
        userToken: userToken,
        jobID: jobId,
        appNote: appNote,
      );

      logger.debug('API isteği gönderiliyor: ${uri.toString()}');
      logger.debug('Request body: ${jsonEncode(requestBody.toJson())}');

      // HTTP isteği gönder
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(requestBody.toJson()),
      ).timeout(_connectTimeout);

      logger.debug('API yanıtı alındı - Status: ${response.statusCode}');

      // Yanıtı parse et
      return _parseApplyJobResponse(response);

    } catch (e) {
      logger.error('İşe başvuru hatası: $e');
      return ApplyJobResponse(
        error: true,
        success: false,
        successMessage: '',
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// HTTP yanıtını ApplyJobResponse'a çevirir
  ApplyJobResponse _parseApplyJobResponse(http.Response response) {
    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      // Özel status kod kontrolü
      final has410 = jsonResponse.containsKey('410');
      final has417 = jsonResponse.containsKey('417');
      
      if (has417) {
        // 417 status kod hata demektir
        return ApplyJobResponse(
          error: true,
          success: false,
          successMessage: '',
          status417: jsonResponse['417'],
          errorMessage: jsonResponse['417'] ?? 'Bilinmeyen hata',
        );
      }
      
      if (has410 || (!jsonResponse['error'] && jsonResponse['success'])) {
        // 410 status kod başarılı demektir
        return ApplyJobResponse.fromJson(jsonResponse);
      } else {
        // Normal error handling
        return ApplyJobResponse.fromJson(jsonResponse);
      }

    } catch (e) {
      logger.error('JSON parse hatası: $e');
      return ApplyJobResponse(
        error: true,
        success: false,
        successMessage: '',
        errorMessage: 'Veri işleme hatası',
      );
    }
  }

  /// Yeni iş ilanı ekler
  /// [companyId] - Şirket ID'si
  /// [request] - İş ilanı ekleme request'i
  Future<JobOperationResponse> addJob(int companyId, AddJobRequest request) async {
    try {
      logger.debug('Yeni iş ilanı ekleniyor - Şirket ID: $companyId');

      // API isteği hazırla
      final uri = Uri.parse('$_baseUrl/service/user/company/$companyId/addJob');
      final headers = AuthService.getHeaders(userToken: request.userToken);

      logger.debug('API isteği gönderiliyor: ${uri.toString()}');
      logger.debug('Request body: ${jsonEncode(request.toJson())}');

      // HTTP isteği gönder
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(request.toJson()),
      ).timeout(_connectTimeout);

      logger.debug('API yanıtı alındı - Status: ${response.statusCode}');

      // Token hatası kontrolü
      if (response.statusCode == 403) {
        return JobOperationResponse.fromJson(jsonDecode(response.body), isTokenError: true);
      }

      // Yanıtı parse et
      return _parseJobOperationResponse(response);

    } catch (e) {
      logger.error('İş ilanı ekleme hatası: $e');
      return JobOperationResponse(
        error: true,
        success: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// İş ilanını günceller
  /// [companyId] - Şirket ID'si
  /// [request] - İş ilanı güncelleme request'i
  Future<JobOperationResponse> updateJob(int companyId, UpdateJobRequest request) async {
    try {
      logger.debug('İş ilanı güncelleniyor - Şirket ID: $companyId, İş ID: ${request.jobID}');

      // API isteği hazırla
      final uri = Uri.parse('$_baseUrl/service/user/company/$companyId/updateJob');
      final headers = AuthService.getHeaders(userToken: request.userToken);

      logger.debug('API isteği gönderiliyor: ${uri.toString()}');
      logger.debug('Request body: ${jsonEncode(request.toJson())}');

      // HTTP isteği gönder
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(request.toJson()),
      ).timeout(_connectTimeout);

      logger.debug('API yanıtı alındı - Status: ${response.statusCode}');

      // Token hatası kontrolü
      if (response.statusCode == 403) {
        return JobOperationResponse.fromJson(jsonDecode(response.body), isTokenError: true);
      }

      // Yanıtı parse et
      return _parseJobOperationResponse(response);

    } catch (e) {
      logger.error('İş ilanı güncelleme hatası: $e');
      return JobOperationResponse(
        error: true,
        success: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// HTTP yanıtını JobOperationResponse'a çevirir
  JobOperationResponse _parseJobOperationResponse(http.Response response) {
    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      // Özel status kod kontrolü
      final has410 = jsonResponse.containsKey('410');
      final has417 = jsonResponse.containsKey('417');
      
      if (has417) {
        // 417 status kod hata demektir
        return JobOperationResponse(
          error: true,
          success: false,
          status417: jsonResponse['417'],
          errorMessage: jsonResponse['417'] ?? 'Bilinmeyen hata',
        );
      }
      
      if (has410 || (!jsonResponse['error'] && jsonResponse['success'])) {
        // 410 status kod başarılı demektir
        return JobOperationResponse.fromJson(jsonResponse);
      } else {
        // Normal error handling
        return JobOperationResponse.fromJson(jsonResponse);
      }

    } catch (e) {
      logger.error('JSON parse hatası: $e');
      return JobOperationResponse(
        error: true,
        success: false,
        errorMessage: 'Veri işleme hatası',
      );
    }
  }
} 