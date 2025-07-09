import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/job_detail_models.dart';
import '../services/job_service.dart';
import '../viewmodels/auth_viewmodels.dart';

class JobDetailScreen extends StatefulWidget {
  final int jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late Future<JobDetailResponse> _jobDetailFuture;
  final JobService _jobService = JobService();

  // Kullanıcının favori ve başvuru durumunu yönetmek için state'ler.
  bool? _isFavorite;
  bool? _isApplied;

  @override
  void initState() {
    super.initState();
    _jobDetailFuture = _fetchJobDetail();
  }

  Future<JobDetailResponse> _fetchJobDetail() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final String? token = await authViewModel.getToken();
    final response = await _jobService.getJobDetail(jobId: widget.jobId, userToken: token);

    // Veri geldiğinde state'leri ilk değerleriyle set edelim.
    if (response.success && response.data != null) {
      if (mounted) {
        setState(() {
          _isFavorite = response.data!.job.isFavorite;
          _isApplied = response.data!.job.isApplied;
        });
      }
    }
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<JobDetailResponse>(
      future: _jobDetailFuture,
      builder: (context, snapshot) {
        final JobDetail? job = snapshot.data?.data?.job;

        return Scaffold(
          appBar: AppBar(
            title: const Text('İlan Detayı'),
            actions: job != null && (_isFavorite != null)
                ? [
                    IconButton(
                      icon: Icon(_isFavorite! ? Icons.favorite : Icons.favorite_border),
                      color: _isFavorite! ? Colors.red : null,
                      tooltip: 'Favorilere Ekle',
                      onPressed: () {
                        setState(() {
                          _isFavorite = !_isFavorite!;
                          // TODO: API'ye favori durumunu güncelleme isteği gönderilecek.
                        });
                      },
                    ),
                  ]
                : [],
          ),
          body: _buildBody(snapshot),
          bottomNavigationBar: (job != null && job.isActive && _isApplied != null) ? _buildApplyButton(job) : null,
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<JobDetailResponse> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return _buildError('Bir hata oluştu: ${snapshot.error}');
    }

    if (!snapshot.hasData || !(snapshot.data?.success ?? false) || snapshot.data?.data == null) {
      return _buildError(snapshot.data?.message410 ?? 'İlan detayları getirilemedi.');
    }

    final JobDetail job = snapshot.data!.data!.job;

    if (!job.isActive) {
      return _buildInactiveJob();
    }

    return _buildJobDetail(job);
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _jobDetailFuture = _fetchJobDetail();
                });
              },
              child: const Text('Yeniden Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInactiveJob() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility_off_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Bu ilan artık aktif değil.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobDetail(JobDetail job) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildJobHeader(job),
          const SizedBox(height: 16),
          _buildJobInfo(job),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildSectionTitle('İş Tanımı'),
          const SizedBox(height: 8),
          Text(job.jobDesc, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          if (job.benefits.isNotEmpty) ..._buildBenefitsSection(job),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildDatesSection(job),
          const SizedBox(height: 24),
          _buildDebugInfo(job),
        ],
      ),
    );
  }

  Widget _buildJobHeader(JobDetail job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                job.jobTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            if (job.isHighlighted)
              Chip(
                label: const Text('Öne Çıkan'),
                backgroundColor: Colors.amber.shade100,
                labelStyle: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          job.compName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        Chip(label: Text(job.catName)),
      ],
    );
  }

  Widget _buildJobInfo(JobDetail job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconText(Icons.location_on, '${job.cityName}, ${job.districtName}'),
        const SizedBox(height: 8),
        _buildIconText(Icons.work_outline, job.workType),
        const SizedBox(height: 8),
        _buildIconText(Icons.monetization_on, '${job.salaryMin} - ${job.salaryMax} ${job.salaryType}'),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  List<Widget> _buildBenefitsSection(JobDetail job) {
    return [
      _buildSectionTitle('Yan Haklar'),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: job.benefits
            .map((benefit) => Chip(
                  label: Text(benefit),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                ))
            .toList(),
      ),
    ];
  }

  Widget _buildDatesSection(JobDetail job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('İlan Bilgileri'),
        const SizedBox(height: 12),
        _buildIconText(Icons.calendar_today_outlined, 'Yayın Tarihi: ${job.showDate}'),
        const SizedBox(height: 8),
        _buildIconText(Icons.create_outlined, 'Oluşturma Tarihi: ${job.createDate}'),
      ],
    );
  }

  Widget _buildDebugInfo(JobDetail job) {
    return Text(
      'JobID: ${job.jobID} / CompID: ${job.compID}',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildApplyButton(JobDetail job) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ElevatedButton(
        onPressed: _isApplied!
            ? null
            : () {
                setState(() {
                  _isApplied = true;
                });
                // TODO: API'ye başvuru isteği gönderilecek.
              },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          backgroundColor: Theme.of(context).primaryColor,
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: Text(
          _isApplied! ? 'Başvuruldu' : 'Hemen Başvur',
          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
} 