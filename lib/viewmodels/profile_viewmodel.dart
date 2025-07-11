import 'package:flutter/material.dart';
import 'package:isport/models/auth_models.dart';
import 'package:isport/models/user_model.dart';
import 'package:isport/services/auth_services.dart';
import 'package:isport/services/logger_service.dart';
import 'package:isport/services/user_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  UserModel? _user;
  UserResponse? _userResponse;
  String? _errorMessage;
  bool _isLoading = false;
  bool _needsLogout = false;

  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  UserModel? get user => _user;
  UserResponse? get userResponse => _userResponse;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get needsLogout => _needsLogout;

  TextEditingController get firstnameController => _firstnameController;
  TextEditingController get lastnameController => _lastnameController;
  TextEditingController get emailController => _emailController;
  TextEditingController get phoneController => _phoneController;
  TextEditingController get currentPasswordController => _currentPasswordController;
  TextEditingController get newPasswordController => _newPasswordController;
  TextEditingController get confirmPasswordController => _confirmPasswordController;

  ProfileViewModel() {
    loadUserData();
  }

  Future<void> loadUserData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.loadToken();
      if (token == null) {
        _needsLogout = true;
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      final response = await _userService.getUser(userToken: token);
      _userResponse = response;

      if (response.success && response.data != null) {
        _user = response.data!.user;
        _setUserFieldsFromModel();
      } else {
        _errorMessage = response.displayMessage ?? 'Kullanıcı verileri alınamadı.';
        if (response.isTokenError) {
          _needsLogout = true;
        }
      }
    } catch (e, s) {
      logger.e('Kullanıcı verileri yüklenirken hata', error: e, stackTrace: s);
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUser() async {
    await loadUserData();
  }

  Future<bool> updateUser(UpdateUserRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _userService.updateUser(request);

      _isLoading = false;

      if (response.success) {
        await loadUserData(); // Refresh data
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.displayMessage ?? 'Profil güncellenemedi.';
        if (response.isTokenError) {
          _needsLogout = true;
        }
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      logger.e('Profil güncellenirken hata', error: e, stackTrace: s);
      _errorMessage = 'Bir hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(UpdatePasswordRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _userService.updatePassword(request);
      _isLoading = false;

      if (response.success) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.displayMessage ?? 'Şifre değiştirilemedi.';
        if (response.isTokenError) {
          _needsLogout = true;
        }
        notifyListeners();
        return false;
      }
    } catch (e, s) {
      logger.e('Şifre değiştirilirken hata', error: e, stackTrace: s);
      _errorMessage = 'Bir hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _setUserFieldsFromModel() {
    if (_user != null) {
      _firstnameController.text = _user!.userFirstname;
      _lastnameController.text = _user!.userLastname;
      _emailController.text = _user!.userEmail;
      _phoneController.text = _user!.userPhone;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _needsLogout = true;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
} 