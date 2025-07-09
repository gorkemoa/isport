import 'package:flutter/material.dart';
import 'package:isport/utils/app_constants.dart';
import 'package:provider/provider.dart';

import '../models/job_detail_models.dart';
import '../services/job_service.dart';
import '../viewmodels/auth_viewmodels.dart';

class JobDetailBottomSheet extends StatefulWidget {
  final int jobId;
  const JobDetailBottomSheet({super.key, required this.jobId});

  @override
  State<JobDetailBottomSheet> createState() => _JobDetailBottomSheetState();
}

class _JobDetailBottomSheetState extends State<JobDetailBottomSheet> {
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
    // Provider'ı dinlemeden alalım çünkü sadece bir kez token'a ihtiyacımız var.
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
    // Bottom sheet için genel bir yapı
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: FutureBuilder<JobDetailResponse>(
        future: _jobDetailFuture,
        builder: (context, snapshot) {
          final JobDetail? job = snapshot.data?.data?.job;

          return Column(
            children: [
              _buildDragHandle(),
              Expanded(
                child: _buildBody(snapshot, job),
              ),
              if (job != null && job.isActive && _isApplied != null) _buildApplyButton(job),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 5,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Future<void> _toggleFavorite(int jobID) async {
    if (_isFavorite == null) return;

    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final String? token = await authViewModel.getToken();
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giriş yapmanız gerekiyor.')),
        );
        return;
      }

      // Optimistic update - UI'ı hemen güncelle
      final currentStatus = _isFavorite!;
      setState(() {
        _isFavorite = !currentStatus;
      });

      // API çağrısını yap
      final response = currentStatus
          ? await _jobService.removeJobFromFavorites(userToken: token, jobID: jobID)
          : await _jobService.addJobToFavorites(userToken: token, jobID: jobID);

      if (response.success) {
        // Başarılı, snackbar göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? (currentStatus ? 'Favorilerden kaldırıldı.' : 'Favorilere eklendi.')),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        // Başarısız, geri al
        setState(() {
          _isFavorite = currentStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Favori durumu güncellenemedi.'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } catch (e) {
      // Hata durumunda geri al
      setState(() {
        _isFavorite = !_isFavorite!;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bir hata oluştu: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Widget _buildBody(AsyncSnapshot<JobDetailResponse> snapshot, JobDetail? job) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (snapshot.hasError) {
      return _buildError('Bir hata oluştu: ${snapshot.error}');
    }

    if (!snapshot.hasData || !(snapshot.data?.success ?? false) || snapshot.data?.data == null) {
      return _buildError(snapshot.data?.message410 ?? 'İlan detayları getirilemedi.');
    }

    if (!job!.isActive) {
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
          const SizedBox(height: 20),
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
                style: AppTextStyles.title.copyWith(fontSize: 22),
              ),
            ),
            const SizedBox(width: 8),
            if (_isFavorite != null)
              IconButton(
                icon: Icon(_isFavorite! ? Icons.favorite : Icons.favorite_border),
                color: _isFavorite! ? Colors.redAccent : AppColors.textLight,
                tooltip: 'Favorilere Ekle',
                onPressed: () async {
                  await _toggleFavorite(job.jobID);
                },
              ),
          ],
        ),
        if (job.isHighlighted)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Chip(
              label: const Text('Öne Çıkan'),
              backgroundColor: Colors.amber.shade100,
              labelStyle: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        const SizedBox(height: 8),
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
        border: Border(top: BorderSide(color: AppColors.cardBorder.withOpacity(0.5))),
      ),
      child: SafeArea(
        top: false,
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
      ),
    );
  }
} 