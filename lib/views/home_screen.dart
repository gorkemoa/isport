import 'package:flutter/material.dart';
import 'package:isport/utils/app_constants.dart';
import 'package:provider/provider.dart';
import '../viewmodels/job_viewmodel.dart';
import '../viewmodels/auth_viewmodels.dart';
import '../models/job_models.dart';
import 'job_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  

  @override
  void initState() {
    super.initState();
    // İlk iş ilanlarını yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobViewModel>().fetchJobs(isRefresh: true);
    });

    // Sayfa sonuna gelindiğinde daha fazla ilan yükle
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<JobViewModel>().loadMoreJobs();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer2<JobViewModel, AuthViewModel>(
        builder: (context, jobViewModel, authViewModel, child) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => jobViewModel.fetchJobs(isRefresh: true),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Modern App Bar with Welcome Message
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, Color(0xFFF9D71C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(AppPaddings.pageHorizontal),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Merhaba 👋',
                                          style: AppTextStyles.subtitle.copyWith(
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          'Hayalindeki işi bul',
                                          style: AppTextStyles.title.copyWith(
                                            color: Colors.black,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Search Bar
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'İş ara...',
                                    hintStyle: TextStyle(color: Colors.grey[500]),
                                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                                    suffixIcon: Icon(Icons.tune, color: Colors.grey[600]),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    // TODO: Implement search
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Job List
                SliverToBoxAdapter(
                  child: _buildJobListContent(context, jobViewModel),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildJobListContent(BuildContext context, JobViewModel jobViewModel) {
    final status = jobViewModel.status;
    final jobs = jobViewModel.jobs;

    if (status == JobStatus.loading && jobs.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (status == JobStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(jobViewModel.errorMessage ?? 'Bir hata oluştu.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => jobViewModel.fetchJobs(isRefresh: true),
              child: const Text('Yeniden Dene'),
            ),
          ],
        ),
      );
    }

    if (status == JobStatus.empty) {
      return const Center(child: Text('Gösterilecek ilan bulunamadı.'));
    }

    return Padding(
      padding: const EdgeInsets.all(AppPaddings.pageHorizontal / 2),
      child: Column(
        children: [
          // Jobs List Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Önerilen İşler',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Tümünü görüntüle
                  },
                  child: const Text('Tümünü Gör'),
                ),
              ],
            ),
          ),
          // Jobs List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: jobs.length + (jobViewModel.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == jobs.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                );
              }
              return JobCard(job: jobs[index]);
            },
          ),
        ],
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  final Job job;
  const JobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(
          horizontal: AppPaddings.pageHorizontal / 2, vertical: AppPaddings.item / 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      color: AppColors.cardBackground,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // İçeriğin yüksekliğine göre ayarlanmasını sağlar
            backgroundColor: Colors.transparent, // Arka planı transparan yapıp alttaki container'a yetki ver
            builder: (_) => Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: JobDetailBottomSheet(jobId: job.jobID),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppPaddings.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder.withOpacity(0.3)),
                    ),
                    child: Image.network(
                      job.jobImage,
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.business, size: 48, color: AppColors.textLight),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Job Title, Company Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.jobTitle,
                          style: AppTextStyles.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.compName,
                          style: AppTextStyles.company,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                         Text(
                          '${job.jobCity}, ${job.jobDistrict}',
                          style: AppTextStyles.body.copyWith(color: AppColors.textLight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Favorite Button
                  Consumer<JobViewModel>(
                    builder: (context, jobViewModel, child) {
                      return IconButton(
                        splashRadius: 20,
                        icon: Icon(
                          job.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: job.isFavorite ? Colors.redAccent : AppColors.textLight,
                        ),
                        onPressed: () => jobViewModel.toggleJobFavorite(job.jobID),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppPaddings.card),
              // Bottom Info Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildInfoChip(context, Icons.work_outline, job.workType),
                    const SizedBox(width: 8),
                    _buildInfoChip(context, Icons.access_time_outlined, job.showDate),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
} 