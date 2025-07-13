import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/user_service.dart';
import '../../services/employer_service.dart';
import '../../models/user_model.dart';
import '../../models/employer_models.dart';
import '../../services/logger_service.dart';
import '../login_screen.dart';
import 'add_job_screen.dart';
import 'favorite_applicants_screen.dart';

class EmployerHomeScreen extends StatefulWidget {
  const EmployerHomeScreen({super.key});

  @override
  State<EmployerHomeScreen> createState() => _EmployerHomeScreenState();
}

class _EmployerHomeScreenState extends State<EmployerHomeScreen> {
  final UserService _userService = UserService();
  final EmployerService _employerService = EmployerService();
  
  UserModel? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentIndex = 0;
  
  // İş ilanları ve başvurular için state
  EmployerJobsData? _jobsData;
  EmployerApplicationsData? _applicationsData;
  bool _isJobsLoading = false;
  bool _isApplicationsLoading = false;
  String? _jobsErrorMessage;
  String? _applicationsErrorMessage;
  
  // Favori adaylar için state
  EmployerFavoriteApplicantsData? _favoriteApplicantsData;
  bool _isFavoriteApplicantsLoading = false;
  String? _favoriteApplicantsErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sayfa değiştiğinde ilgili verileri yükle
    if (_currentUser != null) {
      _loadPageData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken') ?? '';
      
      if (userToken.isEmpty) {
        setState(() {
          _errorMessage = 'Oturum bulunamadı. Lütfen tekrar giriş yapın.';
          _isLoading = false;
        });
        return;
      }

      logger.debug('Kullanıcı verisi yükleniyor...');
      
      final response = await _userService.getUser(userToken: userToken);
      
      if (response.isTokenError) {
        await _logout();
        return;
      }
      
      if (response.success && response.data != null) {
        final user = response.data!.user;
        
        if (user.isComp) {
          setState(() {
            _currentUser = user;
            _isLoading = false;
            _errorMessage = null;
          });
          logger.debug('Şirket kullanıcısı başarıyla yüklendi: ${user.userFullname}');
          
          // Kullanıcı verisi yüklendiğinde sayfa verilerini de yükle
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadPageData();
          });
        } else {
          setState(() {
            _errorMessage = 'Bu hesap şirket hesabı değil. Lütfen geçerli bir şirket hesabı ile giriş yapın.';
            _isLoading = false;
          });
          logger.debug('Kullanıcı şirket hesabı değil');
        }
      } else {
        setState(() {
          _errorMessage = response.displayMessage ?? 'Kullanıcı bilgileri alınamadı';
          _isLoading = false;
        });
        logger.debug('Kullanıcı verisi alınamadı: ${response.error_message}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bir hata oluştu: $e';
        _isLoading = false;
      });
      logger.debug('Kullanıcı verisi yüklenirken hata: $e');
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userToken');
      
      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const LoginScreen())
        );
      }
    } catch (e) {
      logger.debug('Çıkış yapılırken hata: $e');
    }
  }

  /// Sayfa verilerini yükler
  Future<void> _loadPageData() async {
    if (_currentUser == null) return;

    switch (_currentIndex) {
      case 1: // İlanlarım sayfası
        await _loadJobsData();
        break;
      case 2: // Başvurular sayfası
        await _loadApplicationsData();
        break;
      case 3: // Favori Adaylar sayfası
        await _loadFavoriteApplicantsData();
        break;
    }
  }

  /// İş ilanlarını yükler
  Future<void> _loadJobsData() async {
    if (_isJobsLoading) return;

    setState(() {
      _isJobsLoading = true;
      _jobsErrorMessage = null;
    });

    try {
      final response = await _employerService.fetchCurrentUserCompanyJobs();
      
      if (response.isTokenError) {
        await _logout();
        return;
      }

      if (response.isSuccessful && response.data != null) {
        setState(() {
          _jobsData = response.data;
          _isJobsLoading = false;
        });
        logger.debug('İş ilanları başarıyla yüklendi: ${response.data!.jobCount} ilan');
      } else {
        setState(() {
          _jobsErrorMessage = response.displayMessage ?? 'İş ilanları alınamadı';
          _isJobsLoading = false;
        });
        logger.debug('İş ilanları alınamadı: ${response.errorMessage}');
      }
    } catch (e) {
      setState(() {
        _jobsErrorMessage = 'Bir hata oluştu: $e';
        _isJobsLoading = false;
      });
      logger.debug('İş ilanları yüklenirken hata: $e');
    }
  }

  /// Başvuruları yükler
  Future<void> _loadApplicationsData() async {
    if (_isApplicationsLoading) return;

    setState(() {
      _isApplicationsLoading = true;
      _applicationsErrorMessage = null;
    });

    try {
      final response = await _employerService.fetchCurrentUserCompanyApplications();
      
      if (response.isTokenError) {
        await _logout();
        return;
      }

      if (response.isSuccessful && response.data != null) {
        setState(() {
          _applicationsData = response.data;
          _isApplicationsLoading = false;
        });
        logger.debug('Başvurular başarıyla yüklendi: ${response.data!.applicationCount} başvuru');
      } else {
        setState(() {
          _applicationsErrorMessage = response.displayMessage ?? 'Başvurular alınamadı';
          _isApplicationsLoading = false;
        });
        logger.debug('Başvurular alınamadı: ${response.errorMessage}');
      }
    } catch (e) {
      setState(() {
        _applicationsErrorMessage = 'Bir hata oluştu: $e';
        _isApplicationsLoading = false;
      });
      logger.debug('Başvurular yüklenirken hata: $e');
    }
  }

  /// Favori adayları yükler
  Future<void> _loadFavoriteApplicantsData() async {
    if (_isFavoriteApplicantsLoading) return;

    setState(() {
      _isFavoriteApplicantsLoading = true;
      _favoriteApplicantsErrorMessage = null;
    });

    try {
      final response = await _employerService.fetchCurrentUserCompanyFavoriteApplicants();
      
      if (response.isTokenError) {
        await _logout();
        return;
      }

      if (response.isSuccessful && response.data != null) {
        setState(() {
          _favoriteApplicantsData = response.data;
          _isFavoriteApplicantsLoading = false;
        });
        logger.debug('Favori adaylar başarıyla yüklendi: ${response.data!.favoriteCount} aday');
      } else {
        setState(() {
          _favoriteApplicantsErrorMessage = response.displayMessage ?? 'Favori adaylar alınamadı';
          _isFavoriteApplicantsLoading = false;
        });
        logger.debug('Favori adaylar alınamadı: ${response.errorMessage}');
      }
    } catch (e) {
      setState(() {
        _favoriteApplicantsErrorMessage = 'Bir hata oluştu: $e';
        _isFavoriteApplicantsLoading = false;
      });
      logger.debug('Favori adaylar yüklenirken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _getPageTitle(),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _logout,
                        child: const Text('Giriş Ekranına Dön'),
                      ),
                    ],
                  ),
                )
              : IndexedStack(
                  index: _currentIndex,
                  children: [
                    _buildHomePage(),
                    _buildJobsPage(),
                    _buildApplicationsPage(),
                    _buildFavoriteApplicantsPage(),
                    _buildProfilePage(),
                  ],
                ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Sayfa değiştiğinde verileri yükle
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadPageData();
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue.shade600,
        unselectedItemColor: Colors.grey.shade500,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'İlanlarım',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Başvurular',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoriler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Ana Sayfa';
      case 1:
        return 'İlanlarım';
      case 2:
        return 'Başvurular';
      case 3:
        return 'Favori Adaylar';
      case 4:
        return 'Profil';
      default:
        return 'İşveren Paneli';
    }
  }

  Widget _buildHomePage() {
    final user = _currentUser!;
    final company = user.company!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hoş Geldin Kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade600,
                  Colors.blue.shade800,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade200,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Icon(
                        Icons.business,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hoş Geldiniz',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.userFullname,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            company.compName,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // İstatistikler
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Toplam İlan',
                  company.totalJobs.toString(),
                  Icons.article,
                  Colors.blue.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Aktif İlan',
                  company.activeJobs.toString(),
                  Icons.visibility,
                  Colors.green.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Başvuru',
                  company.totalApplications.toString(),
                  Icons.person_add,
                  Colors.orange.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Favori',
                  company.totalFavorites.toString(),
                  Icons.favorite,
                  Colors.red.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Hızlı Aksiyonlar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.flash_on, color: Colors.blue.shade600, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Hızlı Aksiyonlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildActionButton(
                  company.canAddJob 
                    ? 'Yeni İş İlanı Ekle' 
                    : 'İş İlanı Ekle (${company.isJobLimitReached ? "Limit Doldu" : "Yetki Yok"})',
                  Icons.add,
                  company.canAddJob ? Colors.blue.shade600 : Colors.grey.shade400,
                  () => _navigateToAddJob(),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  'Başvuruları İncele',
                  Icons.people,
                  Colors.orange.shade600,
                  () => setState(() => _currentIndex = 2),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  'İlanları Yönet',
                  Icons.edit,
                  Colors.green.shade600,
                  () => setState(() => _currentIndex = 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsPage() {
    final company = _currentUser!.company!;
    
    return RefreshIndicator(
      onRefresh: () async {
        await _loadJobsData();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İlan Özeti
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.blue.shade600, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'İlan Özeti',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Toplam İlan', company.totalJobs.toString()),
                  _buildInfoRow('Aktif İlan', company.activeJobs.toString()),
                  _buildInfoRow('Pasif İlan', company.passiveJobs.toString()),
                  _buildInfoRow('İlan Limiti', company.jobLimit.toString()),
                  _buildInfoRow('Kalan Hak', company.remainingJobSlots.toString()),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // İlan Durumu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: company.canAddJob ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: company.canAddJob ? Colors.green.shade200 : Colors.red.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        company.canAddJob ? Icons.check_circle : Icons.warning,
                        color: company.canAddJob ? Colors.green.shade600 : Colors.red.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          company.limitStatusText,
                          style: TextStyle(
                            color: company.canAddJob ? Colors.green.shade700 : Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Yeni İlan Ekle Butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: company.canAddJob ? () => _navigateToAddJob() : null,
                icon: const Icon(Icons.add, size: 20),
                label: Text(
                  company.canAddJob 
                    ? 'Yeni İş İlanı Ekle'
                    : company.isJobLimitReached 
                      ? 'Limit Doldu (${company.activeJobs}/${company.jobLimit})'
                      : 'İş İlanı Ekleme Yetkiniz Yok',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: company.canAddJob ? Colors.blue.shade600 : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // İlanlarım Listesi
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.work, color: Colors.blue.shade600, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'İlanlarım',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      if (_isJobsLoading)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_isJobsLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_jobsErrorMessage != null)
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _jobsErrorMessage!,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadJobsData,
                            child: const Text('Tekrar Dene'),
                          ),
                        ],
                      ),
                    )
                  else if (_jobsData == null || _jobsData!.jobs.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.work_outline,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Henüz iş ilanınız bulunmamaktadır.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _jobsData!.jobs.map((job) => _buildJobCard(job)).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsPage() {
    final company = _currentUser!.company!;
    
    return RefreshIndicator(
      onRefresh: () async {
        await _loadApplicationsData();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başvuru Özeti
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.blue.shade600, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Başvuru Özeti',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Toplam Başvuru', company.totalApplications.toString()),
                  _buildInfoRow('Bekleyen Başvuru', _applicationsData?.applications.where((app) => app.statusName == 'Yeni Başvuru').length.toString() ?? '0'),
                  _buildInfoRow('Değerlendirilen', _applicationsData?.applications.where((app) => app.statusName == 'Değerlendiriliyor').length.toString() ?? '0'),
                  _buildInfoRow('Kabul Edilen', _applicationsData?.applications.where((app) => app.statusName == 'Kabul Edildi').length.toString() ?? '0'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Başvuru Listesi
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, color: Colors.blue.shade600, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Son Başvurular',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      if (_isApplicationsLoading)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_isApplicationsLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_applicationsErrorMessage != null)
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _applicationsErrorMessage!,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadApplicationsData,
                            child: const Text('Tekrar Dene'),
                          ),
                        ],
                      ),
                    )
                  else if (_applicationsData == null || _applicationsData!.applications.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Henüz başvuru bulunmamaktadır.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _applicationsData!.applications.map((application) => _buildApplicationCard(application)).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePage() {
    final user = _currentUser!;
    final company = user.company!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kullanıcı Bilgileri
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue.shade600, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Kullanıcı Bilgileri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoRow('Ad Soyad', user.userFullname),
                _buildInfoRow('E-posta', user.userEmail),
                _buildInfoRow('Telefon', user.userPhone),
                _buildInfoRow('Cinsiyet', user.userGender),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Şirket Bilgileri
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.business, color: Colors.blue.shade600, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Şirket Bilgileri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoRow('Şirket Adı', company.compName),
                if (company.compDesc.isNotEmpty)
                  _buildInfoRow('Açıklama', company.compDesc),
                _buildInfoRow('Adres', company.fullLocation),
                _buildInfoRow('Çalışan Sayısı', company.formattedEmployeeCount),
                if (company.compSector.isNotEmpty)
                  _buildInfoRow('Sektör', company.compSector),
                if (company.hasWebsite)
                  _buildInfoRow('Web Sitesi', company.compWebSite),
                if (company.compTaxNumber.isNotEmpty)
                  _buildInfoRow('Vergi No', company.compTaxNumber),
                if (company.compTaxPlace.isNotEmpty)
                  _buildInfoRow('Vergi Dairesi', company.compTaxPlace),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: Colors.white),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildSimpleButton(String title, IconData icon, bool enabled, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 16),
        label: Text(title),
        style: TextButton.styleFrom(
          foregroundColor: enabled ? Colors.blue.shade600 : Colors.grey,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Belirtilmemiş',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _navigateToAddJob() async {
    if (_currentUser == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddJobScreen(user: _currentUser!),
      ),
    );

    // Eğer iş ilanı başarıyla eklendiyse sayfayı yenile
    if (result == true) {
      _loadUserData();
      _loadJobsData(); // İş ilanlarını da yenile
    }
  }

  /// İş ilanı kartı oluşturur
  Widget _buildJobCard(EmployerJobModel job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  job.jobTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getWorkTypeColor(job.workType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getWorkTypeColor(job.workType).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  job.workType,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getWorkTypeColor(job.workType),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          if (job.hasDescription) ...[
            Text(
              job.shortDescription,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.formattedLocation,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          Row(
            children: [
              Icon(Icons.attach_money, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.formattedSalary,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Icon(Icons.category, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.catName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                job.showDate,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const Spacer(),
              if (job.isHighlighted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.amber.shade600),
                      const SizedBox(width: 2),
                      Text(
                        'Vurgulanan',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: job.isActive ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  job.isActive ? 'Aktif' : 'Pasif',
                  style: TextStyle(
                    fontSize: 10,
                    color: job.isActive ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          if (job.hasBenefits) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: job.benefits.map((benefit) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  benefit,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// İş türü rengini döner
  Color _getWorkTypeColor(String workType) {
    switch (workType.toLowerCase()) {
      case 'tam zamanlı':
        return const Color(0xFF059669); // Green
      case 'yarı zamanlı':
        return const Color(0xFF0891B2); // Cyan
      case 'proje bazlı':
        return const Color(0xFF7C3AED); // Purple
      case 'stajyer':
        return const Color(0xFFDC2626); // Red
      case 'freelance':
        return const Color(0xFFF59E0B); // Amber
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  /// Favori adaylar sayfasını oluşturur
  Widget _buildFavoriteApplicantsPage() {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const FavoriteApplicantsScreen(),
        );
      },
    );
  }

  /// Başvuru kartı oluşturur
  Widget _buildApplicationCard(EmployerApplicationModel application) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  application.userInitials,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      application.jobTitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(application.statusColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(application.statusColor).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  application.statusName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(application.statusColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (application.hasDescription) ...[
            Text(
              application.shortDescription,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                application.appliedAt,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const Spacer(),
              if (application.isFavorite)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite, size: 12, color: Colors.red.shade600),
                      const SizedBox(width: 2),
                      Text(
                        'Favori',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
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

  /// Durum rengini döner
  Color _getStatusColor(String statusColor) {
    try {
      return Color(int.parse(statusColor.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.grey.shade600;
    }
  }
} 