import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/employer_viewmodel.dart';
import '../../models/employer_models.dart';
import '../../utils/app_constants.dart';

/// Başvuru detayı ekranı
class ApplicationDetailScreen extends StatefulWidget {
  final int appId;
  final String jobTitle;

  const ApplicationDetailScreen({
    super.key,
    required this.appId,
    required this.jobTitle,
  });

  @override
  State<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  ApplicationDetailModel? _applicationDetail;
  bool _isLoading = true;
  bool _isUpdatingStatus = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadApplicationDetail();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadApplicationDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await context.read<EmployerViewModel>().getApplicationDetail(widget.appId);
      
      if (mounted) {
        setState(() {
          _applicationDetail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Başvuru detayı yüklenirken hata oluştu';
        });
      }
    }
  }

  Future<void> _updateApplicationStatus(int newStatus) async {
    if (_applicationDetail == null) return;

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final success = await context.read<EmployerViewModel>().updateApplicationStatus(
        widget.appId,
        newStatus,
      );

      if (success && mounted) {
        // Başarılı güncelleme sonrası detayları yeniden yükle
        await _loadApplicationDetail();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Başvuru durumu başarıyla güncellendi'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Başvuru Detayı',
        style: TextStyle(
          color: Colors.grey[800],
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.grey[700]),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (_applicationDetail != null) ...[
          // Favori butonu
          IconButton(
            icon: Icon(
              Icons.favorite,
              color: Colors.red[400],
            ),
            onPressed: () => _toggleFavorite(),
            tooltip: 'Favorilere ekle/çıkar',
          ),
          // Yenile butonu
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey[700]),
            onPressed: _loadApplicationDetail,
          ),
        ],
      ],
    );
  }

  /// Favori durumunu değiştirir
  Future<void> _toggleFavorite() async {
    if (_applicationDetail == null) return;

    try {
      final success = await context.read<EmployerViewModel>().toggleFavoriteApplicant(
        _applicationDetail!.jobID,
        _applicationDetail!.userID,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Favori durumu güncellendi'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_applicationDetail == null) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Başvuru detayı yükleniyor...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Bir hata oluştu',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadApplicationDetail,
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Başvuru detayı bulunamadı',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final detail = _applicationDetail!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(detail),
          const SizedBox(height: 16),
          _buildApplicantInfoCard(detail),
          const SizedBox(height: 16),
          _buildApplicationInfoCard(detail),
          if (detail.hasCv) ...[
            const SizedBox(height: 16),
            _buildCvCard(detail),
          ],
          const SizedBox(height: 16),
          _buildStatusUpdateCard(detail),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(ApplicationDetailModel detail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    detail.userInitials,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.jobTitle,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantInfoCard(ApplicationDetailModel detail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Aday Bilgileri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('E-posta', detail.userEmail, Icons.email_outlined),
          const SizedBox(height: 12),
          if (detail.canShowContact)
            _buildInfoRow('Telefon', detail.userPhone, Icons.phone_outlined),
          if (!detail.canShowContact)
            _buildInfoRow('İletişim', 'Görüntüleme izni yok', Icons.block_outlined),
        ],
      ),
    );
  }

  Widget _buildApplicationInfoCard(ApplicationDetailModel detail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.work_outline, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Başvuru Bilgileri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Başvuru Tarihi', detail.formattedAppliedAt, Icons.calendar_today_outlined),
          const SizedBox(height: 12),
          _buildInfoRow('Başvuru Saati', detail.formattedAppliedTime, Icons.access_time_outlined),
          const SizedBox(height: 12),
          _buildStatusRow(detail),
        ],
      ),
    );
  }

  Widget _buildCvCard(ApplicationDetailModel detail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'CV Bilgileri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (detail.cvData.hasTitle)
            _buildInfoRow('CV Başlığı', detail.cvData.cvTitle, Icons.title_outlined),
          if (detail.cvData.hasTitle && detail.cvData.hasSummary)
            const SizedBox(height: 12),
          if (detail.cvData.hasSummary)
            _buildInfoRow('CV Özeti', detail.cvData.cvSummary, Icons.summarize_outlined),
        ],
      ),
    );
  }

  Widget _buildStatusUpdateCard(ApplicationDetailModel detail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.update_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Durum Güncelleme',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusButtons(detail),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(ApplicationDetailModel detail) {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mevcut Durum',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _parseStatusColor(detail.statusColor),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  detail.statusName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusButtons(ApplicationDetailModel detail) {
    // Durum seçenekleri (gerçek uygulamada API'den alınabilir)
    final statusOptions = [
      {'id': 1, 'name': 'Yeni Başvuru', 'color': '#999999'},
      {'id': 2, 'name': 'İnceleniyor', 'color': '#2196F3'},
      {'id': 3, 'name': 'Mülakat', 'color': '#FF9800'},
      {'id': 4, 'name': 'Kabul Edildi', 'color': '#4CAF50'},
      {'id': 5, 'name': 'Reddedildi', 'color': '#F44336'},
    ];

    return Column(
      children: [
        Text(
          'Başvuru durumunu güncellemek için aşağıdaki seçeneklerden birini seçin:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        ...statusOptions.map((status) {
          final isCurrentStatus = status['id'] == detail.statusID;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: _isUpdatingStatus ? null : () => _updateApplicationStatus(status['id'] as int),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCurrentStatus 
                    ? _parseStatusColor(status['color'] as String).withValues(alpha: 0.1)
                    : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrentStatus 
                      ? _parseStatusColor(status['color'] as String)
                      : Colors.grey[300]!,
                    width: isCurrentStatus ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _parseStatusColor(status['color'] as String),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        status['name'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrentStatus ? FontWeight.w600 : FontWeight.normal,
                          color: isCurrentStatus 
                            ? _parseStatusColor(status['color'] as String)
                            : Colors.black87,
                        ),
                      ),
                    ),
                    if (isCurrentStatus)
                      Icon(
                        Icons.check_circle,
                        color: _parseStatusColor(status['color'] as String),
                        size: 20,
                      ),
                    if (_isUpdatingStatus)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Color _parseStatusColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
} 