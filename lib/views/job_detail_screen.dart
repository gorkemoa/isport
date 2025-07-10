import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:isport/utils/app_constants.dart';
import 'package:isport/viewmodels/job_viewmodel.dart';
import 'package:provider/provider.dart';

import '../models/job_detail_models.dart';
import '../services/job_service.dart';
import '../viewmodels/auth_viewmodels.dart';
import 'company_detail_screen.dart';

class JobDetailBottomSheet extends StatefulWidget {
  final int jobId;
  const JobDetailBottomSheet({super.key, required this.jobId});

  @override
  State<JobDetailBottomSheet> createState() => _JobDetailBottomSheetState();
}

class _JobDetailBottomSheetState extends State<JobDetailBottomSheet> {
  late Future<JobDetailResponse> _jobDetailFuture;
  final JobService _jobService = JobService();

  @override
  void initState() {
    super.initState();
    final token = context.read<AuthViewModel>().currentUser?.token;
    _jobDetailFuture = _jobService.getJobDetail(jobId: widget.jobId, userToken: token);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) {
        return FutureBuilder<JobDetailResponse>(
          future: _jobDetailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data?.data?.job == null) {
              return Center(
                child: Text(
                  'İlan detayı yüklenemedi: ${snapshot.error ?? "Veri yok"}',
                  textAlign: TextAlign.center,
                ),
              );
            }

            final jobDetail = snapshot.data!.data!.job;

            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    children: [
                      _buildHeaderBar(context),
                      Expanded(
                        child: ListView(
                          controller: controller,
                          padding: const EdgeInsets.symmetric(horizontal: AppPaddings.pageHorizontal),
                          children: [
                            _buildCompanyHeader(context, jobDetail),
                            const SizedBox(height: AppPaddings.pageVertical),
                            _buildJobInfo(context, jobDetail),
                            const SizedBox(height: AppPaddings.item),
                            const Divider(color: AppColors.cardBorder),
                            const SizedBox(height: AppPaddings.item),
                            _buildJobDetailsHtml(context, jobDetail),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (jobDetail.isActive) ApplyButton(jobId: jobDetail.jobID),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyHeader(BuildContext context, JobDetail jobDetail) {
    return Row(
      children: [
        Image.network(
          jobDetail.profilePhoto,
          width: 60,
          height: 60,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.business, size: 60, color: AppColors.textLight),
        ),
        const SizedBox(width: AppPaddings.card),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                jobDetail.jobTitle,
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () {
                  if (jobDetail.compID > 0) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => CompanyDetailScreen(companyId: jobDetail.compID),
                    ));
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        jobDetail.compName,
                        style: AppTextStyles.company.copyWith(color: AppColors.primary),
                      ),
                    ),
                    if (jobDetail.compID > 0)
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.primary,
                        size: 20,
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJobInfo(BuildContext context, JobDetail jobDetail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconText(Icons.location_on_outlined, '${jobDetail.cityName}, ${jobDetail.districtName}'),
        const SizedBox(height: AppPaddings.card),
        _buildIconText(Icons.work_outline, jobDetail.workType),
        const SizedBox(height: AppPaddings.card),
        _buildIconText(Icons.monetization_on_outlined, '${jobDetail.salaryMin} - ${jobDetail.salaryMax} ${jobDetail.salaryType}'),
      ],
    );
  }

  Widget _buildJobDetailsHtml(BuildContext context, JobDetail jobDetail) {
    return Html(
      data: jobDetail.jobDesc,
      style: {
        "body": Style(
          fontSize: FontSize.medium,
          color: AppColors.textTitle,
          padding: HtmlPaddings.zero,
          margin: Margins.zero,
        ),
        "p": Style(
          fontSize: FontSize.medium,
          color: AppColors.textTitle,
          padding: HtmlPaddings.zero,
          margin: Margins.zero,
        ),
        "ul": Style(
          padding: HtmlPaddings.only(left: 20),
          margin: Margins.symmetric(vertical: 10),
        ),
        "li": Style(
          margin: Margins.only(bottom: 5),
          lineHeight: LineHeight.normal,
        ),
      },
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textLight, size: 18),
        const SizedBox(width: AppPaddings.item),
        Expanded(child: Text(text, style: AppTextStyles.body)),
      ],
    );
  }
}

class ApplyButton extends StatelessWidget {
  final int jobId;
  const ApplyButton({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final jobViewModel = context.watch<JobViewModel>();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppPaddings.pageHorizontal, vertical: AppPaddings.item),
        decoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: authViewModel.isAuthenticated && !jobViewModel.isApplying
              ? () async {
                  final success = await jobViewModel.applyToJob(
                    jobId: jobId,
                    token: authViewModel.currentUser!.token,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Başvurunuz başarıyla gönderildi!'
                              : jobViewModel.errorMessage ?? 'Başvuru yapılamadı.',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                    if (success) {
                      Navigator.of(context).pop();
                    }
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: jobViewModel.isApplying
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                )
              : const Text(
                  'Başvur',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
} 