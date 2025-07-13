import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../services/logger_service.dart';
import '../../utils/app_constants.dart';
import 'employer_dashboard_layout.dart';
import 'add_job_screen.dart';

/// Modern Employer Dashboard Ana Sayfa
/// LinkedIn ve Kariyer.net tarzında kurumsal tasarım
class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  final UserService _userService = UserService();
  
  UserModel? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

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
      title: 'Dashboard',
      actions: [
        IconButton(
          onPressed: _refreshData,
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

    return _buildDashboardContent();
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
            'Dashboard yükleniyor...',
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

  Widget _buildDashboardContent() {
    final user = _currentUser!;
    final company = user.company!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(user, company),
          const SizedBox(height: 24),
          _buildStatsGrid(company),
          const SizedBox(height: 24),
          _buildQuickActions(company),
          const SizedBox(height: 24),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(UserModel user, CompanyModel company) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  Icons.business,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoş Geldiniz',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.userFullname,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      company.compName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildWelcomeStat('Aktif İlan', company.activeJobs.toString(), Icons.visibility),
              const SizedBox(width: 16),
              _buildWelcomeStat('Toplam Başvuru', company.totalApplications.toString(), Icons.people),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(CompanyModel company) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İstatistikler',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textTitle,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Toplam İlan',
                company.totalJobs.toString(),
                Icons.article_outlined,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Aktif İlan',
                company.activeJobs.toString(),
                Icons.visibility_outlined,
                Colors.green[600]!,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Başvuru',
                company.totalApplications.toString(),
                Icons.person_add_outlined,
                Colors.orange[600]!,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Favori Aday',
                '0', // TODO: Get from API
                Icons.favorite_outlined,
                Colors.red[600]!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textTitle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(CompanyModel company) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı Aksiyonlar',
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
              _buildActionButton(
                company.canAddJob 
                  ? 'Yeni İş İlanı Ekle' 
                  : 'İş İlanı Ekle (${company.isJobLimitReached ? "Limit Doldu" : "Yetki Yok"})',
                Icons.add,
                company.canAddJob ? AppColors.primary : AppColors.textLight,
                company.canAddJob ? _navigateToAddJob : null,
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                'Başvuruları İncele',
                Icons.people,
                Colors.orange[600]!,
                () => _navigateToApplications(),
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                'Favori Adaylar',
                Icons.favorite,
                Colors.red[600]!,
                () => _navigateToFavorites(),
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                'İlanları Yönet',
                Icons.edit,
                Colors.green[600]!,
                () => _navigateToJobs(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback? onPressed) {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: onPressed != null ? Colors.white : AppColors.textLight),
        label: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: onPressed != null ? Colors.white : AppColors.textLight,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? color : AppColors.background,
          foregroundColor: onPressed != null ? Colors.white : AppColors.textLight,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: onPressed != null ? 2 : 0,
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Son Aktiviteler',
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
              _buildActivityItem(
                'Yeni başvuru alındı',
                'PHP Developer pozisyonu için 2 yeni başvuru',
                Icons.person_add,
                Colors.green[600]!,
                '2 saat önce',
              ),
              const SizedBox(height: 16),
              _buildActivityItem(
                'İlan güncellendi',
                'Senior Flutter Developer ilanı güncellendi',
                Icons.edit,
                Colors.blue[600]!,
                '1 gün önce',
              ),
              const SizedBox(height: 16),
              _buildActivityItem(
                'Favori aday eklendi',
                'Ahmet Yılmaz favorilere eklendi',
                Icons.favorite,
                Colors.red[600]!,
                '2 gün önce',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String description, IconData icon, Color color, String time) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTitle,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  void _refreshData() {
    _loadUserData();
  }

  void _navigateToAddJob() {
    if (_currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddJobScreen(user: _currentUser!),
        ),
      );
    }
  }

  void _navigateToApplications() {
    // Navigate to applications page
  }

  void _navigateToFavorites() {
    // Navigate to favorites page
  }

  void _navigateToJobs() {
    // Navigate to jobs page
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