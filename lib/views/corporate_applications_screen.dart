import 'package:flutter/material.dart';
import 'package:isport/utils/app_constants.dart';
import 'package:provider/provider.dart';
import '../viewmodels/company_applications_viewmodel.dart';
import '../viewmodels/auth_viewmodels.dart';
import '../models/company_applications_models.dart';

class CorporateApplicationsScreen extends StatefulWidget {
  const CorporateApplicationsScreen({super.key});

  @override
  State<CorporateApplicationsScreen> createState() => _CorporateApplicationsScreenState();
}

class _CorporateApplicationsScreenState extends State<CorporateApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Company applications verilerini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCompanyApplications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCompanyApplications() {
    final authViewModel = context.read<AuthViewModel>();
    final companyApplicationsViewModel = context.read<CompanyApplicationsViewModel>();
    
    if (authViewModel.currentUser != null) {
      // TODO: Gerçek company ID'yi auth'dan al, şimdilik 4 kullanıyoruz
      companyApplicationsViewModel.setCompanyId(4);
      companyApplicationsViewModel.loadAllData(
        userToken: authViewModel.currentUser!.token,
        isRefresh: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Başvuru Yönetimi',
          style: AppTextStyles.title.copyWith(color: AppColors.textTitle),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showSearchDialog,
            icon: const Icon(Icons.search, color: AppColors.textTitle),
          ),
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list, color: AppColors.textTitle),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Tümü'),
            Tab(text: 'Yeni'),
            Tab(text: 'İncelenen'),
            Tab(text: 'Onaylanan'),
            Tab(text: 'Favori Adaylar'),
          ],
        ),
      ),
      body: Column(
        children: [
          // İstatistik kartları
          _buildStatsCards(),
          
          // Başvuru listesi
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllApplicationsList(),
                _buildApplicationsList(1), // Yeni
                _buildApplicationsList(2), // İncelenen
                _buildApplicationsList(3), // Onaylanan
                _buildFavoriteApplicantsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Consumer<CompanyApplicationsViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.all(AppPaddings.pageHorizontal),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard('Toplam', '${viewModel.totalApplicationsCount}', Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Yeni', '${viewModel.newApplicationsCount}', Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Onaylanan', '${viewModel.approvedApplicationsCount}', Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Favoriler', '${viewModel.totalFavoritesCount}', Colors.purple),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: AppTextStyles.title.copyWith(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
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

  Widget _buildAllApplicationsList() {
    return Consumer<CompanyApplicationsViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.status == CompanyApplicationsStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        
        if (viewModel.status == CompanyApplicationsStatus.error) {
          return _buildErrorState(viewModel.errorMessage ?? 'Bir hata oluştu');
        }
        
        List<CompanyApplication> applications = _searchQuery.isEmpty
            ? viewModel.applications
            : viewModel.searchApplications(_searchQuery);
        
        if (applications.isEmpty) {
          return _buildEmptyState('Başvuru bulunamadı', 'Henüz başvuru yapılmamış');
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => _loadCompanyApplications(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppPaddings.pageHorizontal),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              return _buildApplicationCard(applications[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildApplicationsList(int statusId) {
    return Consumer<CompanyApplicationsViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.status == CompanyApplicationsStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        
        if (viewModel.status == CompanyApplicationsStatus.error) {
          return _buildErrorState(viewModel.errorMessage ?? 'Bir hata oluştu');
        }
        
        List<CompanyApplication> applications = viewModel.getApplicationsByStatus(statusId);
        
        if (_searchQuery.isNotEmpty) {
          applications = applications.where((app) => 
              app.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              app.jobTitle.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        }
        
        if (applications.isEmpty) {
          return _buildEmptyState(
            'Bu kategoride başvuru yok',
            _getEmptyMessageForStatus(statusId),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => _loadCompanyApplications(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppPaddings.pageHorizontal),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              return _buildApplicationCard(applications[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildFavoriteApplicantsList() {
    return Consumer<CompanyApplicationsViewModel>(
      builder: (context, viewModel, child) {
        List<FavoriteApplicant> favorites = _searchQuery.isEmpty
            ? viewModel.favoriteApplicants
            : viewModel.searchFavoriteApplicants(_searchQuery);
        
        if (favorites.isEmpty) {
          return _buildEmptyState('Favori aday yok', 'Henüz favori aday eklenmemiş');
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => _loadCompanyApplications(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppPaddings.pageHorizontal),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              return _buildFavoriteCard(favorites[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildApplicationCard(CompanyApplication application) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppPaddings.card),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      color: AppColors.cardBackground,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showApplicationDetail(application),
        child: Padding(
          padding: const EdgeInsets.all(AppPaddings.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      application.userInitial,
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
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
                          style: AppTextStyles.title.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          application.jobTitle,
                          style: AppTextStyles.subtitle.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(application),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                application.shortJobDesc,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Başvuru: ${application.formattedAppliedAt}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _toggleFavorite(application),
                        icon: Icon(
                          application.isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: application.isFavorite ? Colors.red : AppColors.textLight,
                        ),
                      ),
                      if (application.jobStatusID == 1) ...[
                        IconButton(
                          onPressed: () => _approveApplication(application),
                          icon: const Icon(Icons.check_circle_outline, size: 20),
                          color: Colors.green,
                        ),
                        IconButton(
                          onPressed: () => _rejectApplication(application),
                          icon: const Icon(Icons.cancel_outlined, size: 20),
                          color: Colors.red,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(FavoriteApplicant favorite) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppPaddings.card),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppPaddings.card),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.purple.withOpacity(0.1),
              child: Text(
                favorite.userInitial,
                style: AppTextStyles.subtitle.copyWith(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    favorite.userName,
                    style: AppTextStyles.title.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    favorite.jobTitle,
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Favoriye eklendi: ${favorite.formattedFavDate}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _removeFavorite(favorite),
              icon: const Icon(Icons.favorite, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(CompanyApplication application) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: application.statusColorValue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: application.statusColorValue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(application.statusIcon, size: 16, color: application.statusColorValue),
          const SizedBox(width: 4),
          Text(
            application.statusName,
            style: AppTextStyles.caption.copyWith(
              color: application.statusColorValue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.title.copyWith(
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Hata Oluştu',
            style: AppTextStyles.title.copyWith(
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCompanyApplications,
            child: const Text('Yeniden Dene'),
          ),
        ],
      ),
    );
  }

  String _getEmptyMessageForStatus(int statusId) {
    switch (statusId) {
      case 1:
        return 'Yeni başvurular burada görünecek';
      case 2:
        return 'İncelenen başvurular burada görünecek';
      case 3:
        return 'Onaylanan başvurular burada görünecek';
      case 4:
        return 'Reddedilen başvurular burada görünecek';
      default:
        return 'Başvurular burada görünecek';
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Başvuru Ara'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Aday adı veya iş ilanı...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
              Navigator.pop(context);
            },
            child: const Text('Temizle'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    // TODO: Filtreleme seçenekleri
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrele'),
        content: const Text('Filtreleme seçenekleri yakında eklenecek'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showApplicationDetail(CompanyApplication application) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ApplicationDetailView(application: application),
    );
  }

  Future<void> _toggleFavorite(CompanyApplication application) async {
    final authViewModel = context.read<AuthViewModel>();
    final userToken = authViewModel.currentUser?.token;
    
    if (userToken == null) {
      ScaffoldMessenger.of(context).showSnackBar( 
        const SnackBar(content: Text('Kullanıcı bilgisi bulunamadı')),
      );
      return;
    }

    final success = await context.read<CompanyApplicationsViewModel>()
        .toggleApplicationFavorite(application.appID, userToken);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            application.isFavorite 
                ? '${application.userName} favorilerden kaldırıldı'
                : '${application.userName} favorilere eklendi'
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşlem gerçekleştirilemedi')),
      );
    }
  }

  Future<void> _approveApplication(CompanyApplication application) async {
    final authViewModel = context.read<AuthViewModel>();
    final userToken = authViewModel.currentUser?.token;
    
    if (userToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bilgisi bulunamadı')),
      );
      return;
    }

    final success = await context.read<CompanyApplicationsViewModel>()
        .updateApplicationStatusAPI(
          appId: application.appID,
          newStatus: 3, // Onaylandı
          userToken: userToken,
        );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${application.userName} başvurusu onaylandı')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşlem gerçekleştirilemedi')),
      );
    }
  }

  Future<void> _rejectApplication(CompanyApplication application) async {
    final authViewModel = context.read<AuthViewModel>();
    final userToken = authViewModel.currentUser?.token;
    
    if (userToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bilgisi bulunamadı')),
      );
      return;
    }

    final success = await context.read<CompanyApplicationsViewModel>()
        .updateApplicationStatusAPI(
          appId: application.appID,
          newStatus: 4, // Reddedildi
          userToken: userToken,
        );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${application.userName} başvurusu reddedildi')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşlem gerçekleştirilemedi')),
      );
    }
  }

  Future<void> _removeFavorite(FavoriteApplicant favorite) async {
    final authViewModel = context.read<AuthViewModel>();
    final userToken = authViewModel.currentUser?.token;
    
    if (userToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bilgisi bulunamadı')),
      );
      return;
    }

    // İlgili başvuruyu bul
    final companyApplicationsViewModel = context.read<CompanyApplicationsViewModel>();
    final application = companyApplicationsViewModel.applications
        .where((app) => app.userID == favorite.userID && app.jobID == favorite.jobID)
        .firstOrNull;

    if (application == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlgili başvuru bulunamadı')),
      );
      return;
    }

    // Toggle API'sine request at (favori olduğu için çıkarır)
    final success = await companyApplicationsViewModel.toggleApplicationFavorite(
      application.appID, 
      userToken
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${favorite.userName} favorilerden kaldırıldı')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşlem gerçekleştirilemedi')),
      );
    }
  }
}

class ApplicationDetailView extends StatefulWidget {
  final CompanyApplication application;

  const ApplicationDetailView({super.key, required this.application});

  @override
  State<ApplicationDetailView> createState() => _ApplicationDetailViewState();
}

class _ApplicationDetailViewState extends State<ApplicationDetailView> {
  ApplicationDetail? _applicationDetail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadApplicationDetail();
  }

  Future<void> _loadApplicationDetail() async {
    final authViewModel = context.read<AuthViewModel>();
    final userToken = authViewModel.currentUser?.token;
    
    if (userToken == null) {
      setState(() {
        _errorMessage = 'Kullanıcı bilgisi bulunamadı';
        _isLoading = false;
      });
      return;
    }

    try {
      final detail = await context.read<CompanyApplicationsViewModel>()
          .getApplicationDetail(
            appId: widget.application.appID,
            userToken: userToken,
          );
      
      setState(() {
        _applicationDetail = detail;
        _isLoading = false;
        if (detail == null) {
          _errorMessage = 'Başvuru detayı yüklenemedi';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(int newStatus) async {
    final authViewModel = context.read<AuthViewModel>();
    final userToken = authViewModel.currentUser?.token;
    
    if (userToken == null) return;

    final success = await context.read<CompanyApplicationsViewModel>()
        .updateApplicationStatusAPI(
          appId: widget.application.appID,
          newStatus: newStatus,
          userToken: userToken,
        );
    
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Başvuru durumu güncellendi')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşlem gerçekleştirilemedi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppPaddings.pageHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Başvuru Detayı',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Aday Bilgileri
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    application.userInitial,
                    style: AppTextStyles.title.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.userName,
                        style: AppTextStyles.title.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        application.jobTitle,
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(application.statusIcon, size: 16, color: application.statusColorValue),
                          const SizedBox(width: 4),
                          Text(
                            application.statusName,
                            style: AppTextStyles.caption.copyWith(
                              color: application.statusColorValue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // İş İlanı Bilgileri
            _buildSection('İş İlanı', [
              _buildDetailRow('Pozisyon', application.jobTitle),
              _buildDetailRow('Başvuru Tarihi', application.formattedAppliedAt),
              _buildDetailRow('İlan ID', application.jobID.toString()),
            ]),
            
            const SizedBox(height: 16),
            
            // İş Açıklaması
            _buildSection('İş Açıklaması', [
              Text(
                application.jobDesc,
                style: AppTextStyles.body,
              ),
            ]),
            
            const Spacer(),
            
            // Action Buttons
            if (application.jobStatusID == 1) // Sadece bekleyen başvurular için
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<CompanyApplicationsViewModel>().updateApplicationStatus(
                          application.appID, 4, 'Reddedildi', '#F44336',
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Reddet'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<CompanyApplicationsViewModel>().updateApplicationStatus(
                          application.appID, 3, 'Onaylandı', '#4CAF50',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Onayla'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.subtitle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
} 