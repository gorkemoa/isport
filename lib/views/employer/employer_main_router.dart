import 'package:flutter/material.dart';
import 'dashboard_home_screen.dart';
import 'jobs_management_screen.dart';
import 'applications_screen.dart';
import 'favorite_applicants_screen.dart';
import 'profile_screen.dart';

/// Modern Employer Ana Router
/// LinkedIn ve Kariyer.net tarzında kurumsal tasarım
class EmployerMainRouter extends StatefulWidget {
  const EmployerMainRouter({super.key});

  @override
  State<EmployerMainRouter> createState() => _EmployerMainRouterState();
}

class _EmployerMainRouterState extends State<EmployerMainRouter> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardHomeScreen(),
    const JobsManagementScreen(),
    const ApplicationsScreen(),
    const FavoriteApplicantsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Ana Sayfa',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.work_outline,
                activeIcon: Icons.work,
                label: 'İlanlarım',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: 'Başvurular',
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.favorite_outline,
                activeIcon: Icons.favorite,
                label: 'Favoriler',
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _currentIndex == index;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 20,
                color: isActive ? const Color(0xFF1D9D83) : const Color(0xFF757575),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? const Color(0xFF1D9D83) : const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 