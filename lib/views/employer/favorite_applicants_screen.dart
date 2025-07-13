import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/employer_models.dart';
import '../../viewmodels/employer_viewmodel.dart';
import '../../utils/app_constants.dart';
import '../../services/logger_service.dart';

/// Firma favori adayları listeleme ekranı
class FavoriteApplicantsScreen extends StatefulWidget {
  const FavoriteApplicantsScreen({super.key});

  @override
  State<FavoriteApplicantsScreen> createState() => _FavoriteApplicantsScreenState();
}

class _FavoriteApplicantsScreenState extends State<FavoriteApplicantsScreen>
    with TickerProviderStateMixin {
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchActive = false;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    
    // İlk yükleme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployerViewModel>().loadFavoriteApplicants();
    });
    
    // Search controller listener with debounce
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce search to avoid excessive filtering
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.toLowerCase();
          _isSearchActive = _searchQuery.isNotEmpty;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Consumer<EmployerViewModel>(
        builder: (context, employerVM, child) {
          return CustomScrollView(
            slivers: [
              _buildAppBar(employerVM),
              _buildSearchBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildContent(employerVM),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(EmployerViewModel employerVM) {
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Favori Adaylar',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ).animate().fadeIn(duration: 500.ms).slideX(),
                            const SizedBox(height: 2),
                            Text(
                              employerVM.hasFavoriteApplicants
                                  ? '${employerVM.favoriteApplicantsCount} favori aday'
                                  : 'Beğendiğiniz adayları burada görün',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideX(),
                          ],
                        ),
                      ),
                      
                      // Refresh button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: employerVM.isFavoriteApplicantsLoading
                              ? null
                              : () => _refreshData(employerVM),
                          iconSize: 20,
                          icon: AnimatedRotation(
                            turns: employerVM.isRefreshing ? 1 : 0,
                            duration: const Duration(milliseconds: 500),
                            child: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                            ),
                          ),
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

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF374151),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Aday veya iş ilanı ara...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: Colors.grey[500],
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              FocusScope.of(context).unfocus();
                            },
                            icon: Icon(
                              Icons.clear,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Filter button
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => _showFilterBottomSheet(),
                iconSize: 16,
                icon: const Icon(
                  Icons.tune,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: -0.05, end: 0),
    );
  }

  Widget _buildContent(EmployerViewModel employerVM) {
    if (employerVM.isFavoriteApplicantsLoading && employerVM.favoriteApplicantsData == null) {
      return _buildLoadingState();
    }

    if (employerVM.hasFavoriteApplicantsError && employerVM.favoriteApplicantsData == null) {
      return _buildErrorState(employerVM.favoriteApplicantsErrorMessage!, employerVM);
    }

    if (!employerVM.hasFavoriteApplicants) {
      return _buildEmptyState();
    }

    final filteredApplicants = _isSearchActive 
        ? _filterApplicants(employerVM.favoriteApplicantsData!.favorites)
        : employerVM.favoriteApplicantsData!.sortedFavorites;

    if (_isSearchActive && filteredApplicants.isEmpty) {
      return _buildEmptySearchState();
    }

    return RefreshIndicator(
      onRefresh: () => _refreshData(employerVM),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        itemCount: filteredApplicants.length,
        itemBuilder: (context, index) {
          final applicant = filteredApplicants[index];
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 30.0,
              child: FadeInAnimation(
                child: _FavoriteApplicantCard(
                  applicant: applicant,
                  onTap: () => _showApplicantDetail(applicant),
                  onJobTap: () => _showJobDetail(applicant.jobID),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<EmployerFavoriteApplicantModel> _filterApplicants(List<EmployerFavoriteApplicantModel> applicants) {
    return applicants.where((applicant) {
      final nameMatch = applicant.userName.toLowerCase().contains(_searchQuery);
      final jobMatch = applicant.jobTitle.toLowerCase().contains(_searchQuery);
      return nameMatch || jobMatch;
    }).toList();
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Favori adaylar yükleniyor...',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lütfen bekleyin',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildErrorState(String errorMessage, EmployerViewModel employerVM) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.error_outline,
              size: 40,
              color: Colors.red[300],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Bir hata oluştu',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 4),
          
          Text(
            errorMessage,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          ElevatedButton.icon(
            onPressed: () => employerVM.loadFavoriteApplicants(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
            label: Text(
              'Tekrar Dene',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale();
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.favorite_border,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Henüz Favori Aday Yok',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Beğendiğiniz adayları favorilere ekleyerek burada görüntüleyebilirsiniz',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
            label: Text(
              'Geri Dön',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale();
  }

  Widget _buildEmptySearchState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.search_off,
              size: 32,
              color: Colors.grey[400],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Arama Sonucu Bulunamadı',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '"$_searchQuery" için sonuç bulunamadı',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
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
    ).animate().fadeIn(duration: 300.ms);
  }

  Future<void> _refreshData(EmployerViewModel employerVM) async {
    await employerVM.refreshFavoriteApplicants();
  }

  void _showApplicantDetail(EmployerFavoriteApplicantModel applicant) {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          applicant.userInitials,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              applicant.userName,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              applicant.jobTitle,
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
                  
                  const SizedBox(height: 20),
                  
                  _buildInfoRow('Favori Tarihi', applicant.formattedDate),
                  _buildInfoRow('Favori Saati', applicant.formattedTime),
                  
                  const SizedBox(height: 20),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'İş İlanı',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          applicant.jobTitle,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
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

  void _showJobDetail(int jobId) {
    HapticFeedback.lightImpact();
    // Job detail implementation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('İş detayı yakında eklenecek (ID: $jobId)'),
        backgroundColor: AppColors.primary,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Belirtilmemiş',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Favori aday kartı widget'ı
class _FavoriteApplicantCard extends StatelessWidget {
  final EmployerFavoriteApplicantModel applicant;
  final VoidCallback onTap;
  final VoidCallback onJobTap;

  const _FavoriteApplicantCard({
    required this.applicant,
    required this.onTap,
    required this.onJobTap,
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        applicant.userInitials,
                        style: GoogleFonts.inter(
                          fontSize: 16,
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
                            applicant.userName,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF374151),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: onJobTap,
                            child: Text(
                              applicant.jobTitle,
                              style: GoogleFonts.inter(
                                fontSize: 14,
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
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 12,
                            color: Colors.red[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Favori',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.red[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Favori: ${applicant.formattedDate}',
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
} 