import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;

import '../models/user_model.dart';
import '../models/auth_models.dart';
import 'auth_services.dart';
import 'logger_service.dart';

/// Kullanıcı bilgileri ile ilgili servisler
class UserService {
  // API sabitleri - AuthService ile aynı base URL
  static const String _baseUrl = 'https://api.rivorya.com/isport';
  static const String _userEndpoint = '/service/user/id';
  static const String _updateUserEndpoint = '/service/user/update/account';
  static const String _updatePasswordEndpoint = '/service/user/update/password';

  /// Kullanıcı bilgilerini getirir
  Future<UserResponse> getUser({required String? userToken}) async {
    if (userToken == null || userToken.isEmpty) {
      return UserResponse(
        error: true,
        success: false,
        message410: 'Kullanıcı girişi yapılmamış.',
      );
    }

    try {
      final url = Uri.parse('$_baseUrl$_userEndpoint');
      final headers = AuthService.getHeaders(userToken: userToken);
      final body = jsonEncode({
        'userToken': userToken,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'version': '1.0.0',
      });

      logger.d('Kullanıcı Bilgisi İsteği Gövdesi: $body');

      final response = await http.put(
        url,
        headers: headers,
        body: body,
      );

      logger.d('Kullanıcı Bilgisi Yanıtı: ${response.statusCode} - ${response.body}');

      // Status code kontrolü mevcut mimariye uygun
      if (response.statusCode == 410) {
        // 410 = Başarılı
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return UserResponse.fromJson(jsonData);
      } else if (response.statusCode == 403) {
        // 403 = Token geçersiz, logout gerekli
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final userResponse = UserResponse.fromJson(jsonData);
        // Logout işlemini tetiklemek için özel bir flag ekleyebiliriz
        return UserResponse(
          error: true,
          success: false,
          message410: 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.',
        );
      } else if (response.statusCode == 401) {
        // 401 = Unauthorized
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return UserResponse.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        // 404 = Not Found
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return UserResponse.fromJson(jsonData);
      } else if (response.statusCode == 200) {
        // 200 = Hata mesajı (mevcut mimariye göre)
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return UserResponse.fromJson(jsonData);
      } else {
        return UserResponse(
          error: true,
          success: false,
          message410: 'API Hatası: ${response.statusCode}',
        );
      }
    } catch (e, s) {
      logger.e('Kullanıcı bilgileri getirilirken hata', error: e, stackTrace: s);
      return UserResponse(
        error: true,
        success: false,
        message410: 'Ağ Hatası: $e',
      );
    }
  }

  /// Kullanıcı bilgilerini günceller
  Future<GenericAuthResponse> updateUser(UpdateUserRequest request) async {
    try {
      final url = Uri.parse('$_baseUrl$_updateUserEndpoint');
      final headers = AuthService.getHeaders(userToken: request.userToken);
      final body = jsonEncode(request.toJson());

      logger.d('Kullanıcı Güncelleme İsteği: $body');

      final response = await http.put(
        url,
        headers: headers,
        body: body,
      );

      logger.d('Kullanıcı Güncelleme Yanıtı: ${response.statusCode} - ${response.body}');
      
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return GenericAuthResponse.fromJson(jsonData);

    } catch (e, s) {
      logger.e('Kullanıcı güncellenirken hata', error: e, stackTrace: s);
      return GenericAuthResponse(
        error: true,
        success: false,
        message: 'Ağ Hatası: $e',
      );
    }
  }

  /// Kullanıcı şifresini günceller
  Future<GenericAuthResponse> updatePassword(UpdatePasswordRequest request) async {
    try {
      final url = Uri.parse('$_baseUrl$_updatePasswordEndpoint');
      final headers = AuthService.getHeaders(userToken: request.userToken);
      final body = jsonEncode(request.toJson());

      logger.d('Şifre Güncelleme İsteği gönderiliyor.');

      final response = await http.put(
        url,
        headers: headers,
        body: body,
      );

      logger.d('Şifre Güncelleme Yanıtı: ${response.statusCode} - ${response.body}');

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return GenericAuthResponse.fromJson(jsonData);

    } catch (e, s) {
      logger.e('Şifre güncellenirken hata', error: e, stackTrace: s);
      return GenericAuthResponse(
        error: true,
        success: false,
        message: 'Ağ Hatası: $e',
      );
    }
  }
} 