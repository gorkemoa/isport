import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_services.dart';
import '../services/user_service.dart';
import '../services/logger_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  UserResponse? _userResponse;
  UserResponse? get userResponse => _userResponse;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _needsLogout = false;
  bool get needsLogout => _needsLogout;

  ProfileViewModel() {
    fetchUser();
  }

  Future<void> fetchUser() async {
    _isLoading = true;
    _errorMessage = null;
    _needsLogout = false;
    notifyListeners();

    try {
      final String? token = await _authService.loadToken();
      if (token == null || token.isEmpty) {
        throw Exception('Giriş yapmış bir kullanıcı bulunamadı.');
      }
      
      _userResponse = await _userService.getUser(userToken: token);

      if (_userResponse?.error ?? true) {
        _errorMessage = _userResponse?.message410 ?? 'Kullanıcı bilgileri alınamadı.';
        
        // Eğer hata mesajı token ile ilgiliyse logout gerekli
        if (_errorMessage?.contains('Oturum süreniz dolmuş') ?? false) {
          _needsLogout = true;
          await logout();
        }
      }

    } catch (e, s) {
      logger.e('Profil verisi getirilirken hata', error: e, stackTrace: s);
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      _userResponse = null;
      _needsLogout = true;
      notifyListeners();
    } catch (e, s) {
      logger.e('Logout işlemi sırasında hata', error: e, stackTrace: s);
    }
  }
} 