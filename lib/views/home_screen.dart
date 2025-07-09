import 'package:flutter/material.dart';
import 'package:isport/utils/app_constants.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodels.dart';
import '../viewmodels/job_viewmodel.dart';
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
      appBar: AppBar(
        title: const Text('İş İlanları'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showUserInfoDialog(context),
            tooltip: 'Kullanıcı Bilgileri',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, context.read<AuthViewModel>()),
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: Consumer<JobViewModel>(
        builder: (context, jobViewModel, child) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => jobViewModel.fetchJobs(isRefresh: true),
            child: _buildJobList(context, jobViewModel),
          );
        },
      ),
    );
  }

  Widget _buildJobList(BuildContext context, JobViewModel jobViewModel) {
    final status = jobViewModel.status;
    final jobs = jobViewModel.jobs;

    if (status == JobStatus.loading) {
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppPaddings.item),
      controller: _scrollController,
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
    );
  }
  
  void _showUserInfoDialog(BuildContext context) {
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kullanıcı Bilgileri'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildInfoRow('Kullanıcı ID:', user.userID.toString()),
                _buildInfoRow('E-posta:', user.userEmail),
                _buildInfoRow('Şirket Hesabı:', user.isComp ? 'Evet' : 'Hayır'),
                _buildInfoRow('Token:', '${user.token.substring(0, 10)}...'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Kapat'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: <TextSpan>[
            TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthViewModel authViewModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Çıkış Yap'),
          content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await authViewModel.logout();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Çıkış Yap'),
            ),
          ],
        );
      },
    );
  }
}

class JobCard extends StatelessWidget {
  final Job job;
  const JobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => JobDetailScreen(jobId: job.jobID),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppPaddings.pageHorizontal, vertical: AppPaddings.item / 2),
        padding: const EdgeInsets.all(AppPaddings.card),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder.withOpacity(0.8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.network(
                  job.jobImage,
                  width: 30,
                  height: 30,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job.jobTitle,
                    style: AppTextStyles.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
              job.compName,
              style: AppTextStyles.company,
            ),
              ],
            ),
            const SizedBox(height: AppPaddings.item / 2),
           Text(
            job.jobDesc,
            style: AppTextStyles.body,
           ),
            const SizedBox(height: AppPaddings.card),
            Row(
              children: [
                _buildIconText(
                    context, Icons.location_on_outlined, '${job.jobCity}, ${job.jobDistrict}'),
                const Spacer(),
                _buildIconText(
                    context, Icons.access_time_outlined, job.showDate),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconText(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textLight),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(color: AppColors.textLight),
          ),
        ),
      ],
    );
  }
} 