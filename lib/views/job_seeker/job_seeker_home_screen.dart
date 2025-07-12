import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isport/utils/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../login_screen.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../models/user_model.dart';
import 'job_listing_screen.dart';
import 'applications_screen.dart';
import 'job_seeker_profile_screen.dart';

class JobSeekerHomeScreen extends StatefulWidget {
  const JobSeekerHomeScreen({super.key});

  @override
  State<JobSeekerHomeScreen> createState() => _JobSeekerHomeScreenState();
}

class _JobSeekerHomeScreenState extends State<JobSeekerHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Kullanıcı verilerini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().loadUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Consumer<ProfileViewModel>(
        builder: (context, profileVM, child) {
          return CustomScrollView(
            slivers: [
              _buildAppBar(profileVM),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (profileVM.isLoading) 
                      _buildLoadingShimmer()
                    else if (profileVM.user != null) ...[
                      _buildWelcomeCard(profileVM.user!),
                      const SizedBox(height: 16),
                      _buildQuickActions(),
                      const SizedBox(height: 16),
                      _buildStatsSection(profileVM.user!),
                      const SizedBox(height: 16),
                    ] else
                      _buildErrorState(profileVM.errorMessage),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(ProfileViewModel profileVM) {
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
                  Text(
                    'İş Arayan Paneli',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideX(),
                  const SizedBox(height: 2),
                  Text(
                    'Kariyerinizi şekillendirin',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideX(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(UserModel user) {
    return AnimationConfiguration.staggeredList(
      position: 0,
      duration: const Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 30.0,
        child: FadeInAnimation(
          child: Container(
            padding: const EdgeInsets.all(16),
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
              border: Border.all(color: Colors.grey.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF6366F1)],
                    ),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color:   (AppColors.primary).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: user.profilePhoto.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: user.profilePhoto,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.person,
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
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        user.userFullname,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      if (user.isComp && user.company != null)
                        Text(
                          user.company!.compName,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color:   (AppColors.primary),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.userStatus == 'activated' 
                        ? const Color(0xFF059669).withOpacity(0.1)
                        : const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.userStatus == 'activated' ? 'Aktif' : 'Onay Bekliyor',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: user.userStatus == 'activated' 
                          ? const Color(0xFF059669)
                          : const Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.search, 'title': 'İş Ara', 'color':   (AppColors.primary)},
      {'icon': Icons.work_outline, 'title': 'Başvurularım', 'color': const Color(0xFF059669)},
      {'icon': Icons.person_outline, 'title': 'Profil', 'color': const Color(0xFFD97706)},
      {'icon': Icons.message_outlined, 'title': 'Mesajlar', 'color': const Color(0xFFDC2626)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı İşlemler',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(0),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 500),
              columnCount: 2,
              child: SlideAnimation(
                verticalOffset: 30.0,
                child: FadeInAnimation(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      
                      switch (action['title']) {
                        case 'İş Ara':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const JobListingScreen(),
                            ),
                          );
                          break;
                        case 'Başvurularım':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ApplicationsScreen(),
                            ),
                          );
                          break;
                        case 'Profil':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const JobSeekerProfileScreen(),
                            ),
                          );
                          break;
                        case 'Mesajlar':
                          _showComingSoonDialog('Mesajlar');
                          break;
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
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
                         border: Border.all(color: Colors.grey.withOpacity(0.15)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: (action['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              action['icon'] as IconData,
                              color: action['color'] as Color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            action['title'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatsSection(UserModel user) {
    return AnimationConfiguration.staggeredList(
      position: 2,
      duration: const Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 30.0,
        child: FadeInAnimation(
          child: Container(
            padding: const EdgeInsets.all(16),
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
              border: Border.all(color: Colors.grey.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'İstatistikler',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Rank', user.userRank,   (AppColors.primary)),
                    _buildStatItem('Başvuru', '12', const Color(0xFF059669)),
                    _buildStatItem('Görüntüleme', '45', const Color(0xFFD97706)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }


  
  Widget _buildLoadingShimmer() {
    return Column(
      children: List.generate(3, (index) => 
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String? errorMessage) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Bir hata oluştu',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            errorMessage ?? 'Bilinmeyen hata',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              context.read<ProfileViewModel>().loadUserProfile();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:   (AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'Tekrar Dene',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Yakında gelecek özellikler için dialog gösterir
  void _showComingSoonDialog(String featureName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                featureName,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
          ),
          content: Text(
            'Bu özellik yakında eklenecek! Geliştirme sürecinde olduğu için biraz daha bekleyiniz.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Tamam',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
} 