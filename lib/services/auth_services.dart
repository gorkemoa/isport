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
  
  // Basic Auth sabitleri
  static const String _basicAuthUsername = 'Tr2BUhR2ICWHJN2nlvp9T5ycBoyMJD';
  static const String _basicAuthPassword = 'vRP4rTBAqm1tm2I17I1EI6PHFBEdl0';
  
  // SharedPreferences anahtarları
  static const String _userDataKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _userEmailKey = 'user_email';

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
    try {
      final url = Uri.parse('$_baseUrl$_loginEndpoint');
      final headers = getHeaders();
      final body = jsonEncode(loginRequest.toJson());

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 410) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final loginResponse = LoginResponse.fromJson(jsonData);
        
        // Başarılı giriş durumunda kullanıcı verilerini kaydet
        if (loginResponse.success && loginResponse.data != null) {
          await _saveUserData(loginRequest.userEmail, loginResponse.data!);
        }
        
        return loginResponse;
      } else {
        return LoginResponse(
          error: true,
          success: false,
          message410: 'HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return LoginResponse(
        error: true,
        success: false,
        message410: 'Network Error: $e',
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
      await prefs.setString(_userEmailKey, userEmail);
    } catch (e, s) {
      logger.e('Kullanıcı verileri kaydedilirken hata', error: e, stackTrace: s);
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
      logger.e('Kullanıcı verileri yüklenirken hata', error: e, stackTrace: s);
      return null;
    }
  }

  /// Kayıtlı token'ı yükler
  Future<String?> loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e, s) {
      logger.e('Token yüklenirken hata', error: e, stackTrace: s);
      return null;
    }
  }

  /// Kullanıcı çıkışı yapar
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      await prefs.remove(_tokenKey);
      await prefs.remove(_userEmailKey);
    } catch (e, s) {
      logger.e('Çıkış yapılırken hata', error: e, stackTrace: s);
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
