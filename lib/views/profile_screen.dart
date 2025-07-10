import 'package:flutter/material.dart';
import 'package:isport/utils/app_constants.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../viewmodels/auth_viewmodels.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Profilim'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            Consumer<ProfileViewModel>(
              builder: (context, viewModel, child) {
                return IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Profili Düzenle',
                  onPressed: viewModel.isLoading || viewModel.userResponse?.data?.user == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChangeNotifierProvider.value(
                                value: viewModel, // Mevcut viewModel'i pasla
                                child: EditProfileScreen(
                                  user: viewModel.userResponse!.data!.user,
                                ),
                              ),
                            ),
                          );
                        },
                );
              },
            ),
          ],
        ),
        body: Consumer<ProfileViewModel>(
          builder: (context, viewModel, child) {
            // Logout gerekiyorsa ana AuthViewModel'i güncelle ve login ekranına yönlendir
            if (viewModel.needsLogout) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<AuthViewModel>().logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              });
            }

            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            if (viewModel.errorMessage != null) {
              return _buildError(context, viewModel.errorMessage!, () => viewModel.fetchUser());
            }

            if (viewModel.userResponse?.data?.user == null) {
              return _buildError(context, 'Kullanıcı verisi bulunamadı.', () => viewModel.fetchUser());
            }

            final UserModel user = viewModel.userResponse!.data!.user;
            return ListView(
              padding: const EdgeInsets.all(AppPaddings.pageHorizontal),
              children: [
                const SizedBox(height: AppPaddings.card),
                _buildHeader(context, user),
                const SizedBox(height: AppPaddings.pageVertical),
                _buildInfoCard(
                  title: 'Kişisel Bilgiler',
                  children: [
                    _buildInfoTile(icon: Icons.email_outlined, title: 'E-posta', subtitle: user.userEmail),
                    _buildInfoTile(icon: Icons.phone_outlined, title: 'Telefon', subtitle: user.userPhone),
                    if (user.userBirthday.isNotEmpty)
                      _buildInfoTile(icon: Icons.cake_outlined, title: 'Doğum Günü', subtitle: user.userBirthday),
                    if (user.userGender.isNotEmpty && user.userGender != 'Belirtilmemiş')
                      _buildInfoTile(icon: Icons.person_outline, title: 'Cinsiyet', subtitle: user.userGender),
                  ],
                ),
                if (user.isComp && user.company != null) ...[
                  const SizedBox(height: AppPaddings.pageVertical),
                  _buildInfoCard(
                    title: 'Kurumsal Bilgiler',
                    children: [
                      _buildInfoTile(icon: Icons.business_outlined, title: 'Şirket Adı', subtitle: user.company!.compName),
                      _buildInfoTile(icon: Icons.location_on_outlined, title: 'Adres', subtitle: '${user.company!.compDistrict} / ${user.company!.compCity}'),
                      if (user.company!.compAddress.isNotEmpty)
                        _buildInfoTile(icon: Icons.map_outlined, title: 'Detaylı Adres', subtitle: user.company!.compAddress),
                       if (user.company!.compTaxNumber.isNotEmpty)
                        _buildInfoTile(icon: Icons.receipt_long_outlined, title: 'Vergi Numarası', subtitle: user.company!.compTaxNumber),
                    ],
                  ),
                ],
                const SizedBox(height: AppPaddings.pageVertical),
                 _buildInfoCard(
                  title: 'Güvenlik',
                  children: [
                    _buildInfoTile(
                      icon: Icons.lock_outline, 
                      title: 'Şifre Değiştir',
                      onTap: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider.value(
                              value: viewModel,
                              child: const ChangePasswordScreen(),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                 const SizedBox(height: AppPaddings.pageVertical),
                _buildLogoutButton(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppPaddings.pageHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: AppPaddings.card),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(fontSize: 16),
            ),
            const SizedBox(height: AppPaddings.item),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Yeniden Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.cardBorder,
          backgroundImage: user.profilePhoto.isNotEmpty
              ? NetworkImage(user.profilePhoto)
              : null,
          child: user.profilePhoto.isEmpty
              ? Icon(Icons.person_outline, size: 50, color: AppColors.textLight.withOpacity(0.8))
              : null,
        ),
        const SizedBox(height: AppPaddings.card),
        Text(
          user.userFullname,
          style: AppTextStyles.title.copyWith(fontSize: 22),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppPaddings.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.title.copyWith(color: AppColors.primary, fontSize: 18),
            ),
            const SizedBox(height: AppPaddings.item),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String title, String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textLight, size: 20),
      title: Text(title, style: AppTextStyles.body.copyWith(color: AppColors.textLight)),
      subtitle: subtitle != null ? Text(subtitle, style: AppTextStyles.company.copyWith(fontWeight: FontWeight.w600, fontSize: 15)) : null,
      onTap: onTap,
    );
  }

  Widget _buildClickableInfoTile(BuildContext context, ProfileViewModel viewModel, {required IconData icon, required String title}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider.value(
              value: viewModel,
              child: const ChangePasswordScreen(),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppPaddings.pageHorizontal, vertical: AppPaddings.item + 4),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textLight, size: 20),
            const SizedBox(width: AppPaddings.card),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.company.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: AppTextStyles.title.copyWith(color: AppColors.primary, fontSize: 18),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _showLogoutDialog(context, context.read<ProfileViewModel>()),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: const Text('Çıkış Yap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  void _showLogoutDialog(BuildContext context, ProfileViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Çıkış Yap'),
          titleTextStyle: AppTextStyles.title,
          content: const Text('Hesabınızdan çıkmak istediğinizden emin misiniz?'),
          contentTextStyle: AppTextStyles.body,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('İptal', style: AppTextStyles.body.copyWith(color: AppColors.textLight)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                viewModel.logout();
              },
              child: Text('Çıkış Yap', style: AppTextStyles.body.copyWith(color: Colors.red.shade600, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
} 