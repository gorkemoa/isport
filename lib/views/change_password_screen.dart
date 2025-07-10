import 'package:flutter/material.dart';
import 'package:isport/models/user_model.dart';
import 'package:isport/utils/app_constants.dart';
import 'package:isport/viewmodels/profile_viewmodel.dart';
import 'package:provider/provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

   @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().clearError();
    });
  }

  Future<void> _handleChangePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    
    final profileViewModel = context.read<ProfileViewModel>();
    final token = profileViewModel.userResponse?.data?.user.userToken;

    if (token == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı bilgileri bulunamadı, lütfen tekrar giriş yapın.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final request = UpdatePasswordRequest(
      userToken: token,
      currentPassword: _currentPasswordController.text,
      password: _newPasswordController.text,
      passwordAgain: _confirmPasswordController.text,
    );

    final success = await profileViewModel.updatePassword(request);
     if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifreniz başarıyla güncellendi.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else if (profileViewModel.errorMessage != null) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profileViewModel.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şifre Değiştir'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ProfileViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppPaddings.pageHorizontal),
                  children: [
                    const SizedBox(height: AppPaddings.pageVertical),
                    _buildPasswordField(
                      controller: _currentPasswordController,
                      label: 'Mevcut Şifre',
                      obscureText: _obscureCurrent,
                      onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                    const SizedBox(height: AppPaddings.card),
                    _buildPasswordField(
                      controller: _newPasswordController,
                      label: 'Yeni Şifre',
                      obscureText: _obscureNew,
                      onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                    const SizedBox(height: AppPaddings.card),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      label: 'Yeni Şifre (Tekrar)',
                      obscureText: _obscureConfirm,
                      onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (value) {
                        if (value != _newPasswordController.text) {
                          return 'Yeni şifreler eşleşmiyor.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppPaddings.pageVertical * 2),
                    ElevatedButton(
                      onPressed: viewModel.isLoading ? null : _handleChangePassword,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: viewModel.isLoading 
                          ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                          : const Text('Şifreyi Güncelle'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: onToggle,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label alanı boş bırakılamaz.';
        }
        if (validator != null) {
          return validator(value);
        }
        return null;
      },
    );
  }
} 