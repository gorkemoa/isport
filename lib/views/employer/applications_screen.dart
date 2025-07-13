import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/user_service.dart';
import '../../services/employer_service.dart';
import '../../models/user_model.dart';
import '../../models/employer_models.dart';
import '../../services/logger_service.dart';
import '../../utils/app_constants.dart';
import 'employer_dashboard_layout.dart';
import 'application_detail_screen.dart';

/// Modern Başvurular Yönetim Sayfası
/// LinkedIn ve Kariyer.net tarzında kurumsal tasarım
class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  final UserService _userService = UserService();
  final EmployerService _employerService = EmployerService();
  
  UserModel? _currentUser;
  EmployerApplicationsData? _applicationsData;
  bool _isLoading = true;
  bool _isApplicationsLoading = false;
  String? _errorMessage;
  String? _applicationsErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken') ?? '';
      
      if (userToken.isEmpty) {
        setState(() {
          _errorMessage = 'Oturum bulunamadı. Lütfen tekrar giriş yapın.';
          _isLoading = false;
        });
        return;
      }

      logger.debug('Kullanıcı verisi yükleniyor...');
      
      final response = await _userService.getUser(userToken: userToken);
      
      if (response.isTokenError) {
        await _logout();
        return;
      }
      
      if (response.success && response.data != null) {
        final user = response.data!.user;
        
        if (user.isComp) {
          setState(() {
            _currentUser = user;
            _isLoading = false;
            _errorMessage = null;
          });
          logger.debug('Şirket kullanıcısı başarıyla yüklendi: ${user.userFullname}');
          
          // Kullanıcı verisi yüklendiğinde başvuruları da yükle
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadApplicationsData();
          });
        } else {
          setState(() {
            _errorMessage = 'Bu hesap şirket hesabı değil. Lütfen geçerli bir şirket hesabı ile giriş yapın.';
            _isLoading = false;
          });
          logger.debug('Kullanıcı şirket hesabı değil');
        }
      } else {
        setState(() {
          _errorMessage = response.displayMessage ?? 'Kullanıcı bilgileri alınamadı';
          _isLoading = false;
        });
        logger.debug('Kullanıcı verisi alınamadı: ${response.error_message}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bir hata oluştu: $e';
        _isLoading = false;
      });
      logger.debug('Kullanıcı verisi yüklenirken hata: $e');
    }
  }

  Future<void> _loadApplicationsData() async {
    if (_isApplicationsLoading) return;

    setState(() {
      _isApplicationsLoading = true;
      _applicationsErrorMessage = null;
    });

    try {
      final response = await _employerService.fetchCurrentUserCompanyApplications();
      
      if (response.isTokenError) {
        await _logout();
        return;
      }

      if (response.isSuccessful && response.data != null) {
        setState(() {
          _applicationsData = response.data;
          _isApplicationsLoading = false;
        });
        logger.debug('Başvurular başarıyla yüklendi: ${response.data!.applicationCount} başvuru');
      } else {
        setState(() {
          _applicationsErrorMessage = response.displayMessage ?? 'Başvurular alınamadı';
          _isApplicationsLoading = false;
        });
        logger.debug('Başvurular alınamadı: ${response.errorMessage}');
      }
    } catch (e) {
      setState(() {
        _applicationsErrorMessage = 'Bir hata oluştu: $e';
        _isApplicationsLoading = false;
      });
      logger.debug('Başvurular yüklenirken hata: $e');
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userToken');
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      logger.debug('Çıkış yapılırken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return EmployerDashboardLayout(
      title: 'Başvurular',
      actions: [
        IconButton(
          onPressed: _refreshApplications,
          icon: Icon(
            Icons.refresh,
            color: AppColors.textBody,
            size: 20,
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_currentUser == null) {
      return _buildEmptyState();
    }

    return _buildApplicationsContent();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Başvurular yükleniyor...',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textBody,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              Icons.error_outline,
              size: 32,
              color: Colors.red[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bir hata oluştu',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textTitle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadUserData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Tekrar Dene',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.business_outlined,
              size: 40,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Şirket bilgileri bulunamadı',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textBody,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsContent() {
    final company = _currentUser!.company!;

    return RefreshIndicator(
      onRefresh: _loadApplicationsData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildApplicationsOverview(company),
            const SizedBox(height: 24),
            _buildApplicationsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsOverview(CompanyModel company) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Başvuru Özeti',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textTitle,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildOverviewStat(
                      'Toplam Başvuru',
                      company.totalApplications.toString(),
                      Icons.people_outlined,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildOverviewStat(
                      'Bekleyen',
                      _applicationsData?.applications.where((app) => app.statusName == 'Yeni Başvuru').length.toString() ?? '0',
                      Icons.schedule_outlined,
                      Colors.orange[600]!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildOverviewStat(
                      'Değerlendirilen',
                      _applicationsData?.applications.where((app) => app.statusName == 'Değerlendiriliyor').length.toString() ?? '0',
                      Icons.visibility_outlined,
                      Colors.blue[600]!,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildOverviewStat(
                      'Kabul Edilen',
                      _applicationsData?.applications.where((app) => app.statusName == 'Kabul Edildi').length.toString() ?? '0',
                      Icons.check_circle_outlined,
                      Colors.green[600]!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textTitle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Son Başvurular',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textTitle,
              ),
            ),
            const Spacer(),
            if (_isApplicationsLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_isApplicationsLoading && _applicationsData == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_applicationsErrorMessage != null)
          _buildApplicationsErrorState()
        else if (_applicationsData == null || _applicationsData!.applications.isEmpty)
          _buildEmptyApplicationsState()
        else
          Column(
            children: _applicationsData!.applications.map((application) => _buildApplicationCard(application)).toList(),
          ),
      ],
    );
  }

  Widget _buildApplicationsErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            _applicationsErrorMessage!,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textBody,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadApplicationsData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Tekrar Dene',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyApplicationsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz başvuru bulunmamaktadır',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textBody,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'İş ilanlarınız için başvurular geldiğinde burada görünecek',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(EmployerApplicationModel application) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToApplicationDetail(application),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          application.userInitials,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              application.userName,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textTitle,
                              ),
                            ),
                            Text(
                              application.jobTitle,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(application.statusColor).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(application.statusColor).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          application.statusName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(application.statusColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  if (application.hasDescription) ...[
                    const SizedBox(height: 12),
                    Text(
                      application.shortDescription,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // Divider
            Container(
              height: 1,
              color: AppColors.cardBorder,
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(
                    application.appliedAt,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                  const Spacer(),
                  if (application.isFavorite)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite, size: 12, color: Colors.red[600]),
                          const SizedBox(width: 2),
                          Text(
                            'Favori',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.textLight,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String statusColor) {
    try {
      return Color(int.parse(statusColor.replaceAll('#', '0xFF')));
    } catch (e) {
      return AppColors.textLight;
    }
  }

  void _refreshApplications() {
    _loadApplicationsData();
  }

  void _navigateToApplicationDetail(EmployerApplicationModel application) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplicationDetailScreen(
          appId: application.appID,
          jobTitle: application.jobTitle,
        ),
      ),
    );
  }
}

// Google Fonts import için
class GoogleFonts {
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
} 