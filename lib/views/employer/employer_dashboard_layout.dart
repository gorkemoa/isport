import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_constants.dart';

/// Modern Employer Dashboard Layout
class EmployerDashboardLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? floatingActionButton;
  final bool showBottomNavigation;

  const EmployerDashboardLayout({
    super.key,
    required this.child,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.floatingActionButton,
    this.showBottomNavigation = true,
  });

  @override
  State<EmployerDashboardLayout> createState() => _EmployerDashboardLayoutState();
}

class _EmployerDashboardLayoutState extends State<EmployerDashboardLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildModernAppBar(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ana AppBar
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Back Button
                if (widget.showBackButton)
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: IconButton(
                      onPressed: widget.onBackPressed ?? () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.textTitle,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                
                // Title
                Expanded(
                  child: Text(
                    widget.title,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTitle,
                    ),
                  ),
                ),
                
                // Actions
                if (widget.actions != null) ...[
                  ...widget.actions!,
                ],
                
                // Profile Menu
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: PopupMenuButton<String>(
                    icon: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.person,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, size: 18, color: AppColors.textBody),
                            const SizedBox(width: 12),
                            Text(
                              'Profil',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textBody,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings_outlined, size: 18, color: AppColors.textBody),
                            const SizedBox(width: 12),
                            Text(
                              'Ayarlar',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textBody,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 18, color: Colors.red[600]),
                            const SizedBox(width: 12),
                            Text(
                              'Çıkış Yap',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.red[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'profile':
                          // Navigate to profile
                          break;
                        case 'settings':
                          // Navigate to settings
                          break;
                        case 'logout':
                          // Handle logout
                          break;
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Navigation Indicator
          if (widget.showBottomNavigation)
            Container(
              height: 1,
              color: AppColors.cardBorder,
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: widget.child,
    );
  }
}
// Google Fonts import için
class GoogleFonts {
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
} 