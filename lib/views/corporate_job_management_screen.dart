import 'package:flutter/material.dart';
import 'package:isport/utils/app_constants.dart';
import 'package:provider/provider.dart';
import '../viewmodels/company_job_viewmodel.dart';
import '../viewmodels/auth_viewmodels.dart';
import '../models/company_job_models.dart';

class CorporateJobManagementScreen extends StatefulWidget {
  const CorporateJobManagementScreen({super.key});

  @override
  State<CorporateJobManagementScreen> createState() => _CorporateJobManagementScreenState();
}

class _CorporateJobManagementScreenState extends State<CorporateJobManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Company jobs verilerini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCompanyJobs();
    });
  }

  void _loadCompanyJobs() {
    final authViewModel = context.read<AuthViewModel>();
    final companyJobViewModel = context.read<CompanyJobViewModel>();
    
    if (authViewModel.currentUser != null) {
      // TODO: Gerçek company ID'yi auth'dan al, şimdilik 4 kullanıyoruz
      companyJobViewModel.setCompanyId(4);
      companyJobViewModel.fetchCompanyJobs(
        userToken: authViewModel.currentUser!.token,
        isRefresh: true,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'İlan Yönetimi',
          style: AppTextStyles.title.copyWith(color: AppColors.textTitle),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              _showCreateJobBottomSheet();
            },
            icon: const Icon(Icons.add, color: AppColors.textTitle),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Aktif İlanlar'),
            Tab(text: 'Bekleyenler'),
            Tab(text: 'Arşiv'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveJobsList(),
          _buildPendingJobsList(),
          _buildArchivedJobsList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateJobBottomSheet();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Yeni İlan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildActiveJobsList() {
    return Consumer<CompanyJobViewModel>(
      builder: (context, companyJobViewModel, child) {
        final activeJobs = companyJobViewModel.activeJobs;
        
        if (companyJobViewModel.status == CompanyJobStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        
        if (companyJobViewModel.status == CompanyJobStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(companyJobViewModel.errorMessage ?? 'Bir hata oluştu'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadCompanyJobs,
                  child: const Text('Yeniden Dene'),
                ),
              ],
            ),
          );
        }
        
        if (activeJobs.isEmpty) {
          return _buildEmptyState('Aktif ilan bulunamadı', 'Yeni ilan oluşturmak için + butonuna tıklayın');
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => _loadCompanyJobs(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppPaddings.pageHorizontal),
            itemCount: activeJobs.length,
            itemBuilder: (context, index) {
              return _buildJobCard(activeJobs[index], 'active');
            },
          ),
        );
      },
    );
  }

  Widget _buildPendingJobsList() {
    return Consumer<CompanyJobViewModel>(
      builder: (context, companyJobViewModel, child) {
        final inactiveJobs = companyJobViewModel.inactiveJobs;
        
        if (companyJobViewModel.status == CompanyJobStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        
        if (inactiveJobs.isEmpty) {
          return _buildEmptyState('Bekleyen ilan bulunamadı', 'Tüm ilanlarınız onaylandı');
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => _loadCompanyJobs(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppPaddings.pageHorizontal),
            itemCount: inactiveJobs.length,
            itemBuilder: (context, index) {
              return _buildJobCard(inactiveJobs[index], 'pending');
            },
          ),
        );
      },
    );
  }

  Widget _buildArchivedJobsList() {
    // Arşiv için ayrı bir API endpoint olması gerekiyor
    // Şimdilik boş gösteriyoruz
    return _buildEmptyState('Arşivlenmiş ilan bulunamadı', 'Kapatılan ilanlarınız burada görünecek');
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline,
            size: 64,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.title.copyWith(
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(CompanyJob job, String status) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppPaddings.card),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppPaddings.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.jobTitle,
                        style: AppTextStyles.title.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.catName,
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoItem(Icons.location_on_outlined, job.location),
                const SizedBox(width: 16),
                _buildInfoItem(Icons.access_time_outlined, job.workType),
                const SizedBox(width: 16),
                _buildInfoItem(Icons.attach_money_outlined, job.formattedSalary),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Yayın tarihi: ${job.showDate}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
                Row(
                  children: [
                    if (status == 'active') ...[
                      IconButton(
                        onPressed: () {
                          _showJobStatistics(job);
                        },
                        icon: const Icon(Icons.analytics_outlined, size: 20),
                        color: AppColors.primary,
                      ),
                      IconButton(
                        onPressed: () {
                          _editJob(job);
                        },
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        color: Colors.blue,
                      ),
                      IconButton(
                        onPressed: () {
                          _archiveJob(job);
                        },
                        icon: const Icon(Icons.archive_outlined, size: 20),
                        color: Colors.orange,
                      ),
                    ],
                    if (status == 'pending') ...[
                      IconButton(
                        onPressed: () {
                          _editJob(job);
                        },
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        color: Colors.blue,
                      ),
                      IconButton(
                        onPressed: () {
                          _cancelJob(job);
                        },
                        icon: const Icon(Icons.cancel_outlined, size: 20),
                        color: Colors.red,
                      ),
                    ],
                    if (status == 'archived') ...[
                      IconButton(
                        onPressed: () {
                          _reactivateJob(job);
                        },
                        icon: const Icon(Icons.refresh_outlined, size: 20),
                        color: Colors.green,
                      ),
                      IconButton(
                        onPressed: () {
                          _deleteJob(job);
                        },
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: Colors.red,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'active':
        color = Colors.green;
        text = 'Aktif';
        icon = Icons.check_circle_outline;
        break;
      case 'pending':
        color = Colors.orange;
        text = 'Bekliyor';
        icon = Icons.hourglass_empty;
        break;
      case 'archived':
        color = Colors.grey;
        text = 'Arşiv';
        icon = Icons.archive_outlined;
        break;
      default:
        color = Colors.grey;
        text = 'Bilinmiyor';
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textLight),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  void _showCreateJobBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: const CreateJobForm(),
      ),
    );
  }

  void _showJobStatistics(CompanyJob job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${job.jobTitle} İstatistikleri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('İlan Başlığı', job.jobTitle),
            _buildStatRow('Kategori', job.catName),
            _buildStatRow('Konum', job.location),
            _buildStatRow('Çalışma Türü', job.workType),
            _buildStatRow('Maaş', job.formattedSalary),
            _buildStatRow('Durumu', job.isActive ? 'Aktif' : 'Pasif'),
            _buildStatRow('Oluşturma Tarihi', job.createDate),
            _buildStatRow('Yayın Tarihi', job.showDate),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text(value, style: AppTextStyles.subtitle),
        ],
      ),
    );
  }

  void _editJob(CompanyJob job) {
    // TODO: Edit job implementation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${job.jobTitle} düzenleniyor...')),
    );
  }

  void _archiveJob(CompanyJob job) {
    // TODO: Archive job implementation
    context.read<CompanyJobViewModel>().toggleJobStatus(job.jobID);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${job.jobTitle} arşivlendi')),
    );
  }

  void _cancelJob(CompanyJob job) {
    // TODO: Cancel job implementation
    context.read<CompanyJobViewModel>().toggleJobStatus(job.jobID);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${job.jobTitle} iptal edildi')),
    );
  }

  void _reactivateJob(CompanyJob job) {
    // TODO: Reactivate job implementation
    context.read<CompanyJobViewModel>().toggleJobStatus(job.jobID);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${job.jobTitle} yeniden aktifleştirildi')),
    );
  }

  void _deleteJob(CompanyJob job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İlanı Sil'),
        content: Text('${job.jobTitle} ilanını kalıcı olarak silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CompanyJobViewModel>().removeJob(job.jobID);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${job.jobTitle} silindi')),
              );
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

}

class CreateJobForm extends StatefulWidget {
  const CreateJobForm({super.key});

  @override
  State<CreateJobForm> createState() => _CreateJobFormState();
}

class _CreateJobFormState extends State<CreateJobForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppPaddings.pageHorizontal,
        right: AppPaddings.pageHorizontal,
        top: AppPaddings.pageHorizontal,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppPaddings.pageHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Yeni İş İlanı',
                style: AppTextStyles.title.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: _buildInputDecoration('İlan Başlığı'),
                      validator: (value) => value?.isEmpty ?? true ? 'Bu alan zorunludur' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _descriptionController,
                      decoration: _buildInputDecoration('İş Açıklaması'),
                      maxLines: 4,
                      validator: (value) => value?.isEmpty ?? true ? 'Bu alan zorunludur' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _requirementsController,
                      decoration: _buildInputDecoration('Gereksinimler'),
                      maxLines: 3,
                      validator: (value) => value?.isEmpty ?? true ? 'Bu alan zorunludur' : null,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('İptal'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('İlanı Yayınla'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: AppColors.cardBackground,
    );
  }

  void _submitJob() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: Submit job implementation
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlan başarıyla oluşturuldu!')),
      );
    }
  }
} 