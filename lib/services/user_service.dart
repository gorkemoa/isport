import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/auth_models.dart';
import 'auth_services.dart';
import 'logger_service.dart';

/// Kullanıcı verileri ve profili ile ilgili servisler
class UserService {
  static const String _baseUrl = 'https://api.rivorya.com/isport';
  static const String _getUserEndpoint = '/service/user/account/getUser';
  static const String _updateUserEndpoint = '/service/user/account/userUpdate';
  static const String _updatePasswordEndpoint = '/service/user/account/passwordUpdate';

  /// Kullanıcı verilerini API'den alır.
  Future<UserResponse> getUser({required String userToken}) async {
    try {
      final url = Uri.parse('$_baseUrl$_getUserEndpoint');
      final headers = AuthService.getHeaders(userToken: userToken);
      final body = jsonEncode({'userToken': userToken});

      final response = await http.post(url, headers: headers, body: body);
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 403) {
        return UserResponse.fromJson(jsonData, isTokenError: true);
      }

      if (response.statusCode == 410 || response.statusCode == 200 || response.statusCode == 417) {
        return UserResponse.fromJson(jsonData);
      } else {
        return UserResponse(
          error: true,
          success: false,
          error_message: 'API Hatası: ${response.statusCode}',
        );
      }
    } catch (e, s) {
      logger.e('Kullanıcı verisi alınırken hata', error: e, stackTrace: s);
      return UserResponse(
        error: true,
        success: false,
        error_message: 'Ağ Hatası: $e',
      );
    }
  }

    
  /// Kullanıcı bilgilerini günceller.
  Future<GenericAuthResponse> updateUser(UpdateUserRequest request) async {
    try {
      final url = Uri.parse('$_baseUrl$_updateUserEndpoint');
      final headers = AuthService.getHeaders(userToken: request.userToken);
      final body = jsonEncode(request.toJson());

      logger.d('Kullanıcı Güncelleme İsteği: $body');

      final response = await http.post(url, headers: headers, body: body);
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      
      logger.d('Kullanıcı Güncelleme Yanıtı: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 403) {
        return GenericAuthResponse.fromJson(jsonData, isTokenError: true);
      }

      return GenericAuthResponse.fromJson(jsonData);
      
    } catch (e, s) {
      logger.e('Kullanıcı güncellenirken hata', error: e, stackTrace: s);
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

      logger.d('Şifre Güncelleme İsteği: $body');

      final response = await http.post(url, headers: headers, body: body);
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      logger.d('Şifre Güncelleme Yanıtı: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 403) {
        return GenericAuthResponse.fromJson(jsonData, isTokenError: true);
      }

      return GenericAuthResponse.fromJson(jsonData);

    } catch (e, s) {
      logger.e('Şifre güncellenirken hata', error: e, stackTrace: s);
      return GenericAuthResponse(
        error: true,
        success: false,
        message: 'Ağ Hatası: $e',
        error_message: 'Ağ Hatası: $e',
      );
    }
  }
} 