import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/job_detail_models.dart';
import '../models/job_models.dart';
import '../models/company_job_models.dart';
import '../models/company_applications_models.dart';
import 'auth_services.dart';
export '../models/job_detail_models.dart' show ApplyJobRequest;
import 'logger_service.dart';

/// İş ilanları ile ilgili servisler
class JobService {
  // API sabitleri
  static const String _baseUrl = 'https://api.rivorya.com/isport'; // AuthService ile aynı olmalı
  static const String _jobListEndpoint = '/service/user/company/jobListAll';
  static const String _jobDetailEndpointBase = '/service/user/company';
  static const String _favoriteAddEndpoint = '/service/user/account/jobFavoriteAdd';
  static const String _favoriteRemoveEndpoint = '/service/user/account/jobFavoriteRemove';
  static const String _jobApplyEndpoint = '/service/user/account/jobApply';
  static const String _companyJobsEndpoint = '/service/user/company';
  static const String _companyApplicationsEndpoint = '/service/user/company';
  static const String _favoriteApplicantsEndpoint = '/service/user/company';
  static const String _favoriteApplicantToggleEndpoint = '/service/user/company/favoriteApplicant';

  /// İş ilanlarını getirir
  Future<JobListResponse> getJobList(JobListRequest request) async {
    try {
      final url = Uri.parse('$_baseUrl$_jobListEndpoint');
      final headers = AuthService.getHeaders(userToken: request.userToken);
      final body = jsonEncode(request.toJson());

      logger.d('İş İlanı İsteği Gövdesi: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      
      logger.d('İş İlanı Yanıtı: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 410) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return JobListResponse.fromJson(jsonData);
      } else {
        return JobListResponse(
          error: true,
          success: false,
          message410: 'API Hatası: ${response.statusCode}',
        );
      }
    } catch (e, s) {
      logger.e('İş ilanları getirilirken hata', error: e, stackTrace: s);
      return JobListResponse(
        error: true,
        success: false,
        message410: 'Ağ Hatası: $e',
      );
    }
  }

  /// İlan detayını getirir
  Future<JobDetailResponse> getJobDetail({required int jobId, String? userToken}) async {
    try {
      final query = userToken != null ? '?userToken=$userToken' : '';
      final url = Uri.parse('$_baseUrl$_jobDetailEndpointBase/$jobId/jobDetail$query');
      final headers = AuthService.getHeaders(userToken: userToken);

      final response = await http.get(url, headers: headers);

      logger.d('İş Detay Yanıtı: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 410) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return JobDetailResponse.fromJson(jsonData);
      }

      return JobDetailResponse(
        error: true,
        success: false,
        message410: 'API Hatası: ${response.statusCode}',
      );
    } catch (e, s) {
      logger.e('İş detay getirilirken hata', error: e, stackTrace: s);
      return JobDetailResponse(
        error: true,
        success: false,
        message410: 'Ağ Hatası: $e',
      );
    }
  }

  /// İlanı favorilere ekler
  Future<FavoriteResponse> addJobToFavorites({required String userToken, required int jobID}) async {
    try {
      final url = Uri.parse('$_baseUrl$_favoriteAddEndpoint');
      final headers = AuthService.getHeaders(userToken: userToken);
      final body = jsonEncode({
        'userToken': userToken,
        'jobID': jobID,
      });

      logger.d('Favori Ekleme İsteği: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      logger.d('Favori Ekleme Yanıtı: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 410) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return FavoriteResponse.fromJson(jsonData);
      } else {
        return FavoriteResponse(
          error: true,
          success: false,
          message: 'API Hatası: ${response.statusCode}',
        );
      }
    } catch (e, s) {
      logger.e('Favori eklenirken hata', error: e, stackTrace: s);
      return FavoriteResponse(
        error: true,
        success: false,
        message: 'Ağ Hatası: $e',
      );
    }
  }

