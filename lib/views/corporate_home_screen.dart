import 'package:flutter/material.dart';
import 'package:isport/utils/app_constants.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodels.dart';
import '../viewmodels/company_job_viewmodel.dart';
import '../viewmodels/company_applications_viewmodel.dart';

class CorporateHomeScreen extends StatefulWidget {
  const CorporateHomeScreen({super.key});

  @override
  State<CorporateHomeScreen> createState() => _CorporateHomeScreenState();
}

class _CorporateHomeScreenState extends State<CorporateHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Kurumsal verileri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCorporateData();
    });
  }

  Future<void> _loadCorporateData() async {
    final authViewModel = context.read<AuthViewModel>();
    final companyJobViewModel = context.read<CompanyJobViewModel>();
    final companyApplicationsViewModel = context.read<CompanyApplicationsViewModel>();
    
    if (authViewModel.currentUser != null) {
      // TODO: Gerçek company ID'yi auth'dan al, şimdilik 4 kullanıyoruz
      companyJobViewModel.setCompanyId(4);
      companyApplicationsViewModel.setCompanyId(4);
      
      // Paralel olarak hem iş ilanları hem başvuruları yükle
      await Future.wait([
        companyJobViewModel.fetchCompanyJobs(
          userToken: authViewModel.currentUser!.token,
          isRefresh: true,
        ),
        companyApplicationsViewModel.loadAllData(
          userToken: authViewModel.currentUser!.token,
          isRefresh: true,
        ),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Kurumsal Panel',
          style: AppTextStyles.title.copyWith(color: AppColors.textTitle),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // Bildirimler sayfasına git
            },
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textTitle),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _loadCorporateData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppPaddings.pageHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hoş geldin kartı
              _buildWelcomeCard(),
              
              const SizedBox(height: AppPaddings.section),
              
              // İstatistik kartları
              _buildStatsCards(),
              
              const SizedBox(height: AppPaddings.section),
              
              // Hızlı eylemler
              _buildQuickActions(),
              
              const SizedBox(height: AppPaddings.section),
              
              // Son oluşturulan ilanlar
              _buildRecentJobs(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        final user = authViewModel.currentUser;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppPaddings.card),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.business_center,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hoş Geldiniz',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        Text(
                          user?.userEmail ?? 'Şirket Yetkilisi',
                          style: AppTextStyles.title.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Bugün ${DateTime.now().day} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                style: AppTextStyles.body.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCards() {
    return Consumer2<CompanyJobViewModel, CompanyApplicationsViewModel>(
      builder: (context, companyJobViewModel, companyApplicationsViewModel, child) {
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Aktif İlanlar',
                value: '${companyJobViewModel.activeJobsCount}',
                icon: Icons.work_outline,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Başvurular',
                value: '${companyApplicationsViewModel.totalApplicationsCount}',
                icon: Icons.people_outline,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Yeni Başvuru',
                value: '${companyApplicationsViewModel.newApplicationsCount}',
                icon: Icons.notifications_active,
                color: Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.title.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı İşlemler',
          style: AppTextStyles.subtitle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Yeni İlan',
                subtitle: 'İş ilanı oluştur',
                icon: Icons.add_circle_outline,
                color: AppColors.primary,
                onTap: () {
                  // Yeni ilan oluşturma sayfasına git
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'İlanları Yönet',
                subtitle: 'İlanları görüntüle',
                icon: Icons.list_alt_outlined,
                color: Colors.blue,
                onTap: () {
                  // İlanlar sekmesine geç
                  DefaultTabController.of(context)?.animateTo(1);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Başvurular',
                subtitle: 'Başvuruları incele',
                icon: Icons.folder_open_outlined,
                color: Colors.green,
                onTap: () {
                  // Başvurular sekmesine geç
                  DefaultTabController.of(context)?.animateTo(2);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'Raporlar',
                subtitle: 'İstatistikleri gör',
                icon: Icons.analytics_outlined,
                color: Colors.purple,
                onTap: () {
                  // Raporlar sayfasına git
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.subtitle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentJobs() {
    return Consumer<CompanyJobViewModel>(
      builder: (context, companyJobViewModel, child) {
        final recentJobs = companyJobViewModel.jobs.take(3).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Son İlanlar',
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (companyJobViewModel.hasJobs)
                  TextButton(
                    onPressed: () {
                      // İlanlar sekmesine geç
                      DefaultTabController.of(context)?.animateTo(1);
                    },
                    child: const Text('Tümünü Gör'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (companyJobViewModel.status == CompanyJobStatus.loading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            else if (companyJobViewModel.status == CompanyJobStatus.error)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        companyJobViewModel.errorMessage ?? 'Bir hata oluştu',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              )
            else if (companyJobViewModel.status == CompanyJobStatus.empty || recentJobs.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 48,
                        color: AppColors.textLight.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Henüz ilan yok',
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'İlk ilanınızı oluşturun',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: recentJobs.map((job) => _buildJobItem(job)).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildJobItem(job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: job.isActive ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              job.isActive ? Icons.check_circle_outline : Icons.hourglass_empty,
              color: job.isActive ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.jobTitle,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${job.location} • ${job.workType}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            job.showDate,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month];
  }
} 