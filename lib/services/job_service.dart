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
} 