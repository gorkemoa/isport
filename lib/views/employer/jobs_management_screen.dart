import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/user_service.dart';
import '../../services/employer_service.dart';
import '../../models/user_model.dart';
import '../../models/employer_models.dart';
import '../../services/logger_service.dart';
import '../../utils/app_constants.dart';
import 'employer_dashboard_layout.dart';
import 'add_job_screen.dart';

/// Modern İş İlanları Yönetim Sayfası
/// LinkedIn ve Kariyer.net tarzında kurumsal tasarım
class JobsManagementScreen extends StatefulWidget {
  const JobsManagementScreen({super.key});

  @override
  State<JobsManagementScreen> createState() => _JobsManagementScreenState();
}

class _JobsManagementScreenState extends State<JobsManagementScreen> {
  final UserService _userService = UserService();
  final EmployerService _employerService = EmployerService();
  
  UserModel? _currentUser;
  EmployerJobsData? _jobsData;
  bool _isLoading = true;
  bool _isJobsLoading = false;
  String? _errorMessage;
  String? _jobsErrorMessage;

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
          
          // Kullanıcı verisi yüklendiğinde iş ilanlarını da yükle
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadJobsData();
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

  Future<void> _loadJobsData() async {
    if (_isJobsLoading) return;

    setState(() {
      _isJobsLoading = true;
      _jobsErrorMessage = null;
    });

    try {
      final response = await _employerService.fetchCurrentUserCompanyJobs();
      
      if (response.isTokenError) {
        await _logout();
        return;
      }

      if (response.isSuccessful && response.data != null) {
        setState(() {
          _jobsData = response.data;
          _isJobsLoading = false;
        });
        logger.debug('İş ilanları başarıyla yüklendi: ${response.data!.jobCount} ilan');
      } else {
        setState(() {
          _jobsErrorMessage = response.displayMessage ?? 'İş ilanları alınamadı';
          _isJobsLoading = false;
        });
        logger.debug('İş ilanları alınamadı: ${response.errorMessage}');
      }
    } catch (e) {
      setState(() {
        _jobsErrorMessage = 'Bir hata oluştu: $e';
        _isJobsLoading = false;
      });
      logger.debug('İş ilanları yüklenirken hata: $e');
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
      title: 'İş İlanları',
      actions: [
        IconButton(
          onPressed: _refreshJobs,
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
      floatingActionButton: _currentUser?.company?.canAddJob == true
          ? FloatingActionButton(
              onPressed: _navigateToAddJob,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
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

    return _buildJobsContent();
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
            'İş ilanları yükleniyor...',
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

  Widget _buildJobsContent() {
    final company = _currentUser!.company!;

    return RefreshIndicator(
      onRefresh: _loadJobsData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildJobsOverview(company),
            const SizedBox(height: 24),
            _buildJobsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildJobsOverview(CompanyModel company) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İlan Özeti',
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
                      'Toplam İlan',
                      company.totalJobs.toString(),
                      Icons.article_outlined,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildOverviewStat(
                      'Aktif İlan',
                      company.activeJobs.toString(),
                      Icons.visibility_outlined,
                      Colors.green[600]!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildOverviewStat(
                      'Pasif İlan',
                      company.passiveJobs.toString(),
                      Icons.visibility_off_outlined,
                      Colors.grey[600]!,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildOverviewStat(
                      'Kalan Hak',
                      company.remainingJobSlots.toString(),
                      Icons.add_circle_outlined,
                      Colors.orange[600]!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: company.canAddJob ? Colors.green[50] : Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: company.canAddJob ? Colors.green[200]! : Colors.red[200]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                company.canAddJob ? Icons.check_circle : Icons.warning,
                color: company.canAddJob ? Colors.green[600] : Colors.red[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  company.limitStatusText,
                  style: GoogleFonts.inter(
                    color: company.canAddJob ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
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

  Widget _buildJobsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'İlanlarım',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textTitle,
              ),
            ),
            const Spacer(),
            if (_isJobsLoading)
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
        
        if (_isJobsLoading && _jobsData == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_jobsErrorMessage != null)
          _buildJobsErrorState()
        else if (_jobsData == null || _jobsData!.jobs.isEmpty)
          _buildEmptyJobsState()
        else
          Column(
            children: _jobsData!.jobs.map((job) => _buildJobCard(job)).toList(),
          ),
      ],
    );
  }

  Widget _buildJobsErrorState() {
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
            _jobsErrorMessage!,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textBody,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadJobsData,
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

  Widget _buildEmptyJobsState() {
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
            Icons.work_outline,
            size: 48,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz iş ilanınız bulunmamaktadır',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textBody,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'İlk iş ilanınızı oluşturmak için + butonuna tıklayın',
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

  Widget _buildJobCard(EmployerJobModel job) {
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
                    Expanded(
                      child: Text(
                        job.jobTitle,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTitle,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getWorkTypeColor(job.workType).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getWorkTypeColor(job.workType).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        job.workType,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getWorkTypeColor(job.workType),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                if (job.hasDescription) ...[
                  Text(
                    job.shortDescription,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],
                
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        job.formattedLocation,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        job.formattedSalary,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
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
                  job.showDate,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
                const Spacer(),
                if (job.isHighlighted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 12, color: Colors.amber[600]),
                        const SizedBox(width: 2),
                        Text(
                          'Vurgulanan',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.amber[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: job.isActive ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    job.isActive ? 'Aktif' : 'Pasif',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: job.isActive ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getWorkTypeColor(String workType) {
    switch (workType.toLowerCase()) {
      case 'tam zamanlı':
        return const Color(0xFF059669);
      case 'yarı zamanlı':
        return const Color(0xFF0891B2);
      case 'proje bazlı':
        return const Color(0xFF7C3AED);
      case 'stajyer':
        return const Color(0xFFDC2626);
      case 'freelance':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  void _refreshJobs() {
    _loadJobsData();
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