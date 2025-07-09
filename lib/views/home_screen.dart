import 'package:flutter/material.dart';
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
      appBar: AppBar(
        title: const Text('İş İlanları'),
        backgroundColor: Colors.blue[800],
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
      return const Center(child: CircularProgressIndicator());
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
      controller: _scrollController,
      itemCount: jobs.length + (jobViewModel.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == jobs.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
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
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      job.jobImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.business, size: 60, color: Colors.grey);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.jobTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.compName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      job.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: job.isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: () {
                      // Favorilere ekleme/çıkarma fonksiyonu eklenebilir
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildIconText(context, Icons.location_city, '${job.jobCity}, ${job.jobDistrict}'),
                  _buildIconText(context, Icons.work_outline, job.workType),
                  _buildIconText(context, Icons.access_time, job.showDate),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconText(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[800]),
        ),
      ],
    );
  }
} 