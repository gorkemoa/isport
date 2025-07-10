import 'package:flutter/material.dart';
import '../models/company_detail_model.dart';
import '../services/user_service.dart';
import '../services/logger_service.dart';

class CompanyDetailViewModel extends ChangeNotifier {
  final UserService _userService = UserService();

  CompanyDetailResponse? _companyDetail;
  CompanyDetailResponse? get companyDetail => _companyDetail;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final int companyId;

  CompanyDetailViewModel({required this.companyId}) {
    fetchCompanyDetail();
  }

  Future<void> fetchCompanyDetail() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _companyDetail = await _userService.getCompanyDetail(companyId: companyId);

      if (_companyDetail?.error ?? true) {
        _errorMessage = _companyDetail?.message ?? 'Şirket detayları alınamadı.';
      }
    } catch (e, s) {
      logger.e('Şirket detayı getirilirken ViewModel hatası', error: e, stackTrace: s);
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 