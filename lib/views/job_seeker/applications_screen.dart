import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/application_models.dart';
import '../../models/favorites_models.dart';
import '../../viewmodels/application_viewmodel.dart';
import '../../viewmodels/favorites_viewmodel.dart';
import '../../utils/app_constants.dart';
import 'job_detail_screen.dart';
import 'company/company_detail_screen.dart';

/// Başvurular ve Favoriler listeleme ekranı
class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen>
    with TickerProviderStateMixin {
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchActive = false;
  late TabController _mainTabController;
  late TabController _applicationsTabController;
  
  // Ana tab indeksleri
  static const int _applicationsTab = 0;
  static const int _favoritesTab = 1;
  
  // Başvurular alt tab indeksleri
  static const int _allApplicationsTab = 0;
  static const int _pendingTab = 1;
  static const int _acceptedTab = 2;
  static const int _rejectedTab = 3;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _applicationsTabController = TabController(length: 4, vsync: this);
    
    // İlk yükleme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApplicationViewModel>().loadApplications();
      // User ID'yi doğru şekilde al - bu örnek için 2 kullanıyorum
      context.read<FavoritesViewModel>().loadFavorites(2);
    });
    
    // Search controller listener
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _applicationsTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _isSearchActive = _searchQuery.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Consumer2<ApplicationViewModel, FavoritesViewModel>(
        builder: (context, appVM, favVM, child) {
          return CustomScrollView(
            slivers: [
              _buildAppBar(appVM, favVM),
              _buildMainTabBar(),
              _buildSearchBar(),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _mainTabController,
                  children: [
                    _buildApplicationsContent(appVM),
                    _buildFavoritesContent(favVM),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(ApplicationViewModel appVM, FavoritesViewModel favVM) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                Color(0xFF6366F1),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Başvurularım & Favorilerim',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ).animate().fadeIn(duration: 500.ms).slideX(),
                            const SizedBox(height: 2),
                            Text(
                              '${appVM.applicationCount} başvuru • ${favVM.favoriteCount} favori',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideX(),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _mainTabController.index == 0 ? Icons.work_outline : Icons.favorite_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                      ).animate().fadeIn(delay: 300.ms, duration: 500.ms).scale(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainTabBar() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _mainTabController.animateTo(0);
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _mainTabController.index == 0 ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _mainTabController.index == 0 ? AppColors.primary : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 16,
                            color: _mainTabController.index == 0 ? Colors.white : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Başvurular',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _mainTabController.index == 0 ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _mainTabController.animateTo(1);
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _mainTabController.index == 1 ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _mainTabController.index == 1 ? AppColors.primary : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_outline,
                            size: 16,
                            color: _mainTabController.index == 1 ? Colors.white : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Favoriler',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _mainTabController.index == 1 ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: -0.05, end: 0),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF374151),
                  ),
                  decoration: InputDecoration(
                    hintText: _mainTabController.index == 0 ? 'Başvuru ara...' : 'Favori ara...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[500],
                      size: 18,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              FocusScope.of(context).unfocus();
                            },
                            icon: Icon(
                              Icons.clear,
                              color: Colors.grey[500],
                              size: 16,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(top: 13, bottom: 0, left: 12, right: 12), 
  
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: IconButton(
                onPressed: () => _showFilterBottomSheet(),
                iconSize: 14,
                icon: const Icon(
                  Icons.tune,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: -0.05, end: 0),
    );
  }

  Widget _buildApplicationsContent(ApplicationViewModel appVM) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          if (appVM.hasApplications) ...[
            _buildApplicationsTabBar(appVM),
            const SizedBox(height: 12),
          ],
          Flexible(
            child: _buildApplicationsTabView(appVM),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsTabBar(ApplicationViewModel appVM) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TabBar(
        controller: _applicationsTabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(4),
        ),
        indicatorPadding: const EdgeInsets.only(bottom: 0, top: 0, left: -15, right: -15),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(text: 'Tümü (${appVM.applicationCount})'),
          Tab(text: 'Yeni (${appVM.statusCounts['Yeni Başvuru'] ?? 0})'),
          Tab(text: 'Kabul (${appVM.statusCounts['Kabul Edildi'] ?? 0})'),
          Tab(text: 'Red (${appVM.statusCounts['Red Edildi'] ?? 0})'),
        ],
      ),
    );
  }

  Widget _buildApplicationsTabView(ApplicationViewModel appVM) {
    if (appVM.isLoading) {
      return _buildLoadingState();
    }

    if (appVM.hasError) {
      return _buildErrorState(appVM.errorMessage!, () => appVM.loadApplications(forceRefresh: true));
    }

    if (!appVM.hasApplications) {
      return _buildEmptyApplicationsState();
    }

    final filteredApplications = _isSearchActive 
        ? appVM.searchApplications(_searchQuery)
        : appVM.applications;

    if (_isSearchActive && filteredApplications.isEmpty) {
      return _buildEmptySearchState();
    }

    return TabBarView(
      controller: _applicationsTabController,
      children: [
        _buildApplicationsList(filteredApplications),
        _buildApplicationsList(filteredApplications.where((app) => app.statusName.contains('Yeni')).toList()),
        _buildApplicationsList(filteredApplications.where((app) => app.statusName.contains('Kabul')).toList()),
        _buildApplicationsList(filteredApplications.where((app) => app.statusName.contains('Red')).toList()),
      ],
    );
  }

  Widget _buildFavoritesContent(FavoritesViewModel favVM) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Flexible(
        child: _buildFavoritesView(favVM),
      ),
    );
  }

  Widget _buildFavoritesView(FavoritesViewModel favVM) {
    if (favVM.isLoading) {
      return _buildLoadingState();
    }

    if (favVM.hasError) {
      return _buildErrorState(favVM.errorMessage!, () => favVM.loadFavorites(2, useCache: false));
    }

    if (!favVM.hasFavorites) {
      return _buildEmptyFavoritesState();
    }

    final filteredFavorites = _isSearchActive 
        ? favVM.searchFavorites(_searchQuery)
        : favVM.filteredFavorites;

    if (_isSearchActive && filteredFavorites.isEmpty) {
      return _buildEmptySearchState();
    }

    return RefreshIndicator(
      onRefresh: () => favVM.refreshFavorites(2),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        itemCount: filteredFavorites.length,
        itemBuilder: (context, index) {
          final favorite = filteredFavorites[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 30.0,
              child: FadeInAnimation(
                child: _FavoriteCard(
                  favorite: favorite,
                  onTap: () => _showJobDetail(favorite.jobID),
                  onToggleFavorite: () => favVM.toggleJobFavorite(favorite.jobID),
                  onCompanyTap: () => _showCompanyDetail(favorite.compID),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildApplicationsList(List<ApplicationModel> applications) {
    if (applications.isEmpty) {
      return const SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.work_off_outlined,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 12),
              Text(
                'Bu kategoride başvuru bulunamadı',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<ApplicationViewModel>().refreshApplications(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        itemCount: applications.length,
        itemBuilder: (context, index) {
          final application = applications[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 30.0,
              child: FadeInAnimation(
                child: _ApplicationCard(
                  application: application,
                  onTap: () => _showJobDetail(application.jobID),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Hata Oluştu',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
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
      ),
    );
  }

  Widget _buildEmptyApplicationsState() {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_off_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz Başvuru Yok',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İş ilanlarına başvurduğunuzda burada görüntülenecek',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final tabController = DefaultTabController.of(context);
                tabController?.animateTo(1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'İş Ara',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFavoritesState() {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz Favori Yok',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Beğendiğiniz iş ilanlarını favorilere ekleyerek burada görüntüleyebilirsiniz',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final tabController = DefaultTabController.of(context);
                tabController?.animateTo(1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'İş Ara',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Arama Sonucu Bulunamadı',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"$_searchQuery" için sonuç bulunamadı',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _searchController.clear();
                FocusScope.of(context).unfocus();
              },
              child: Text(
                'Aramayı Temizle',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJobDetail(int jobId) {
    HapticFeedback.lightImpact();
    JobDetailBottomSheet.show(context, jobId);
  }

  void _showCompanyDetail(int companyId) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyDetailScreen(companyId: companyId),
      ),
    );
  }

  void _showFilterBottomSheet() {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Filtreleme',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Gelişmiş filtreleme özellikleri yakında eklenecek!',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Başvuru kartı widget'ı
class _ApplicationCard extends StatelessWidget {
  final ApplicationModel application;
  final VoidCallback onTap;

  const _ApplicationCard({
    required this.application,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            application.jobTitle,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF374151),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            application.jobDesc,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(application.statusName, application.statusColor),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Başvuru: ${application.appliedAt}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, String colorHex) {
    Color statusColor;
    try {
      statusColor = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: statusColor,
        ),
      ),
    );
  }
}

/// Favori kartı widget'ı
class _FavoriteCard extends StatelessWidget {
  final FavoriteJobModel favorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onCompanyTap;

  const _FavoriteCard({
    required this.favorite,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onCompanyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Company avatar
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          favorite.companyInitials,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            favorite.jobTitle,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF374151),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          InkWell(
                            onTap: onCompanyTap,
                            child: Text(
                              favorite.compName,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    IconButton(
                      onPressed: onToggleFavorite,
                      icon: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 6),
                
                Text(
                  favorite.shortDescription,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: favorite.workTypeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        favorite.workType,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: favorite.workTypeColor,
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    Text(
                      favorite.showDate,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 