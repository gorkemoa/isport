import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isport/utils/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/job_models.dart';
import '../../viewmodels/job_viewmodel.dart';
import '../../widget/job_widgets.dart';
import '../../widget/apply_job_bottom_sheet.dart';
import 'job_detail_screen.dart';

/// İş ilanları listesi sayfası
class JobListingScreen extends StatefulWidget {
  const JobListingScreen({super.key});

  @override
  State<JobListingScreen> createState() => _JobListingScreenState();
}

class _JobListingScreenState extends State<JobListingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  List<JobListItem> _filteredJobItems = [];
  bool _isSearchActive = false;
  bool _isInitialLoading = true;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Scroll listener for pagination
    _scrollController.addListener(_onScroll);
    
    // İlk yükleme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
    
    // Search controller listener with debounce
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  void _loadInitialData() async {
    setState(() {
      _isInitialLoading = true;
    });
    
    await context.read<JobViewModel>().loadAllJobListings();
    
    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      final jobVM = context.read<JobViewModel>();
      if (!jobVM.isLoadingMore && jobVM.hasMorePages) {
        jobVM.loadMoreJobs();
      }
    }
  }

  void _onSearchChanged() {
    // Debounce search to avoid excessive filtering
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.toLowerCase();
          _isSearchActive = _searchQuery.isNotEmpty;
          _filterJobs();
        });
      }
    });
  }

  void _filterJobs() {
    final jobVM = context.read<JobViewModel>();
    if (_searchQuery.isEmpty) {
      _filteredJobItems = jobVM.jobListItems;
    } else {
      _filteredJobItems = jobVM.jobListItems.where((job) {
        final companyMatch = job.compName
            .toLowerCase()
            .contains(_searchQuery);
        final cityMatch = job.jobCity
            .toLowerCase()
            .contains(_searchQuery);
        final jobMatch = job.jobTitle.toLowerCase().contains(_searchQuery) ||
            job.workType.toLowerCase().contains(_searchQuery);
        
        return companyMatch || cityMatch || jobMatch;
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Consumer<JobViewModel>(
        builder: (context, jobVM, child) {
          // Her consumer çağrıldığında filtreleme yap
          if (!_isSearchActive) {
            _filteredJobItems = jobVM.jobListItems;
          } else {
            _filterJobs();
          }

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(jobVM),
              _buildSearchBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildContent(jobVM),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(JobViewModel jobVM) {
    return SliverAppBar(
      expandedHeight: 100,
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
                              'İş İlanları',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ).animate().fadeIn(duration: 500.ms).slideX(),
                            const SizedBox(height: 2),
                            Text(
                              jobVM.hasJobListItems
                                  ? '${jobVM.totalItems} aktif ilan'
                                  : 'Yeni fırsatları keşfedin',
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
                          borderRadius: BorderRadius.circular(81),
                        ),
                        child: IconButton(
                          onPressed: jobVM.isLoading
                              ? null
                              : () => _refreshData(),
                          iconSize: 20,
                          icon: AnimatedRotation(
                            turns: jobVM.isRefreshing ? 1 : 0,
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
                    hintText: 'İş, şirket veya şehir ara...',
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
                color:   (AppColors.primary),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color:   (AppColors.primary).withValues(alpha: 0.2),
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

  Widget _buildContent(JobViewModel jobVM) {
    if (_isInitialLoading) {
      return _buildInitialLoadingState();
    }

    if (jobVM.isLoading && jobVM.jobListItems.isEmpty) {
      return _buildLoadingState();
    }

    if (jobVM.hasError && jobVM.jobListItems.isEmpty) {
      return _buildErrorState(jobVM.errorMessage!, jobVM);
    }

    if (!jobVM.hasJobListItems) {
      return const EmptyJobsWidget(
        message: 'Henüz iş ilanı bulunmuyor',
      );
    }

    if (_isSearchActive && _filteredJobItems.isEmpty) {
      return EmptyJobsWidget(
        message: '"$_searchQuery" için sonuç bulunamadı',
        onRetry: () {
          _searchController.clear();
          FocusScope.of(context).unfocus();
        },
      );
    }

    return Column(
      children: [
        _buildTabBar(),
        const SizedBox(height: 12),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildJobsTab(),
              _buildCompaniesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInitialLoadingState() {
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
            'İş ilanları yükleniyor...',
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

  Widget _buildLoadingState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Yenileniyor...',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color:   (AppColors.primary),
          borderRadius: BorderRadius.circular(4),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        indicatorPadding: const EdgeInsets.only(bottom: 0.5, top: 0.5, left: -65, right: -65),
        tabs: const [
          Tab(text: 'İş İlanları'),
          Tab(text: 'Şirketler'),
        ],
      ),
    );
  }

  Widget _buildJobsTab() {
    return RefreshIndicator(
      onRefresh: () => _refreshData(),
      color:   AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 10, left: 8, right: 8),
        itemCount: _filteredJobItems.length + 1, // +1 for loading indicator
        itemBuilder: (context, index) {
          if (index == _filteredJobItems.length) {
            // Loading indicator for pagination
            return Consumer<JobViewModel>(
              builder: (context, jobVM, child) {
                if (jobVM.isLoadingMore && jobVM.hasMorePages) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Daha fazla ilan yükleniyor...',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (jobVM.hasMorePages) {
                  // Load more trigger
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    jobVM.loadMoreJobs();
                  });
                  return const SizedBox.shrink();
                } else if (jobVM.jobListItems.isNotEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Tüm ilanlar yüklendi',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            );
          }

          final job = _filteredJobItems[index];
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 30.0,
              child: FadeInAnimation(
                child: Consumer<JobViewModel>(
                  builder: (context, jobVM, child) {
                    final isFavorite = jobVM.isJobFavorite(job.jobID);
                    final isToggling = jobVM.isJobFavoriteToggling(job.jobID);
                    
                    return JobListItemCard(
                      job: job,
                      onTap: () => _showJobDetail(job),
                      onApply: () => _showApplyBottomSheet(context, job, jobVM),
                      onFavoriteToggle: () => jobVM.toggleJobFavorite(job.jobID, isFavorite),
                      isFavorite: isFavorite,
                      isFavoriteToggling: isToggling,
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompaniesTab() {
    // Şirketleri grupla
    final Map<String, List<JobListItem>> companyGroups = {};
    for (final job in _filteredJobItems) {
      final key = '${job.compID}_${job.compName}';
      if (!companyGroups.containsKey(key)) {
        companyGroups[key] = [];
      }
      companyGroups[key]!.add(job);
    }

    final companyList = companyGroups.values.toList();

    return RefreshIndicator(
      onRefresh: () => _refreshData(),
      color:   (AppColors.primary),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 140, left: 8, right: 8),
        itemCount: companyList.length,
        itemBuilder: (context, index) {
          final companyJobs = companyList[index];
          final firstJob = companyJobs.first;
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 30.0,
              child: FadeInAnimation(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: CompanyCard(
                    company: CompanyDetailModel(
                      compID: firstJob.compID,
                      compName: firstJob.compName,
                      compDesc: '',
                      compAddress: '',
                      compCity: firstJob.jobCity,
                      compDistrict: firstJob.jobDistrict ?? '',
                      profilePhoto: firstJob.jobImage,
                    ),
                    jobCount: companyJobs.length,
                    onTap: () => _showCompanyJobs(companyJobs),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String errorMessage, JobViewModel jobVM) {
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
            onPressed: () => _loadInitialData(),
            style: ElevatedButton.styleFrom(
              backgroundColor:   (AppColors.primary),
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

  Future<void> _refreshData() async {
    await context.read<JobViewModel>().refreshJobListings();
  }

  void _showJobDetail(JobListItem job) {
    HapticFeedback.lightImpact();
    
    JobDetailBottomSheet.show(context, job.jobID);
  }

  void _showApplyBottomSheet(BuildContext context, JobListItem job, JobViewModel jobVM) {
    HapticFeedback.lightImpact();
    
    // Önce job detail'i yükle
    jobVM.loadJobDetail(job.jobID).then((_) {
      if (mounted && jobVM.currentJobDetail != null) {
        ApplyJobBottomSheet.show(
          context,
          jobVM.currentJobDetail!.job,
          jobVM,
        );
      }
    });
  }

  void _showCompanyJobs(List<JobListItem> companyJobs) {
    HapticFeedback.lightImpact();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CompanyJobsScreen(companyJobs: companyJobs),
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
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
                  Text(
                    'Filtreler',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    'Çok yakında daha fazla filtreleme seçeneği eklenecek!',
                    style: GoogleFonts.inter(
                      fontSize: 12,
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

/// Şirket iş ilanları detay sayfası
class _CompanyJobsScreen extends StatelessWidget {
  final List<JobListItem> companyJobs;

  const _CompanyJobsScreen({required this.companyJobs});

  void _showApplyBottomSheetInCompanyScreen(BuildContext context, JobListItem job, JobViewModel jobVM) {
    HapticFeedback.lightImpact();
    
    // Önce job detail'i yükle
    jobVM.loadJobDetail(job.jobID).then((_) {
      if (jobVM.currentJobDetail != null) {
        ApplyJobBottomSheet.show(
          context,
          jobVM.currentJobDetail!.job,
          jobVM,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstJob = companyJobs.first;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          firstJob.compName,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
        itemCount: companyJobs.length,
        itemBuilder: (context, index) {
          final job = companyJobs[index];
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 30.0,
              child: FadeInAnimation(
                child: Consumer<JobViewModel>(
                  builder: (context, jobVM, child) {
                    final isFavorite = jobVM.isJobFavorite(job.jobID);
                    final isToggling = jobVM.isJobFavoriteToggling(job.jobID);
                    
                    return JobListItemCard(
                      job: job,
                      showCompanyInfo: false,
                      onTap: () => JobDetailBottomSheet.show(context, job.jobID),
                      onApply: () => _showApplyBottomSheetInCompanyScreen(context, job, jobVM),
                      onFavoriteToggle: () => jobVM.toggleJobFavorite(job.jobID, isFavorite),
                      isFavorite: isFavorite,
                      isFavoriteToggling: isToggling,
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 