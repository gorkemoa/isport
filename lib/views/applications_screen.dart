import 'package:flutter/material.dart';
import 'package:isport/utils/app_constants.dart';
import 'package:provider/provider.dart';

import '../models/applications_models.dart';
import '../viewmodels/applications_viewmodel.dart';
import '../viewmodels/auth_viewmodels.dart';
import 'job_detail_screen.dart';
import 'login_screen.dart';

class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ApplicationsViewModel(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: const Text('Başvurularım'),
            bottom: const TabBar(
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: 'Başvurular'),
                Tab(text: 'Favoriler'),
              ],
            ),
          ),
          body: Consumer<ApplicationsViewModel>(
            builder: (context, viewModel, child) {
              // Logout gerekiyorsa ana AuthViewModel'i güncelle ve login ekranına yönlendir
              if (viewModel.needsLogout) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.read<AuthViewModel>().logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                });
              }

              return RefreshIndicator(
                onRefresh: () => viewModel.refreshAll(),
                color: AppColors.primary,
                child: TabBarView(
                  children: [
                    _buildApplicationsTab(context, viewModel),
                    _buildFavoritesTab(context, viewModel),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationsTab(BuildContext context, ApplicationsViewModel viewModel) {
    if (viewModel.isLoadingApplications) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (viewModel.applicationsErrorMessage != null) {
      return _buildError(
        context,
        viewModel.applicationsErrorMessage!,
        () => viewModel.fetchApplications(),
      );
    }

    if (!viewModel.hasApplications) {
      return _buildEmptyState(
        context,
        Icons.work_outline,
        'Henüz başvurunuz yok',
        'İlanlara başvurmaya başlayın.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
          horizontal: AppPaddings.pageHorizontal, vertical: AppPaddings.pageVertical),
      itemCount: viewModel.applications.length,
      itemBuilder: (context, index) {
        final application = viewModel.applications[index];
        return _buildApplicationCard(context, application);
      },
    );
  }

  Widget _buildFavoritesTab(BuildContext context, ApplicationsViewModel viewModel) {
    if (viewModel.isLoadingFavorites) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (viewModel.favoritesErrorMessage != null) {
      return _buildError(
        context,
        viewModel.favoritesErrorMessage!,
        () => viewModel.fetchFavorites(),
      );
    }

    if (!viewModel.hasFavorites) {
      return _buildEmptyState(
        context,
        Icons.favorite_outline,
        'Henüz favori ilanınız yok',
        'İlanları favorilere ekleyerek kolayca ulaşın.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
          horizontal: AppPaddings.pageHorizontal, vertical: AppPaddings.pageVertical),
      itemCount: viewModel.favorites.length,
      itemBuilder: (context, index) {
        final favorite = viewModel.favorites[index];
        return _buildFavoriteCard(context, favorite);
      },
    );
  }

  Widget _buildApplicationCard(BuildContext context, Application application) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppPaddings.item),
      padding: const EdgeInsets.all(AppPaddings.card),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.8)),
      ),
      child: InkWell(
        onTap: () => _navigateToJobDetail(context, application.jobID),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    application.jobTitle,
                    style: AppTextStyles.title,
                  ),
                ),
                const SizedBox(width: AppPaddings.item),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _parseColor(application.statusColor).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    application.statusName,
                    style: AppTextStyles.body.copyWith(
                      color: _parseColor(application.statusColor),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppPaddings.item),
            Text(
              application.jobDesc,
              style: AppTextStyles.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppPaddings.card),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: AppColors.textLight),
                const SizedBox(width: 6),
                Text(
                  'Başvuru: ${application.appliedAt}',
                  style: AppTextStyles.body.copyWith(color: AppColors.textLight, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(BuildContext context, Favorite favorite) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppPaddings.item),
      padding: const EdgeInsets.all(AppPaddings.card),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.8)),
      ),
      child: InkWell(
        onTap: () => _navigateToJobDetail(context, favorite.jobID),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              favorite.jobTitle,
              style: AppTextStyles.title,
            ),
            const SizedBox(height: AppPaddings.item / 2),
            Text(
              favorite.compName,
              style: AppTextStyles.company,
            ),
            const SizedBox(height: AppPaddings.card),
            Text(
              favorite.jobDesc,
              style: AppTextStyles.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppPaddings.card),
            Row(
              children: [
                _buildIconText(Icons.work_outline, favorite.workType),
                const Spacer(),
                _buildIconText(Icons.schedule, favorite.showDate),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppPaddings.pageHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: AppPaddings.card),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(fontSize: 16),
            ),
            const SizedBox(height: AppPaddings.item),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Yeniden Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppColors.textLight.withOpacity(0.5)),
            const SizedBox(height: AppPaddings.card),
            Text(
              title,
              style: AppTextStyles.title.copyWith(color: AppColors.textTitle),
            ),
            const SizedBox(height: AppPaddings.item),
            Text(
              subtitle,
              style: AppTextStyles.body.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToJobDetail(BuildContext context, int jobId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // İçeriğin yüksekliğine göre ayarlanmasını sağlar
      backgroundColor: Colors.transparent, // Arka planı transparan yapıp alttaki container'a yetki ver
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: JobDetailBottomSheet(jobId: jobId),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      // "#FFC107" formatını Color'a çevir
      String hexColor = colorString.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor'; // Alpha değeri ekle
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      // Hata durumunda varsayılan renk döndür
      return Colors.grey;
    }
  }
  
  Widget _buildIconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textLight),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(color: AppColors.textLight, fontSize: 12),
          ),
        ),
      ],
    );
  }
} 