  /// İlanı favorilerden kaldırır
  Future<FavoriteResponse> removeJobFromFavorites({required String userToken, required int jobID}) async {
    try {
      final url = Uri.parse('$_baseUrl$_favoriteRemoveEndpoint');
      final headers = AuthService.getHeaders(userToken: userToken);
      final body = jsonEncode({
        'userToken': userToken,
        'jobID': jobID,
      });

      logger.d('Favori Kaldırma İsteği: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      logger.d('Favori Kaldırma Yanıtı: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 410) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return FavoriteResponse.fromJson(jsonData);
      } else {
        return FavoriteResponse(
          error: true,
          success: false,
          message: 'API Hatası: ${response.statusCode}',
        );
      }
    } catch (e, s) {
      logger.e('Favori kaldırılırken hata', error: e, stackTrace: s);
      return FavoriteResponse(
        error: true,
        success: false,
        message: 'Ağ Hatası: $e',
      );
    }
  }

  /// İlana başvuru yapar
  Future<ApplyJobResponse> applyToJob(ApplyJobRequest request) async {
    try {
      final url = Uri.parse('$_baseUrl$_jobApplyEndpoint');
      final headers = AuthService.getHeaders(userToken: request.userToken);
      final body = jsonEncode(request.toJson());

      logger.d('İlana Başvuru İsteği: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      logger.d('İlana Başvuru Yanıtı: ${response.statusCode} - ${response.body}');
      
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return ApplyJobResponse.fromJson(jsonData);

    } catch (e, s) {
      logger.e('İlana başvuru yapılırken hata', error: e, stackTrace: s);
      return ApplyJobResponse(
        error: true,
        success: false,
        successMessage: 'Ağ Hatası: $e',
      );
    }
  }

  /// Şirket iş ilanlarını getirir
  Future<CompanyJobsResponse> getCompanyJobs({required int companyId, String? userToken}) async {
    try {
      final url = Uri.parse('$_baseUrl$_companyJobsEndpoint/$companyId/companyJobList');
      final headers = AuthService.getHeaders(userToken: userToken);

      logger.d('Şirket İlanları İsteği: $url');

      final response = await http.get(url, headers: headers);

      logger.d('Şirket İlanları Yanıtı: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 410) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return CompanyJobsResponse.fromJson(jsonData);
      } else {
        return CompanyJobsResponse(
          error: true,
          success: false,
          message410: 'API Hatası: ${response.statusCode}',
        );
      }
    } catch (e, s) {
      logger.e('Şirket ilanları getirilirken hata', error: e, stackTrace: s);
      return CompanyJobsResponse(
        error: true,
        success: false,
        message410: 'Ağ Hatası: $e',
      );
    }
  }

  /// Şirket başvurularını getirir
  Future<CompanyApplicationsResponse> getCompanyApplications({
    required int companyId, 
    String? userToken,
    int? jobID,
  }) async {
    try {
      final queryParams = jobID != null ? '?jobID=$jobID' : '';
      final url = Uri.parse('$_baseUrl$_companyApplicationsEndpoint/$companyId/jobApplications$queryParams');
      final headers = AuthService.getHeaders(userToken: userToken);

      logger.d('Şirket Başvuruları İsteği: $url');

      final response = await http.get(url, headers: headers);

      logger.d('Şirket Başvuruları Yanıtı: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 410) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return CompanyApplicationsResponse.fromJson(jsonData);
      } else {
        return CompanyApplicationsResponse(
          error: true,
          success: false,
          message410: 'API Hatası: ${response.statusCode}',
        );
      }
    } catch (e, s) {
      logger.e('Şirket başvuruları getirilirken hata', error: e, stackTrace: s);
      return CompanyApplicationsResponse(
        error: true,
        success: false,
        message410: 'Ağ Hatası: $e',
      );
    }
  }

  /// Favori adayları getirir
  Future<FavoriteApplicantsResponse> getFavoriteApplicants({
    required int companyId,
    String? userToken,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$_favoriteApplicantsEndpoint/$companyId/favoriteApplicants');
      final headers = AuthService.getHeaders(userToken: userToken);

      logger.d('Favori Adaylar İsteği: $url');

      final response = await http.get(url, headers: headers);

      logger.d('Favori Adaylar Yanıtı: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 410) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return FavoriteApplicantsResponse.fromJson(jsonData);
      } else {
        return FavoriteApplicantsResponse(
          error: true,
          success: false,
          message410: 'API Hatası: ${response.statusCode}',
        );
      }
    } catch (e, s) {
      logger.e('Favori adaylar getirilirken hata', error: e, stackTrace: s);
      return FavoriteApplicantsResponse(
        error: true,
        success: false,
        message410: 'Ağ Hatası: $e',
      );
    }
  }

  /// Favori aday ekleme/silme toggle
  Future<FavoriteApplicantResponse> toggleFavoriteApplicant(FavoriteApplicantRequest request) async {
    try {
      final url = Uri.parse('$_baseUrl$_favoriteApplicantToggleEndpoint');
      final headers = AuthService.getHeaders(userToken: request.userToken);
      final body = jsonEncode(request.toJson());

      logger.d('Favori Aday Toggle İsteği: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      logger.d('Favori Aday Toggle Yanıtı: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 410) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return FavoriteApplicantResponse.fromJson(jsonData);
      } else {
        return FavoriteApplicantResponse(
          error: true,
          success: false,
          message410: 'API Hatası: ${response.statusCode}',
        );
      }
    } catch (e, s) {
      logger.e('Favori aday toggle işleminde hata', error: e, stackTrace: s);
      return FavoriteApplicantResponse(
        error: true,
        success: false,
        message410: 'Ağ Hatası: $e',
      );
    }
  }
}

/// Favori ekleme/kaldırma API yanıtı için model
class FavoriteResponse {
  final bool error;
  final bool success;
  final String? message;
  final String? gone410;

  FavoriteResponse({
    required this.error,
    required this.success,
    this.message,
    this.gone410,
  });

  factory FavoriteResponse.fromJson(Map<String, dynamic> json) {
    return FavoriteResponse(
      error: json['error'] ?? false,
      success: json['success'] ?? false,
      message: json['data']?['message'],
      gone410: json['410'],
    );
  }
} 