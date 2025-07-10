import 'package:flutter/material.dart';
import 'package:isport/models/company_detail_model.dart';
import 'package:isport/utils/app_constants.dart';
import 'package:isport/viewmodels/company_detail_viewmodel.dart';
import 'package:isport/views/job_detail_screen.dart';
import 'package:provider/provider.dart';

class CompanyDetailScreen extends StatelessWidget {
  final int companyId;
  const CompanyDetailScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CompanyDetailViewModel(companyId: companyId),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Consumer<CompanyDetailViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            if (viewModel.errorMessage != null) {
              return Center(child: Text(viewModel.errorMessage!));
            }

            if (viewModel.companyDetail?.data == null) {
              return const Center(child: Text('Şirket bilgileri bulunamadı.'));
            }

            final companyData = viewModel.companyDetail!.data!;

            return CustomScrollView(
              slivers: [
                _buildSliverAppBar(context, companyData.company),
                SliverToBoxAdapter(child: _buildCompanyInfo(context, companyData.company)),
                SliverToBoxAdapter(child: _buildJobsHeader(context, companyData.jobs.length)),
                _buildJobsList(context, companyData.jobs),
              ],
            );
          },
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context, CompanyInfo? company) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          company?.compName ?? 'Şirket Detayı',
          style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 16),
        ),
        background: company?.profilePhoto != null && company!.profilePhoto.isNotEmpty
            ? Image.network(
                company.profilePhoto,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.4),
                colorBlendMode: BlendMode.darken,
              )
            : Container(color: AppColors.cardBorder),
      ),
    );
  }

  Widget _buildCompanyInfo(BuildContext context, CompanyInfo? company) {
    if (company == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(AppPaddings.pageHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (company.compDesc.isNotEmpty) ...[
            Text(
              'Hakkında',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppPaddings.item / 2),
            Text(
              company.compDesc,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppPaddings.card),
          ],
          _buildInfoRow(
            context,
            icon: Icons.location_on_outlined,
            text: '${company.compDistrict}, ${company.compCity}',
          ),
          if (company.compAddress.isNotEmpty) ...[
            const SizedBox(height: AppPaddings.item),
            _buildInfoRow(
              context,
              icon: Icons.map_outlined,
              text: company.compAddress,
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, {required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textLight, size: 18),
        const SizedBox(width: AppPaddings.item),
        Expanded(
          child: Text(text, style: AppTextStyles.body),
        ),
      ],
    );
  }

  Widget _buildJobsHeader(BuildContext context, int jobCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppPaddings.pageHorizontal, AppPaddings.card, AppPaddings.pageHorizontal, AppPaddings.item),
      child: Text(
        'Açık Pozisyonlar ($jobCount)',
        style: AppTextStyles.title.copyWith(fontSize: 18),
      ),
    );
  }

  Widget _buildJobsList(BuildContext context, List<CompanyJob> jobs) {
    if (jobs.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(AppPaddings.pageHorizontal),
          child: Text('Bu şirkete ait aktif iş ilanı bulunmamaktadır.'),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final job = jobs[index];
          return Card(
            elevation: 1.0,
            margin: const EdgeInsets.symmetric(
              horizontal: AppPaddings.pageHorizontal,
              vertical: AppPaddings.item / 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.cardBorder.withOpacity(0.5)),
            ),
            child: ListTile(
              title: Text(job.jobTitle, style: AppTextStyles.title.copyWith(fontSize: 16)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(job.workType, style: AppTextStyles.body),
              ),
              trailing: Text(job.showDate, style: AppTextStyles.body.copyWith(color: AppColors.textLight)),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
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
            ),
          );
        },
        childCount: jobs.length,
      ),
    );
  }
} 