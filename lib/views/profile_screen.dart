import 'package:flutter/material.dart';
import 'package:isport/utils/app_constants.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../viewmodels/auth_viewmodels.dart';
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
            return _buildProfileView(context, user, viewModel);
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

  Widget _buildProfileView(BuildContext context, UserModel user, ProfileViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: () => viewModel.fetchUser(),
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppPaddings.pageVertical),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPaddings.pageHorizontal),
            child: _buildProfileHeader(context, user),
          ),
          const SizedBox(height: AppPaddings.pageVertical * 1.5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPaddings.pageHorizontal),
            child: _buildSectionTitle(context, 'Kişisel Bilgiler'),
          ),
          const SizedBox(height: AppPaddings.item),
          _buildInfoTile(Icons.person_outline, 'Kullanıcı Adı', user.username),
          _buildInfoTile(Icons.email_outlined, 'E-posta', user.userEmail),
          _buildInfoTile(Icons.phone_outlined, 'Telefon', user.userPhone),
          _buildInfoTile(Icons.cake_outlined, 'Doğum Günü', user.userBirthday),
          _buildInfoTile(Icons.wc_outlined, 'Cinsiyet', user.userGender),
          const SizedBox(height: AppPaddings.pageVertical * 1.5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPaddings.pageHorizontal),
            child: _buildSectionTitle(context, 'Hesap Bilgileri'),
          ),
          const SizedBox(height: AppPaddings.item),
          _buildInfoTile(Icons.star_border_outlined, 'Rank', user.userRank),
          _buildInfoTile(Icons.verified_user_outlined, 'Durum', user.userStatus),
          _buildInfoTile(Icons.check_circle_outline, 'Onaylı Hesap', user.isApproved ? 'Evet' : 'Hayır'),
          _buildInfoTile(Icons.business_center_outlined, 'Şirket Hesabı', user.isComp ? 'Evet' : 'Hayır'),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPaddings.pageHorizontal),
            child: ElevatedButton(
              onPressed: () => _showLogoutDialog(context, viewModel),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Çıkış Yap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
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

  Widget _buildProfileHeader(BuildContext context, UserModel user) {
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: AppTextStyles.title.copyWith(color: AppColors.primary, fontSize: 18),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: AppPaddings.pageHorizontal, vertical: AppPaddings.item),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textLight, size: 20),
          const SizedBox(width: AppPaddings.card),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body.copyWith(color: AppColors.textLight)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.company.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 