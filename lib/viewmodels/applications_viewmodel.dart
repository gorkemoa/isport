import 'package:flutter/material.dart';

import '../models/applications_models.dart';
import '../models/user_model.dart';
import '../services/applications_service.dart';
import '../services/auth_services.dart';
import '../services/logger_service.dart';

class ApplicationsViewModel extends ChangeNotifier {
  final ApplicationsService _applicationsService = ApplicationsService();
  final AuthService _authService = AuthService();

  // Başvuru verileri
  ApplicationsResponse? _applicationsResponse;
  ApplicationsResponse? get applicationsResponse => _applicationsResponse;

  // Favori verileri
  FavoritesResponse? _favoritesResponse;
  FavoritesResponse? get favoritesResponse => _favoritesResponse;

  // Loading states
  bool _isLoadingApplications = false;
  bool get isLoadingApplications => _isLoadingApplications;

  bool _isLoadingFavorites = false;
  bool get isLoadingFavorites => _isLoadingFavorites;

  // Error messages
  String? _applicationsErrorMessage;
  String? get applicationsErrorMessage => _applicationsErrorMessage;

  String? _favoritesErrorMessage;
  String? get favoritesErrorMessage => _favoritesErrorMessage;

  // Logout flag
  bool _needsLogout = false;
  bool get needsLogout => _needsLogout;

  // User data
  UserModel? _currentUser;

  ApplicationsViewModel() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // Önce kullanıcı bilgilerini al
      final userData = await _authService.loadUserData();
      if (userData != null) {
        _currentUser = UserModel(
          userID: userData.userID,
          username: '',
          userFirstname: '',
          userLastname: '',
          userFullname: '',
          userEmail: userData.userEmail,
          userBirthday: '',
          userPhone: '',
          userRank: '',
          userStatus: '',
          userGender: '',
          userToken: userData.token,
          userPlatform: '',
          userVersion: '',
          iosVersion: '',
          androidVersion: '',
          profilePhoto: '',
          isApproved: true,
          isComp: userData.isComp,
          company: [],
        );
        
        // Her iki veri setini de yükle
        await Future.wait([
          fetchApplications(),
          fetchFavorites(),
        ]);
      }
    } catch (e, s) {
      logger.e('İlk veri yüklenirken hata', error: e, stackTrace: s);
    }
  }

  Future<void> fetchApplications() async {
    if (_currentUser == null) {
      _applicationsErrorMessage = 'Kullanıcı bilgisi bulunamadı.';
      notifyListeners();
      return;
    }

    _isLoadingApplications = true;
    _applicationsErrorMessage = null;
    _needsLogout = false;
    notifyListeners();

    try {
      final String? token = await _authService.loadToken();
      if (token == null || token.isEmpty) {
        throw Exception('Giriş yapmış bir kullanıcı bulunamadı.');
      }

      _applicationsResponse = await _applicationsService.getApplications(
        userToken: token,
        userID: _currentUser!.userID,
      );

      if (_applicationsResponse?.error ?? true) {
        _applicationsErrorMessage = _applicationsResponse?.message410 ?? 'Başvuru listesi alınamadı.';
        
        // Token ile ilgili hata kontrolü
        if (_applicationsErrorMessage?.contains('Oturum süreniz dolmuş') ?? false) {
          _needsLogout = true;
          await logout();
        }
      }

    } catch (e, s) {
      logger.e('Başvuru listesi getirilirken hata', error: e, stackTrace: s);
      _applicationsErrorMessage = e.toString();
    } finally {
      _isLoadingApplications = false;
      notifyListeners();
    }
  }

  Future<void> fetchFavorites() async {
    if (_currentUser == null) {
      _favoritesErrorMessage = 'Kullanıcı bilgisi bulunamadı.';
      notifyListeners();
      return;
    }

    _isLoadingFavorites = true;
    _favoritesErrorMessage = null;
    _needsLogout = false;
    notifyListeners();

    try {
      final String? token = await _authService.loadToken();
      if (token == null || token.isEmpty) {
        throw Exception('Giriş yapmış bir kullanıcı bulunamadı.');
      }

      _favoritesResponse = await _applicationsService.getFavorites(
        userToken: token,
        userID: _currentUser!.userID,
      );

      if (_favoritesResponse?.error ?? true) {
        _favoritesErrorMessage = _favoritesResponse?.message410 ?? 'Favori listesi alınamadı.';
        
        // Token ile ilgili hata kontrolü
        if (_favoritesErrorMessage?.contains('Oturum süreniz dolmuş') ?? false) {
          _needsLogout = true;
          await logout();
        }
      }

    } catch (e, s) {
      logger.e('Favori listesi getirilirken hata', error: e, stackTrace: s);
      _favoritesErrorMessage = e.toString();
    } finally {
      _isLoadingFavorites = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchApplications(),
      fetchFavorites(),
    ]);
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      _applicationsResponse = null;
      _favoritesResponse = null;
      _currentUser = null;
      _needsLogout = true;
      notifyListeners();
    } catch (e, s) {
      logger.e('Logout işlemi sırasında hata', error: e, stackTrace: s);
    }
  }

  // Getter methods for easy access
  List<Application> get applications => _applicationsResponse?.data?.applications ?? [];
  List<Favorite> get favorites => _favoritesResponse?.data?.favorites ?? [];
  
  bool get hasApplications => applications.isNotEmpty;
  bool get hasFavorites => favorites.isNotEmpty;
  
  bool get isLoading => _isLoadingApplications || _isLoadingFavorites;
} 