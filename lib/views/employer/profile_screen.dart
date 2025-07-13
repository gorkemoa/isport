import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../services/logger_service.dart';
import '../../utils/app_constants.dart';
import 'employer_dashboard_layout.dart';

/// Modern Profil Sayfası
/// LinkedIn ve Kariyer.net tarzında kurumsal tasarım
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
      title: 'Profil',
      showBottomNavigation: false,
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

    return _buildProfileContent();
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
            'Profil yükleniyor...',
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

  Widget _buildProfileContent() {
    final user = _currentUser!;
    final company = user.company!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(user, company),
          const SizedBox(height: 24),
          _buildUserInfoSection(user),
          const SizedBox(height: 24),
          _buildCompanyInfoSection(company),
          const SizedBox(height: 24),
          _buildSettingsSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user, CompanyModel company) {
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
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              user.userFullname.substring(0, 2).toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.userFullname,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            company.compName,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'İşveren Hesabı',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(UserModel user) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Kullanıcı Bilgileri',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Ad Soyad', user.userFullname, Icons.person),
          _buildInfoRow('E-posta', user.userEmail, Icons.email),
          _buildInfoRow('Telefon', user.userPhone, Icons.phone),
          _buildInfoRow('Cinsiyet', user.userGender, Icons.wc),
        ],
      ),
    );
  }

  Widget _buildCompanyInfoSection(CompanyModel company) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Şirket Bilgileri',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Şirket Adı', company.compName, Icons.business),
          if (company.compDesc.isNotEmpty)
            _buildInfoRow('Açıklama', company.compDesc, Icons.description),
          _buildInfoRow('Adres', company.fullLocation, Icons.location_on),
          _buildInfoRow('Çalışan Sayısı', company.formattedEmployeeCount, Icons.people),
          if (company.compSector.isNotEmpty)
            _buildInfoRow('Sektör', company.compSector, Icons.category),
          if (company.hasWebsite)
            _buildInfoRow('Web Sitesi', company.compWebSite, Icons.language),
          if (company.compTaxNumber.isNotEmpty)
            _buildInfoRow('Vergi No', company.compTaxNumber, Icons.receipt),
          if (company.compTaxPlace.isNotEmpty)
            _buildInfoRow('Vergi Dairesi', company.compTaxPlace, Icons.account_balance),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ayarlar',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingsItem(
            'Profil Düzenle',
            'Kişisel bilgilerinizi güncelleyin',
            Icons.edit,
            () => _editProfile(),
          ),
          _buildSettingsItem(
            'Şirket Bilgileri',
            'Şirket bilgilerinizi düzenleyin',
            Icons.business,
            () => _editCompany(),
          ),
          _buildSettingsItem(
            'Bildirimler',
            'Bildirim ayarlarınızı yönetin',
            Icons.notifications,
            () => _manageNotifications(),
          ),
          _buildSettingsItem(
            'Güvenlik',
            'Hesap güvenlik ayarları',
            Icons.security,
            () => _securitySettings(),
          ),
          _buildSettingsItem(
            'Yardım',
            'Yardım ve destek',
            Icons.help_outline,
            () => _showHelp(),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: Icon(Icons.logout, size: 18),
              label: Text(
                'Çıkış Yap',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : 'Belirtilmemiş',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textTitle,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: AppColors.primary,
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
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }

  void _editProfile() {
    // Navigate to edit profile page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profil düzenleme yakında eklenecek'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _editCompany() {
    // Navigate to edit company page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Şirket bilgileri düzenleme yakında eklenecek'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _manageNotifications() {
    // Navigate to notifications page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bildirim ayarları yakında eklenecek'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _securitySettings() {
    // Navigate to security page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Güvenlik ayarları yakında eklenecek'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showHelp() {
    // Show help dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Yardım ve destek yakında eklenecek'),
        backgroundColor: AppColors.primary,
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