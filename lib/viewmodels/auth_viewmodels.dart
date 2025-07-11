import 'package:flutter/foundation.dart';
import '../models/auth_models.dart';
import '../services/auth_services.dart';
import '../services/logger_service.dart';

/// Authentication ViewModel (Provider pattern ile)
class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // Private durumlar
  AuthStatus _authStatus = AuthStatus.initial;
  User? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;
  String? _codeToken;

  // Public getter'lar
  AuthStatus get authStatus => _authStatus;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authStatus == AuthStatus.authenticated;

  /// Uygulama başlatıldığında çağrılır - kayıtlı kullanıcı var mı kontrol eder
  Future<void> initializeAuth() async {
    _setLoading(true);
    
    try {
      final user = await _authService.loadUserData();
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (user != null && isLoggedIn) {
        _currentUser = user;
        _setAuthStatus(AuthStatus.authenticated);
        _clearError();
      } else {
        _setAuthStatus(AuthStatus.unauthenticated);
      }
    } catch (e) {
      _setError('Kullanıcı verileri yüklenirken hata: $e');
      _setAuthStatus(AuthStatus.unauthenticated);
    }
    
    _setLoading(false);
  }

  /// Kullanıcı girişi yapar
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final loginRequest = LoginRequest(
        userEmail: email,
        userPassword: password,
      );
      
      final loginResponse = await _authService.login(loginRequest);
      
      if (loginResponse.success && loginResponse.data != null) {
        // Başarılı giriş
        _currentUser = User(
          userID: loginResponse.data!.userID,
          token: loginResponse.data!.token,
          isComp: loginResponse.data!.isComp,
          userEmail: email,
        );
        
        _setAuthStatus(AuthStatus.authenticated);
        _clearError();
        _setLoading(false);
        return true;
      } else {
        // Başarısız giriş
        _setError(loginResponse.displayMessage ?? 'Giriş başarısız');
        if (loginResponse.isTokenError) {
          _setAuthStatus(AuthStatus.unauthenticated);
        } else {
          _setAuthStatus(AuthStatus.error);
        }
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Giriş yapılırken hata: $e');
      _setAuthStatus(AuthStatus.error);
      _setLoading(false);
      return false;
    }
  }

  /// Kullanıcı kaydı yapar
  Future<RegisterResponse> register(RegisterRequest request) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.register(request);

      if (response.success) {
        // Başarılı kayıt, hata yok
        _setAuthStatus(AuthStatus.unauthenticated); // Kayıt sonrası giriş yapılmamış state'e geç
      } else {
        // Hatalı kayıt
        _setError(response.displayMessage ?? 'Kayıt başarısız oldu.');
        if (response.isTokenError) {
          _setAuthStatus(AuthStatus.unauthenticated);
        } else {
          _setAuthStatus(AuthStatus.error);
        }
      }
      _setLoading(false);
      return response;

    } catch (e) {
      _setError('Kayıt yapılırken bir hata oluştu: $e');
      _setAuthStatus(AuthStatus.error);
      _setLoading(false);
      return RegisterResponse(error: true, success: false, error_message: e.toString());
    }
  }

  /// Şifre sıfırlama maili gönderir. Başarılı olursa true döner.
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();
    try {
      final request = ForgotPasswordRequest(userEmail: email);
      final response = await _authService.forgotPassword(request);
      if (response.success && response.data?.codeToken != null) {
        _codeToken = response.data!.codeToken;
        _setLoading(false);
        return true;
      } else {
        _setError(response.displayMessage ?? 'Şifre sıfırlama isteği gönderilemedi.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Bir hata oluştu: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Doğrulama kodunu kontrol eder. Başarılı olursa true döner.
  Future<bool> checkCode(String code) async {
    if (_codeToken == null) {
      _setError('Doğrulama anahtarı bulunamadı. Lütfen tekrar deneyin.');
      return false;
    }
    _setLoading(true);
    _clearError();
    try {
      final request = CheckCodeRequest(code: code, codeToken: _codeToken!);
      final response = await _authService.checkCode(request);
      if (response.success) {
        // codeToken hala geçerli, bir sonraki adıma geçilebilir.
        _setLoading(false);
        return true;
      } else {
        _setError(response.displayMessage ?? 'Kod doğrulanamadı.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Bir hata oluştu: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Yeni şifreyi ayarlar. Başarılı olursa true döner.
  Future<bool> resetPassword(String password) async {
    if (_codeToken == null) {
      _setError('Doğrulama anahtarı bulunamadı. Lütfen tekrar deneyin.');
      return false;
    }
     _setLoading(true);
    _clearError();
    try {
      final request = ResetPasswordRequest(userPassword: password, codeToken: _codeToken!);
      final response = await _authService.resetPassword(request);
       if (response.success) {
        _codeToken = null; // Token kullanıldı, temizle.
        _setLoading(false);
        return true;
      } else {
        _setError(response.displayMessage ?? 'Şifre sıfırlanamadı.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Bir hata oluştu: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Kullanıcı çıkışı yapar
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await _authService.logout();
      _currentUser = null;
      _setAuthStatus(AuthStatus.unauthenticated);
      _clearError();
    } catch (e) {
      _setError('Çıkış yapılırken hata: $e');
    }
    
    _setLoading(false);
  }

  /// Kullanıcı verilerini yeniler
  Future<void> refreshUser() async {
    try {
      final user = await _authService.loadUserData();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e, s) {
      logger.w('Kullanıcı verileri yenilenirken hata', error: e, stackTrace: s);
    }
  }

  /// Authentication durumunu kontrol eder
  Future<bool> checkAuthStatus() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn && _authStatus == AuthStatus.authenticated) {
        await logout();
      }
      return isLoggedIn;
    } catch (e) {
      return false;
    }
  }

  // Private helper methodlar
  void _setAuthStatus(AuthStatus status) {
    _authStatus = status;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Hata mesajını temizler
  void clearError() {
    _clearError();
  }

  /// Authenticated API isteği yapar
  Future<Map<String, dynamic>?> makeAuthenticatedRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _authService.authenticatedRequest(
        endpoint: endpoint,
        method: method,
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonData = response.body;
        if (jsonData.isNotEmpty) {
          return jsonData as Map<String, dynamic>?;
        }
      } else if (response.statusCode == 401) {
        // Token geçersiz, kullanıcıyı çıkış yap
        await logout();
        _setError('Oturum süresi doldu, lütfen tekrar giriş yapın');
      } else {
        _setError('API Hatası: ${response.statusCode}');
      }
      
      return null;
    } catch (e) {
      _setError('İstek yapılırken hata: $e');
      return null;
    }
  }

  /// Token'ı döndürür
  Future<String?> getToken() async {
    return await _authService.loadToken();
  }

  Future<bool> isLoggedIn() async {
    return await _authService.isLoggedIn();
  }
}
