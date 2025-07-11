import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/auth_models.dart';
import '../services/user_service.dart';
import '../services/auth_services.dart';
import '../services/logger_service.dart';

/// Kullanıcı profili state management'ı
class ProfileViewModel extends ChangeNotifier {
  bool _isLoading = false;
  UserModel? _user;
  String? _errorMessage;
  final UserService _userService = UserService();

  /// Getters
  bool get isLoading => _isLoading;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isLoggedIn => _user != null;

  /// Loading state'i günceller
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Error mesajını günceller
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Kullanıcı verilerini günceller
  void _setUser(UserModel? user) {
    _user = user;
    notifyListeners();
  }

  /// Kullanıcı profilini yükler
  Future<void> loadUserProfile() async {
    try {
      _setLoading(true);
      _setError(null);

      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken');

      if (userToken == null || userToken.isEmpty) {
        _setError('Kullanıcı oturumu bulunamadı');
        _setLoading(false);
        return;
      }

      logger.debug('Kullanıcı profili yükleniyor: $userToken');

      final response = await _userService.getUser(userToken: userToken);
      
      if (response.isTokenError) {
        _setError('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
        await _clearUserData();
        _setLoading(false);
        return;
      }

      if (response.error) {
        _setError(response.error_message.isNotEmpty 
            ? response.error_message 
            : 'Profil bilgileri alınamadı');
        _setLoading(false);
        return;
      }

      if (response.data?.user != null) {
        _setUser(response.data!.user);
        await _saveUserData(response.data!.user);
        logger.debug('Kullanıcı profili başarıyla yüklendi: ${response.data!.user.userFullname}');
      } else {
        _setError('Kullanıcı verileri bulunamadı');
      }

    } catch (e, s) {
      logger.debug('Profil yüklenirken hata', error: e, stackTrace: s);
      _setError('Ağ hatası: Lütfen internet bağlantınızı kontrol edin.');
    } finally {
      _setLoading(false);
    }
  }

  /// Kullanıcı bilgilerini günceller
  Future<bool> updateUserProfile(UpdateUserRequest request) async {
    try {
      _setLoading(true);
      _setError(null);

      logger.debug('Kullanıcı profili güncelleniyor...');

      final response = await _userService.updateUser(request);
      
      if (response.isTokenError) {
        _setError('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
        await _clearUserData();
        _setLoading(false);
        return false;
      }

      if (response.error) {
        _setError(response.error_message.isNotEmpty 
            ? response.error_message 
            : 'Profil güncellenemedi');
        _setLoading(false);
        return false;
      }

      // Başarılı güncelleme sonrası profili yeniden yükle
      await loadUserProfile();
      logger.debug('Kullanıcı profili başarıyla güncellendi');
      return true;

    } catch (e, s) {
      logger.debug('Profil güncellenirken hata', error: e, stackTrace: s);
      _setError('Ağ hatası: Lütfen internet bağlantınızı kontrol edin.');
      _setLoading(false);
      return false;
    }
  }

  /// Kullanıcı şifresini günceller
  Future<bool> updatePassword(UpdatePasswordRequest request) async {
    try {
      _setLoading(true);
      _setError(null);

      logger.debug('Kullanıcı şifresi güncelleniyor...');

      final response = await _userService.updatePassword(request);
      
      if (response.isTokenError) {
        _setError('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
        await _clearUserData();
        _setLoading(false);
        return false;
      }

      if (response.error) {
        _setError(response.error_message.isNotEmpty 
            ? response.error_message 
            : 'Şifre güncellenemedi');
        _setLoading(false);
        return false;
      }

      logger.debug('Kullanıcı şifresi başarıyla güncellendi');
      _setLoading(false);
      return true;

    } catch (e, s) {
      logger.debug('Şifre güncellenirken hata', error: e, stackTrace: s);
      _setError('Ağ hatası: Lütfen internet bağlantınızı kontrol edin.');
      _setLoading(false);
      return false;
    }
  }

  /// Kullanıcı verilerini yerel depolamaya kaydeder
  Future<void> _saveUserData(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userToken', user.userToken);
      await prefs.setString('userFullname', user.userFullname);
      await prefs.setString('userEmail', user.userEmail);
      await prefs.setString('userPhone', user.userPhone);
      await prefs.setBool('isComp', user.isComp);
      await prefs.setString('userStatus', user.userStatus);
      
      if (user.company != null) {
        await prefs.setString('companyName', user.company!.compName);
        await prefs.setString('companyAddress', user.company!.compAddress);
      }
      
      logger.debug('Kullanıcı verileri yerel depolamaya kaydedildi');
    } catch (e, s) {
      logger.debug('Kullanıcı verileri kaydedilirken hata', error: e, stackTrace: s);
    }
  }

  /// Kullanıcı verilerini temizler
  Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _setUser(null);
      logger.debug('Kullanıcı verileri temizlendi');
    } catch (e, s) {
      logger.debug('Kullanıcı verileri temizlenirken hata', error: e, stackTrace: s);
    }
  }

  /// Çıkış yap
  Future<void> logout() async {
    try {
      _setLoading(true);
      await _clearUserData();
      logger.debug('Kullanıcı çıkış yaptı');
    } catch (e, s) {
      logger.debug('Çıkış yaparken hata', error: e, stackTrace: s);
    } finally {
      _setLoading(false);
    }
  }

  /// Hata mesajını temizle
  void clearError() {
    _setError(null);
  }

  /// Yenile
  Future<void> refresh() async {
    await loadUserProfile();
  }

  /// ViewModel'i temizle
  @override
  void dispose() {
    super.dispose();
  }
} 