import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/applications_models.dart';
import '../models/user_model.dart';
import 'auth_services.dart';
import 'logger_service.dart';

/// Başvuru ve favori işlemleri ile ilgili servisler
class ApplicationsService {
  // API sabitleri - AuthService ile aynı base URL
  static const String _baseUrl = 'https://api.rivorya.com/isport';
  static const String _applicationsEndpointBase = '/service/user/account';
  static const String _jobApplicationsSuffix = '/jobApplications';
  static const String _jobFavoritesSuffix = '/jobFavorites';

  /// Kullanıcının başvurularını getirir
  Future<ApplicationsResponse> getApplications({required String? userToken, required int userID}) async {
    if (userToken == null || userToken.isEmpty) {
      return ApplicationsResponse(
        error: true,
        success: false,
        message410: 'Kullanıcı girişi yapılmamış.',
      );
    }

    try {
      final url = Uri.parse('$_baseUrl$_applicationsEndpointBase/$userID$_jobApplicationsSuffix');
      final headers = AuthService.getHeaders(userToken: userToken);

      logger.d('Başvuru Listesi İsteği: $url');

      final response = await http.get(
        url,
        headers: headers,
      );

      logger.d('Başvuru Listesi Yanıtı: ${response.statusCode} - ${response.body}');

      // Status code kontrolü mevcut mimariye uygun
      if (response.statusCode == 410) {
        // 410 = Başarılı
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return ApplicationsResponse.fromJson(jsonData);
      } else if (response.statusCode == 403) {
        // 403 = Token geçersiz, logout gerekli
        return ApplicationsResponse(
          error: true,
          success: false,
          message410: 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.',
        );
      } else if (response.statusCode == 401) {
        // 401 = Unauthorized
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return ApplicationsResponse.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        // 404 = Not Found
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return ApplicationsResponse.fromJson(jsonData);
      } else if (response.statusCode == 200) {
        // 200 = Hata mesajı (mevcut mimariye göre)
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return ApplicationsResponse.fromJson(jsonData);
      } else {
        return ApplicationsResponse(
          error: true,
          success: false,
          message410: 'API Hatası: ${response.statusCode}',
        );
      }
    } catch (e, s) {
      logger.e('Başvuru listesi getirilirken hata', error: e, stackTrace: s);
      return ApplicationsResponse(
        error: true,
        success: false,
        message410: 'Ağ Hatası: $e',
      );
    }
  }

  /// Kullanıcının favori ilanlarını getirir
  Future<FavoritesResponse> getFavorites({required String? userToken, required int userID}) async {
    if (userToken == null || userToken.isEmpty) {
      return FavoritesResponse(
        error: true,
        success: false,
        message410: 'Kullanıcı girişi yapılmamış.',
      );
    }

    try {
      final url = Uri.parse('$_baseUrl$_applicationsEndpointBase/$userID$_jobFavoritesSuffix');
      final headers = AuthService.getHeaders(userToken: userToken);

      logger.d('Favori Listesi İsteği: $url');

      final response = await http.get(
        url,
        headers: headers,
      );

      logger.d('Favori Listesi Yanıtı: ${response.statusCode} - ${response.body}');

      // Status code kontrolü mevcut mimariye uygun
      if (response.statusCode == 410) {
        // 410 = Başarılı
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return FavoritesResponse.fromJson(jsonData);
      } else if (response.statusCode == 403) {
        // 403 = Token geçersiz, logout gerekli
        return FavoritesResponse(
          error: true,
          success: false,
          message410: 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.',
        );
      } else if (response.statusCode == 401) {
        // 401 = Unauthorized
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return FavoritesResponse.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        // 404 = Not Found
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return FavoritesResponse.fromJson(jsonData);
      } else if (response.statusCode == 200) {
        // 200 = Hata mesajı (mevcut mimariye göre)
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return FavoritesResponse.fromJson(jsonData);
      } else {
        return FavoritesResponse(
          error: true,
          success: false,
          message410: 'API Hatası: ${response.statusCode}',
        );
      }
    } catch (e, s) {
      logger.e('Favori listesi getirilirken hata', error: e, stackTrace: s);
      return FavoritesResponse(
        error: true,
        success: false,
        message410: 'Ağ Hatası: $e',
      );
    }
  }
} 