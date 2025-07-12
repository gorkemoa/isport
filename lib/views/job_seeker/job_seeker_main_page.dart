import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'job_seeker_home_screen.dart';
import 'job_seeker_profile_screen.dart';
import 'job_listing_screen.dart';
import 'applications_screen.dart';

/// İş arayan kullanıcılar için tab tabanlı ana sayfa.
class JobSeekerMainPage extends StatefulWidget {
  const JobSeekerMainPage({super.key});

  @override
  State<JobSeekerMainPage> createState() => _JobSeekerMainPageState();
}

class _JobSeekerMainPageState extends State<JobSeekerMainPage> {
  int _currentIndex = 0;

  late final List<Widget> _screens = const [
    JobSeekerHomeScreen(),
    JobListingScreen(),
    ApplicationsScreen(),
    _MessagesScreen(),
    JobSeekerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Sistem çubuğu rengini ayarla
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
    ));

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF667EEA),
        unselectedItemColor: Colors.grey[500],
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Ara'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Başvurular'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Mesajlar'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

// Aşağıdaki ekranlar şimdilik basit placeholder'lardır. Gerektiğinde detaylı
// ekran bileşenlerine dönüştürülebilirler.

class _MessagesScreen extends StatelessWidget {
  const _MessagesScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Center(child: Text('Mesajlar')),
    );
  }
} 