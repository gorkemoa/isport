import 'package:flutter/material.dart';
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
        appBar: AppBar(
          title: const Text('Profilim'),
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
              return const Center(child: CircularProgressIndicator());
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(context, user),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Kişisel Bilgiler'),
          const Divider(),
          _buildInfoTile(Icons.person_outline, 'Kullanıcı Adı', user.username),
          _buildInfoTile(Icons.email_outlined, 'E-posta', user.userEmail),
          _buildInfoTile(Icons.phone_outlined, 'Telefon', user.userPhone),
          _buildInfoTile(Icons.cake_outlined, 'Doğum Günü', user.userBirthday),
          _buildInfoTile(Icons.wc_outlined, 'Cinsiyet', user.userGender),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Hesap Bilgileri'),
          const Divider(),
          _buildInfoTile(Icons.star_border_outlined, 'Rank', user.userRank),
          _buildInfoTile(Icons.verified_user_outlined, 'Durum', user.userStatus),
          _buildInfoTile(Icons.check_circle_outline, 'Onaylı Hesap', user.isApproved ? 'Evet' : 'Hayır'),
           _buildInfoTile(Icons.business_center_outlined, 'Şirket Hesabı', user.isComp ? 'Evet' : 'Hayır'),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _showLogoutDialog(context, viewModel),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
            ),
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
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
          title: const Text('Çıkış Yap'),
          content: const Text('Hesabınızdan çıkmak istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                viewModel.logout();
              },
              child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
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
          backgroundImage: user.profilePhoto.isNotEmpty
              ? NetworkImage(user.profilePhoto)
              : null,
          child: user.profilePhoto.isEmpty
              ? const Icon(Icons.person, size: 50)
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          user.userFullname,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 16, color: Colors.grey.shade800)),
    );
  }
} 