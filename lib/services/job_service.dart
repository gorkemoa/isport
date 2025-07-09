import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/job_models.dart';
import '../models/job_detail_models.dart';
import 'auth_services.dart';
import 'logger_service.dart';

/// İş ilanları ile ilgili servisler
class JobService {
  // API sabitleri
  static const String _baseUrl = 'https://api.rivorya.com/isport'; // AuthService ile aynı olmalı
  static const String _jobListEndpoint = '/service/user/company/jobListAll';
  static const String _jobDetailEndpointBase = '/service/user/company';
  static const String _favoriteAddEndpoint = '/service/user/account/jobFavoriteAdd';
  static const String _favoriteRemoveEndpoint = '/service/user/account/jobFavoriteRemove';

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