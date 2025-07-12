import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/job_models.dart';
import '../utils/app_constants.dart';

/// Modern iş ilanı kartı widget'ı
class JobCard extends StatelessWidget {
  final JobModel job;
  final CompanyDetailModel company;
  final VoidCallback? onTap;
  final VoidCallback? onApply;
  final bool showCompanyInfo;
  final bool showApplyButton;

  const JobCard({
    super.key,
    required this.job,
    required this.company,
    this.onTap,
    this.onApply,
    this.showCompanyInfo = true,
    this.showApplyButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Şirket bilgileri
            if (showCompanyInfo) ...[
              _buildCompanyHeader(),
              const SizedBox(height: 10),
            ],
            
            // İş başlığı
            Text(
              job.jobTitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 6),
            
            // İş detayları
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.work_outline,
                  text: job.workType,
                  color: const Color(0xFF059669),
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.schedule_outlined,
                  text: job.showDate,
                  color:   (AppColors.primary),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            
            // Alt bilgiler
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showCompanyInfo)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${company.compDistrict}, ${company.compCity}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showApplyButton && onApply != null) ...[
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onApply?.call();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.send,
                                size: 8,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Başvur',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onTap?.call();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Detaylar',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 8,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildCompanyHeader() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: company.profilePhoto.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: company.profilePhoto,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[50],
                      child: Icon(Icons.business, size: 16, color: Colors.grey),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[50],
                      child: Icon(Icons.business, size: 16, color: Colors.grey),
                    ),
                  )
                : Container(
                    color: Colors.grey[50],
                    child: Icon(Icons.business, size: 16, color: Colors.grey),
                  ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                company.compName,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF374151),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (company.compDesc.isNotEmpty)
                Text(
                  company.compDesc,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Şirket detay kartı widget'ı
class CompanyCard extends StatelessWidget {
  final CompanyDetailModel company;
  final int jobCount;
  final VoidCallback? onTap;

  const CompanyCard({
    super.key,
    required this.company,
    required this.jobCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: company.profilePhoto.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: company.profilePhoto,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[50],
                              child: Icon(Icons.business, size: 20, color: Colors.grey),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[50],
                              child: Icon(Icons.business, size: 20, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey[50],
                            child: Icon(Icons.business, size: 20, color: Colors.grey),
                          ),
                  ),
                ),
                
                const SizedBox(width: 10),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.compName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              '${company.compDistrict}, ${company.compCity}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (company.compDesc.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                company.compDesc,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            const SizedBox(height: 10),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:   (AppColors.primary).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$jobCount Açık Pozisyon',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                        color:   (AppColors.primary),
                    ),
                  ),
                ),
                
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }
}

/// Loading shimmer widget'ı
class JobLoadingShimmer extends StatelessWidget {
  final int itemCount;
  final bool showCompanyHeader;

  const JobLoadingShimmer({
    super.key,
    this.itemCount = 3,
    this.showCompanyHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showCompanyHeader) ...[
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 12,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 10,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  Row(
                    children: [
                      Container(
                        height: 16,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 16,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 10,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Container(
                        height: 16,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Boş state widget'ı
class EmptyJobsWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const EmptyJobsWidget({
    super.key,
    this.message = 'Henüz iş ilanı bulunmuyor',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.work_outline,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 4),
            
            Text(
              'Yeni iş ilanları için daha sonra tekrar kontrol edin',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor:   (AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  'Yeniden Dene',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale();
  }
} 