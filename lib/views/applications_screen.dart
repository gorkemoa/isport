import 'package:flutter/material.dart';
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
          appBar: AppBar(
            title: const Text('Başvurular'),
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.work_outline), text: 'Başvurularım'),
                Tab(icon: Icon(Icons.favorite_outline), text: 'Favorilerim'),
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
      return const Center(child: CircularProgressIndicator());
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
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.applications.length,
      itemBuilder: (context, index) {
        final application = viewModel.applications[index];
        return _buildApplicationCard(context, application);
      },
    );
  }

  Widget _buildFavoritesTab(BuildContext context, ApplicationsViewModel viewModel) {
    if (viewModel.isLoadingFavorites) {
      return const Center(child: CircularProgressIndicator());
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
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.favorites.length,
      itemBuilder: (context, index) {
        final favorite = viewModel.favorites[index];
        return _buildFavoriteCard(context, favorite);
      },
    );
  }

  Widget _buildApplicationCard(BuildContext context, Application application) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToJobDetail(context, application.jobID),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      application.jobTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _parseColor(application.statusColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      application.statusName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                application.jobDesc,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Başvuru: ${application.appliedAt}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(BuildContext context, Favorite favorite) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToJobDetail(context, favorite.jobID),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                favorite.jobTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                favorite.compName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                favorite.jobDesc,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.work_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    favorite.workType,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    favorite.showDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
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
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToJobDetail(BuildContext context, int jobId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JobDetailScreen(jobId: jobId),
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
} 