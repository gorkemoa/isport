import 'package:flutter/material.dart';
import 'package:isport/utils/app_constants.dart';
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
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(job?.jobTitle ?? 'İlan Detayı'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: job != null && (_isFavorite != null)
                ? [
                    IconButton(
                      icon: Icon(_isFavorite! ? Icons.favorite : Icons.favorite_border),
                      color: _isFavorite! ? Colors.redAccent : Colors.white,
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
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
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
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.body),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _jobDetailFuture = _fetchJobDetail();
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Yeniden Dene', style: TextStyle(color: Colors.white)),
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
            Icon(Icons.visibility_off_outlined, size: 80, color: AppColors.textLight),
            const SizedBox(height: 16),
            const Text(
              'Bu ilan artık aktif değil.',
              style: AppTextStyles.title,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobDetail(JobDetail job) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppPaddings.pageVertical),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPaddings.pageHorizontal),
            child: _buildJobHeader(job),
          ),
          const SizedBox(height: AppPaddings.pageVertical),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPaddings.pageHorizontal),
            child: _buildJobInfo(job),
          ),
          const SizedBox(height: AppPaddings.pageVertical),
          const Divider(height: 1),
          const SizedBox(height: AppPaddings.pageVertical),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPaddings.pageHorizontal),
            child: _buildSectionTitle('İş Tanımı'),
          ),
          const SizedBox(height: AppPaddings.item),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPaddings.pageHorizontal),
            child: Text(job.jobDesc, style: AppTextStyles.body),
          ),
          const SizedBox(height: AppPaddings.pageVertical),
          if (job.benefits.isNotEmpty) ..._buildBenefitsSection(job),
          const SizedBox(height: AppPaddings.pageVertical),
          const Divider(height: 1),
          const SizedBox(height: AppPaddings.pageVertical),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPaddings.pageHorizontal),
            child: _buildDatesSection(job),
          ),
          const SizedBox(height: AppPaddings.pageVertical),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPaddings.pageHorizontal),
            child: _buildDebugInfo(job),
          ),
          const SizedBox(height: 100), // for bottom nav bar spacing
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
                style: AppTextStyles.title.copyWith(fontSize: 24),
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
        const SizedBox(height: 12),
        Text(
          job.compName,
          style: AppTextStyles.company.copyWith(fontSize: 18, color: AppColors.textBody),
        ),
        const SizedBox(height: 12),
        Chip(
          label: Text(job.catName),
          backgroundColor: AppColors.primary.withOpacity(0.1),
          labelStyle: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildJobInfo(JobDetail job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconText(Icons.location_on_outlined, '${job.cityName}, ${job.districtName}'),
        const SizedBox(height: AppPaddings.card),
        _buildIconText(Icons.work_outline, job.workType),
        const SizedBox(height: AppPaddings.card),
        _buildIconText(Icons.monetization_on_outlined, '${job.salaryMin} - ${job.salaryMax} ${job.salaryType}'),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.title,
    );
  }

  List<Widget> _buildBenefitsSection(JobDetail job) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppPaddings.pageHorizontal),
        child: _buildSectionTitle('Yan Haklar'),
      ),
      const SizedBox(height: AppPaddings.item),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppPaddings.pageHorizontal),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: job.benefits
              .map((benefit) => Chip(
                    label: Text(benefit),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    labelStyle: AppTextStyles.body.copyWith(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ))
              .toList(),
        ),
      ),
    ];
  }

  Widget _buildDatesSection(JobDetail job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('İlan Bilgileri'),
        const SizedBox(height: AppPaddings.card),
        _buildIconText(Icons.calendar_today_outlined, 'Yayın Tarihi: ${job.showDate}'),
        const SizedBox(height: AppPaddings.card),
        _buildIconText(Icons.create_outlined, 'Oluşturma Tarihi: ${job.createDate}'),
      ],
    );
  }

  Widget _buildDebugInfo(JobDetail job) {
    return Text(
      'JobID: ${job.jobID} / CompID: ${job.compID}',
      style: AppTextStyles.body.copyWith(color: AppColors.textLight.withOpacity(0.7)),
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body,
          ),
        ),
      ],
    );
  }

  Widget _buildApplyButton(JobDetail job) {
    return Container(
      padding: const EdgeInsets.all(AppPaddings.pageHorizontal),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
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
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.textLight.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          _isApplied! ? 'Başvuruldu' : 'Hemen Başvur',
          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
} 