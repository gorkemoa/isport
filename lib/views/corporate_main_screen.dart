import 'package:flutter/material.dart';
import 'package:isport/utils/app_constants.dart';
import 'package:isport/views/corporate_home_screen.dart';
import 'package:isport/views/corporate_applications_screen.dart';
import 'package:isport/views/corporate_job_management_screen.dart';
import 'package:isport/views/profile_screen.dart';

class CorporateMainScreen extends StatefulWidget {
  const CorporateMainScreen({super.key});

  @override
  State<CorporateMainScreen> createState() => _CorporateMainScreenState();
}

class _CorporateMainScreenState extends State<CorporateMainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const CorporateHomeScreen(),
    const CorporateJobManagementScreen(),
    const CorporateApplicationsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.cardBackground,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'İlanlarım',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Başvurular',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_outlined),
            activeIcon: Icon(Icons.business),
            label: 'Şirket',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
      ),
    );
  }
}



 