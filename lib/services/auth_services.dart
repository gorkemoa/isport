import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';
import 'logger_service.dart';

/// Authentication servisleri
class AuthService {
  // API sabitleri
  static const String _baseUrl = 'https://api.rivorya.com/isport';
  static const String _loginEndpoint = '/service/auth/login';
  static const String _registerEndpoint = '/service/auth/register';
  static const String _forgotPasswordEndpoint = '/service/auth/forgotPassword';
  static const String _checkCodeEndpoint = '/service/auth/code/checkCode';
  static const String _resetPasswordEndpoint = '/service/auth/code/resetPassword';
  
  // Basic Auth sabitleri
  static const String _basicAuthUsername = 'Tr2BUhR2ICWHJN2nlvp9T5ycBoyMJD';
  static const String _basicAuthPassword = 'vRP4rTBAqm1tm2I17I1EI6PHFBEdl0';
  
  // SharedPreferences anahtarları
  static const String _userDataKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _userEmailKey = 'user_email';
  static const String _userTokenKeyLegacy = 'userToken';

  /// Basic Auth header'ını oluşturur
  static String _getBasicAuthHeader() {
    String credentials = '$_basicAuthUsername:$_basicAuthPassword';
    String encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $encoded';
  }

  /// HTTP headers'ını oluşturur (public static)
  static Map<String, String> getHeaders({String? userToken}) {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': _getBasicAuthHeader(),
    };
    
    // Eğer kullanıcı token'ı varsa ekle
    if (userToken != null && userToken.isNotEmpty) {
      headers['User-Token'] = userToken;
    }
    
