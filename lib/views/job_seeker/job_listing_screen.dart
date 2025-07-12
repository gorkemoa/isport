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
  String _searchQuery = '';
  List<JobListingData> _filteredJobListings = [];
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // İlk yükleme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobViewModel>().loadAllJobs();
    });
    
    // Search controller listener
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _isSearchActive = _searchQuery.isNotEmpty;
      _filterJobs();
    });
  }

  void _filterJobs() {
    final jobVM = context.read<JobViewModel>();
    if (_searchQuery.isEmpty) {
      _filteredJobListings = jobVM.jobListings;
    } else {
      _filteredJobListings = jobVM.jobListings.where((companyData) {
        final companyMatch = companyData.company.compName
            .toLowerCase()
            .contains(_searchQuery);
        final cityMatch = companyData.company.compCity
            .toLowerCase()
            .contains(_searchQuery);
        final jobMatch = companyData.jobs.any((job) =>
            job.jobTitle.toLowerCase().contains(_searchQuery) ||
            job.workType.toLowerCase().contains(_searchQuery));
        
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
            _filteredJobListings = jobVM.jobListings;
          } else {
            _filterJobs();
          }

          return CustomScrollView(
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
                              jobVM.hasJobs
                                  ? '${jobVM.totalJobCount} aktif ilan'
                                  : 'Yeni fırsatları keşfedin',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideX(),
                          ],
                        ),
                      ),
                      
                      // Refresh button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(81),
                        ),
                        child: IconButton(
                          onPressed: jobVM.isLoading
                              ? null
                              : () => jobVM.refreshJobs(),
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
                      color: Colors.black.withOpacity(0.02),
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
                    color:   (AppColors.primary).withOpacity(0.2),
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
    if (jobVM.isLoading) {
      return const JobLoadingShimmer(itemCount: 5);
    }

    if (jobVM.hasError) {
      return _buildErrorState(jobVM.errorMessage!, jobVM);
    }

    if (!jobVM.hasJobs) {
      return const EmptyJobsWidget(
        message: 'Henüz iş ilanı bulunmuyor',
      );
    }

    if (_isSearchActive && _filteredJobListings.isEmpty) {
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
    final allJobs = <Widget>[];
    
    for (int companyIndex = 0; companyIndex < _filteredJobListings.length; companyIndex++) {
      final companyData = _filteredJobListings[companyIndex];
      
      for (int jobIndex = 0; jobIndex < companyData.jobs.length; jobIndex++) {
        final job = companyData.jobs[jobIndex];
        
        allJobs.add(
          AnimationConfiguration.staggeredList(
            position: allJobs.length,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 30.0,
              child: FadeInAnimation(
                child: Consumer<JobViewModel>(
                  builder: (context, jobVM, child) {
                    final isFavorite = jobVM.isJobFavorite(job.jobID);
                    final isToggling = jobVM.isJobFavoriteToggling(job.jobID);
                    
                    return JobCard(
                      job: job,
                      company: companyData.company,
                      onTap: () => _showJobDetail(job, companyData.company),
                      onApply: () => _showApplyBottomSheet(context, job, jobVM),
                      onFavoriteToggle: () => jobVM.toggleJobFavorite(job.jobID, isFavorite),
                      isFavorite: isFavorite,
                      isFavoriteToggling: isToggling,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: () => context.read<JobViewModel>().refreshJobs(),
      color:   AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 10, left: 8, right: 8),
        children: allJobs.isNotEmpty ? allJobs : [
          const EmptyJobsWidget(message: 'İş ilanı bulunamadı'),
        ],
      ),
    );
  }

  Widget _buildCompaniesTab() {
    return RefreshIndicator(
      onRefresh: () => context.read<JobViewModel>().refreshJobs(),
      color:   (AppColors.primary),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 140, left: 8, right: 8),
        itemCount: _filteredJobListings.length,
        itemBuilder: (context, index) {
          final companyData = _filteredJobListings[index];
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 30.0,
              child: FadeInAnimation(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: CompanyCard(
                    company: companyData.company,
                    jobCount: companyData.jobs.length,
                    onTap: () => _showCompanyJobs(companyData),
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
            onPressed: () => jobVM.loadAllJobs(),
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

  void _showJobDetail(JobModel job, CompanyDetailModel company) {
    HapticFeedback.lightImpact();
    
    JobDetailBottomSheet.show(context, job.jobID);
  }

  void _showApplyBottomSheet(BuildContext context, JobModel job, JobViewModel jobVM) {
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





  void _showCompanyJobs(JobListingData companyData) {
    HapticFeedback.lightImpact();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CompanyJobsScreen(companyData: companyData),
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
  final JobListingData companyData;

  const _CompanyJobsScreen({required this.companyData});

  void _showApplyBottomSheetInCompanyScreen(BuildContext context, JobModel job, JobViewModel jobVM) {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          companyData.company.compName,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
        ),
      
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
        itemCount: companyData.jobs.length,
        itemBuilder: (context, index) {
          final job = companyData.jobs[index];
          
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
                    
                    return JobCard(
                      job: job,
                      company: companyData.company,
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