import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodels.dart';
import '../../utils/app_constants.dart';
import '../login_screen.dart';

class EmployerHomeScreen extends StatefulWidget {
  const EmployerHomeScreen({super.key});

  @override
  State<EmployerHomeScreen> createState() => _EmployerHomeScreenState();
}

class _EmployerHomeScreenState extends State<EmployerHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Sayfa yüklendiğinde kullanıcı detaylarını kontrol et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (authViewModel.currentUserDetail == null && authViewModel.currentUser?.isComp == true) {
        authViewModel.getUserDetails();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'İşveren Paneli',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          if (authViewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final user = authViewModel.currentUser;
          final userDetail = authViewModel.currentUserDetail;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppPaddings.pageHorizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hoşgeldin kartı
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppPaddings.card),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
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
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.business,
                              color: AppColors.primary,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hoşgeldiniz!',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: AppColors.textTitle,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userDetail?.company?.compName ?? 'Kurumsal Kullanıcı',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (userDetail?.company != null) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildCompanyInfoItem(
                          'Şirket Adı',
                          userDetail!.company!.compName,
                          Icons.business,
                        ),
                        const SizedBox(height: 12),
                        _buildCompanyInfoItem(
                          'Açıklama',
                          userDetail!.company!.compDesc.isNotEmpty 
                              ? userDetail!.company!.compDesc 
                              : 'Açıklama belirtilmemiş',
                          Icons.description,
                        ),
                        const SizedBox(height: 12),
                        _buildCompanyInfoItem(
                          'Şehir',
                          userDetail!.company!.compCity,
                          Icons.location_city,
                        ),
                        const SizedBox(height: 12),
                        _buildCompanyInfoItem(
                          'İlçe',
                          userDetail!.company!.compDistrict,
                          Icons.location_on,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Hızlı Erişim Kartları
                Text(
                  'Hızlı Erişim',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textTitle,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildQuickAccessCard(
                      'İlan Yönetimi',
                      'İş ilanlarınızı oluşturun ve yönetin',
                      Icons.work,
                      Colors.blue,
                      () {
                        // İlan yönetimi sayfasına git
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('İlan yönetimi sayfası geliştiriliyor...')),
                        );
                      },
                    ),
                    _buildQuickAccessCard(
                      'Başvurular',
                      'Gelen başvuruları inceleyin',
                      Icons.people,
                      Colors.green,
                      () {
                        // Başvurular sayfasına git
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Başvurular sayfası geliştiriliyor...')),
                        );
                      },
                    ),
                    _buildQuickAccessCard(
                      'Şirket Profili',
                      'Şirket bilgilerinizi güncelleyin',
                      Icons.business_center,
                      Colors.orange,
                      () {
                        // Şirket profili sayfasına git
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Şirket profili sayfası geliştiriliyor...')),
                        );
                      },
                    ),
                    _buildQuickAccessCard(
                      'Raporlar',
                      'İstatistiklerinizi görüntüleyin',
                      Icons.analytics,
                      Colors.purple,
                      () {
                        // Raporlar sayfasına git
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Raporlar sayfası geliştiriliyor...')),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Çıkış Butonu
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await authViewModel.logout();
                      if (mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Çıkış Yap',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompanyInfoItem(String title, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textLight,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTitle,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textTitle,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
} 