    return headers;
  }

  /// Kullanıcı girişi yapar
  Future<LoginResponse> login(LoginRequest loginRequest) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final url = Uri.parse('$_baseUrl$_loginEndpoint');
      final headers = getHeaders();
      final body = jsonEncode(loginRequest.toJson());

      logger.info('Kullanıcı girişi başlatıldı', extra: {'email': loginRequest.userEmail});

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      
      stopwatch.stop();
      
      // Network request'i logla
      logger.logNetworkRequest(
        method: 'POST',
        url: url.toString(),
        statusCode: response.statusCode,
        duration: stopwatch.elapsed,
      );
      
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 403) {
        logger.warning('Token hatası - Giriş reddedildi', extra: {'statusCode': response.statusCode});
        return LoginResponse.fromJson(jsonData, isTokenError: true);
      }
      
      if (response.statusCode == 410 || response.statusCode == 417 || response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(jsonData);
        
        // Başarılı giriş durumunda kullanıcı verilerini kaydet
        if (loginResponse.success && loginResponse.data != null) {
          logger.info('Giriş başarılı - Kullanıcı verileri kaydediliyor', 
                     extra: {'userID': loginResponse.data!.userID});
          await _saveUserData(loginRequest.userEmail, loginResponse.data!);
          logger.logUserAction('login_success', parameters: {'userID': loginResponse.data!.userID});
        } else {
          logger.warning('Giriş başarısız', extra: {'errorMessage': loginResponse.error_message});
        }
        
        return loginResponse;
      } else {
        logger.error('HTTP Error', extra: {'statusCode': response.statusCode, 'body': response.body});
        return LoginResponse(
          error: true,
          success: false,
          error_message: 'HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      logger.error('Giriş sırasında network hatası', 
                   error: e, stackTrace: stackTrace, 
                   extra: {'email': loginRequest.userEmail, 'duration': stopwatch.elapsed.inMilliseconds});
      return LoginResponse(
        error: true,
        success: false,
        error_message: 'Network Error: $e',
      );
    }
  }

  /// Kullanıcı kaydı yapar
  Future<RegisterResponse> register(RegisterRequest registerRequest) async {
    try {
      final url = Uri.parse('$_baseUrl$_registerEndpoint');
      final headers = getHeaders();
      final body = jsonEncode(registerRequest.toJson());

      logger.debug('Kayıt İsteği', extra: {'body': body});

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      logger.debug('Kayıt Yanıtı', extra: {'statusCode': response.statusCode, 'body': response.body});
      
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 403) {
        return RegisterResponse.fromJson(jsonData, isTokenError: true);
      }

      if (response.statusCode == 410 || response.statusCode == 200 || response.statusCode == 417) {
        final registerResponse = RegisterResponse.fromJson(jsonData);
        return registerResponse;
      } else {
        return RegisterResponse(
          error: true,
          success: false,
          error_message: 'HTTP Hatası: ${response.statusCode}',
        );
      }
    } catch (e) {
      return RegisterResponse(
        error: true,
        success: false,
        error_message: 'Ağ Hatası: $e',
      );
    }
  }

  /// Şifre sıfırlama maili gönderir
  Future<ForgotPasswordResponse> forgotPassword(ForgotPasswordRequest request) async {
    try {
      final url = Uri.parse('$_baseUrl$_forgotPasswordEndpoint');
      final headers = getHeaders();
      final body = jsonEncode(request.toJson());

      logger.debug('Şifremi Unuttum İsteği', extra: {'body': body});
      final response = await http.post(url, headers: headers, body: body);
      logger.debug('Şifremi Unuttum Yanıtı', extra: {'statusCode': response.statusCode, 'body': response.body});

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 403) {
        return ForgotPasswordResponse.fromJson(jsonData, isTokenError: true);
      }
      return ForgotPasswordResponse.fromJson(jsonData);

    } catch (e) {
      return ForgotPasswordResponse(
        error: true,
        success: false,
        error_message: 'Ağ Hatası: $e',
      );
    }
  }

  /// Doğrulama kodunu kontrol eder
  Future<GenericAuthResponse> checkCode(CheckCodeRequest request) async {
    try {
      final url = Uri.parse('$_baseUrl$_checkCodeEndpoint');
      final headers = getHeaders();
      final body = jsonEncode(request.toJson());

      logger.debug('Kod Kontrol İsteği', extra: {'body': body});
      final response = await http.post(url, headers: headers, body: body);
      logger.debug('Kod Kontrol Yanıtı', extra: {'statusCode': response.statusCode, 'body': response.body});

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 403) {
        return GenericAuthResponse.fromJson(jsonData, isTokenError: true);
      }
      return GenericAuthResponse.fromJson(jsonData);

    } catch (e) {
      return GenericAuthResponse(
        error: true,
        success: false,
        error_message: 'Ağ Hatası: $e',
      );
    }
  }

    /// Yeni şifreyi belirler
  Future<GenericAuthResponse> resetPassword(ResetPasswordRequest request) async {
    try {
      final url = Uri.parse('$_baseUrl$_resetPasswordEndpoint');
      final headers = getHeaders();
      final body = jsonEncode(request.toJson());

      logger.debug('Şifre Sıfırlama İsteği', extra: {'body': body});
      final response = await http.post(url, headers: headers, body: body);
      logger.debug('Şifre Sıfırlama Yanıtı', extra: {'statusCode': response.statusCode, 'body': response.body});

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 403) {
        return GenericAuthResponse.fromJson(jsonData, isTokenError: true);
      }
      return GenericAuthResponse.fromJson(jsonData);

    } catch (e) {
      return GenericAuthResponse(
        error: true,
        success: false,
        error_message: 'Ağ Hatası: $e',
      );
    }
  }

  /// Kullanıcı verilerini SharedPreferences'a kaydeder
  Future<void> _saveUserData(String userEmail, AuthData authData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final user = User(
        userID: authData.userID,
        token: authData.token,
        isComp: authData.isComp,
        userEmail: userEmail,
      );
      
      await prefs.setString(_userDataKey, jsonEncode(user.toJson()));
      await prefs.setString(_tokenKey, authData.token);
      // Geriye dönük uyumluluk için legacy anahtarı da doldur
      await prefs.setString(_userTokenKeyLegacy, authData.token);
      await prefs.setString(_userEmailKey, userEmail);
    } catch (e, s) {
      logger.error('Kullanıcı verileri kaydedilirken hata', error: e, stackTrace: s);
    }
  }

  /// Kayıtlı kullanıcı verilerini yükler
  Future<User?> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);
      
      if (userDataString != null) {
        final userJson = jsonDecode(userDataString) as Map<String, dynamic>;
        return User.fromJson(userJson);
      }
      
      return null;
    } catch (e, s) {
      logger.error('Kullanıcı verileri yüklenirken hata', error: e, stackTrace: s);
      return null;
    }
  }

  /// Kayıtlı token'ı yükler
  Future<String?> loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e, s) {
      logger.error('Token yüklenirken hata', error: e, stackTrace: s);
      return null;
    }
  }

  /// Kullanıcı çıkışı yapar
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      await prefs.remove(_tokenKey);
      await prefs.remove(_userTokenKeyLegacy);
    } catch (e, s) {
      logger.error('Çıkış yapılırken hata', error: e, stackTrace: s);
    }
  }

  /// Kullanıcının giriş yapıp yapmadığını kontrol eder
  Future<bool> isLoggedIn() async {
    final token = await loadToken();
    return token != null && token.isNotEmpty;
  }

  /// Authenticated API istekleri için genel method
  Future<http.Response> authenticatedRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
  }) async {
    final token = await loadToken();
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = getHeaders(userToken: token);

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(url, headers: headers);
      case 'POST':
        return await http.post(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await http.put(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await http.delete(url, headers: headers);
      default:
        throw ArgumentError('Desteklenmeyen HTTP method: $method');
    }
  }
}
