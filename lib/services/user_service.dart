import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/user_model.dart';
import '../models/auth_models.dart';
import 'auth_services.dart';
import 'logger_service.dart';

/// Kullanıcı verileri ve profili ile ilgili servisler
class UserService {
  static const String _baseUrl = 'https://api.rivorya.com/isport';
  static const String _getUserEndpoint = '/service/user/id';
  static const String _updateUserEndpoint = '/service/user/account/userUpdate';
  static const String _updatePasswordEndpoint = '/service/user/account/passwordUpdate';

  /// Platform bilgisini alır
  static String _getPlatform() {
    return Platform.isIOS ? 'ios' : 'android';
  }

  /// Uygulama versiyonunu alır
  static Future<String> _getVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      logger.debug('Package info alınamadı: $e');
      return '1.0.0';
    }
  }

  /// Kullanıcı verilerini API'den alır.
  /// 410 status başarılı, 417 status error mesajı gösterir
  Future<UserResponse> getUser({required String userToken}) async {
    try {
      final url = Uri.parse('$_baseUrl$_getUserEndpoint');
      final headers = AuthService.getHeaders(userToken: userToken);
      final version = await _getVersion();
      
      final body = jsonEncode({
        'userToken': userToken,
        'platform': _getPlatform(),
        'version': version,
      });

      logger.debug('Kullanıcı verisi isteniyor: $body');

      final response = await http.put(url, headers: headers, body: body);
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      logger.debug('Kullanıcı verisi yanıtı: ${response.statusCode} - ${response.body}');

      // Token hatası kontrolü
      if (response.statusCode == 403) {
        return UserResponse.fromJson(jsonData, isTokenError: true);
      }

      // Başarılı yanıt: 410 status başarılı demek
      if (response.statusCode == 410 || response.statusCode == 200) {
        return UserResponse.fromJson(jsonData);
      }

      // Error mesajı: 417 status
      if (response.statusCode == 417) {
        return UserResponse.fromJson(jsonData);
      }

      // Diğer hata durumları
      return UserResponse(
        error: true,
        success: false,
        error_message: 'API Hatası: ${response.statusCode}',
      );
      
    } catch (e, s) {
      logger.debug('Kullanıcı verisi alınırken hata', error: e, stackTrace: s);
      return UserResponse(
        error: true,
        success: false,
        error_message: 'Ağ Hatası: Lütfen internet bağlantınızı kontrol edin.',
      );
    }
  }

  /// Kullanıcı bilgilerini günceller.
  Future<GenericAuthResponse> updateUser(UpdateUserRequest request) async {
    try {
      final url = Uri.parse('$_baseUrl$_updateUserEndpoint');
      final headers = AuthService.getHeaders(userToken: request.userToken);
      final body = jsonEncode(request.toJson());

      logger.debug('Kullanıcı Güncelleme İsteği: $body');

      final response = await http.put(url, headers: headers, body: body);
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      
      logger.debug('Kullanıcı Güncelleme Yanıtı: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 403) {
        return GenericAuthResponse.fromJson(jsonData, isTokenError: true);
      }

      return GenericAuthResponse.fromJson(jsonData);
      
    } catch (e, s) {
      logger.debug('Kullanıcı güncellenirken hata', error: e, stackTrace: s);
      return GenericAuthResponse(
        error: true,
        success: false,
        error_message: 'Ağ Hatası: $e',
        validationErrors: const {},
      );
    }
  }

  /// Kullanıcı şifresini günceller.
  Future<GenericAuthResponse> updatePassword(UpdatePasswordRequest request) async {
     try {
      final url = Uri.parse('$_baseUrl$_updatePasswordEndpoint');
      final headers = AuthService.getHeaders(userToken: request.userToken);
      final body = jsonEncode(request.toJson());

      logger.debug('Şifre Güncelleme İsteği: $body');

      final response = await http.post(url, headers: headers, body: body);
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      logger.debug('Şifre Güncelleme Yanıtı: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 403) {
        return GenericAuthResponse.fromJson(jsonData, isTokenError: true);
      }

      return GenericAuthResponse.fromJson(jsonData);

    } catch (e, s) {
      logger.debug('Şifre güncellenirken hata', error: e, stackTrace: s);
      return GenericAuthResponse(
        error: true,
        success: false,
        message: 'Ağ Hatası: $e',
        error_message: 'Ağ Hatası: $e',
      );
    }
  }
} 