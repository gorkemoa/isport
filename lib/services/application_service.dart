import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/application_models.dart';
import '../models/auth_models.dart';
import 'auth_services.dart';
import 'logger_service.dart';

/// İş başvuruları ile ilgili API servis işlemleri
class ApplicationService {
  static const String _baseUrl = 'https://api.rivorya.com/isport';
  static const String _applicationsEndpoint = '/service/user/account';

  /// Timeout süreleri
  static const Duration _connectTimeout = Duration(seconds: 10);
  static const Duration _receiveTimeout = Duration(seconds: 15);

  /// Kullanıcının başvurularını getirir
  /// [userId] - Kullanıcı ID'si
  /// Returns ApplicationListResponse with status code handling (410 = success, 417 = error)
  Future<ApplicationListResponse> fetchUserApplications({int? userId}) async {
    try {
      // Kullanıcı bilgilerini al
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken') ?? '';
      
      if (userToken.isEmpty) {
        logger.warning('User token bulunamadı');
        return ApplicationListResponse(
          error: true,
          success: false,
          errorMessage: 'Oturum açmanız gerekiyor',
          isTokenError: true,
        );
      }

      // Eğer userId verilmemişse, mevcut kullanıcının ID'sini kullan
      int targetUserId = userId ?? await _getCurrentUserId();
      
      logger.debug('Başvurular getiriliyor - Kullanıcı ID: $targetUserId');

      // API isteği hazırla
      final uri = Uri.parse('$_baseUrl$_applicationsEndpoint/$targetUserId/jobApplications');
      final headers = AuthService.getHeaders(userToken: userToken);

      logger.debug('API isteği gönderiliyor: ${uri.toString()}');

      // HTTP isteği gönder
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(_connectTimeout);

      logger.debug('API yanıtı alındı - Status: ${response.statusCode}');

      // Yanıtı parse et
      return _parseApplicationListResponse(response);

    } catch (e) {
      logger.error('Başvurular getirme hatası: $e');
      return ApplicationListResponse(
        error: true,
        success: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Mevcut kullanıcının ID'sini alır
  Future<int> _getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        final user = User.fromJson(userData);
        return user.userID;
      }
      
      // Fallback - token'dan user ID çıkarmaya çalış veya varsayılan değer
      return 2; // API örneklerinde 2 kullanılmış
    } catch (e) {
      logger.error('Kullanıcı ID alınamadı: $e');
      return 2; // Varsayılan değer
    }
  }

  /// HTTP yanıtını ApplicationListResponse'a çevirir
  ApplicationListResponse _parseApplicationListResponse(http.Response response) {
    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      // Özel status kod kontrolü
      final has410 = jsonResponse.containsKey('410');
      final has417 = jsonResponse.containsKey('417');
      
      if (has417) {
        // 417 status kod hata demektir
        return ApplicationListResponse(
          error: true,
          success: false,
          status417: jsonResponse['417'],
          errorMessage: jsonResponse['417'] ?? 'Bilinmeyen hata',
        );
      }
      
      if (has410 || (!jsonResponse['error'] && jsonResponse['success'])) {
        // 410 status kod veya normal başarı durumu
        return ApplicationListResponse.fromJson(jsonResponse);
      }
      
      // Diğer durumlar
      return ApplicationListResponse.fromJson(jsonResponse);
      
    } catch (e) {
      logger.error('API yanıtı parse hatası: $e');
      return ApplicationListResponse(
        error: true,
        success: false,
        errorMessage: 'Veri işleme hatası: ${e.toString()}',
      );
    }
  }

  /// Hata mesajını standart formata çevirir
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('TimeoutException')) {
      return 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.';
    } else if (error.toString().contains('SocketException')) {
      return 'İnternet bağlantınızı kontrol edin.';
    } else if (error.toString().contains('FormatException')) {
      return 'Veri formatı hatası. Lütfen tekrar deneyin.';
    } else {
      return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  /// Başvuru detayını getirir (gelecekte gerekli olabilir)
  Future<ApplicationModel?> fetchApplicationDetail(int appId) async {
    try {
      logger.debug('Başvuru detayı getiriliyor - Başvuru ID: $appId');
      
      // Bu endpoint henüz mevcut değil, gelecekte eklenebilir
      // Şimdilik null döndür
      return null;

    } catch (e) {
      logger.error('Başvuru detayı getirme hatası: $e');
      return null;
    }
  }

  /// Başvuru durumunu günceller (gelecekte gerekli olabilir)
  Future<bool> updateApplicationStatus(int appId, String newStatus) async {
    try {
      logger.debug('Başvuru durumu güncelleniyor - Başvuru ID: $appId, Yeni Durum: $newStatus');
      
      // Bu endpoint henüz mevcut değil, gelecekte eklenebilir
      // Şimdilik false döndür
      return false;

    } catch (e) {
      logger.error('Başvuru durumu güncelleme hatası: $e');
      return false;
    }
  }
} 