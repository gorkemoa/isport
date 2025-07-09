import 'package:flutter/material.dart';
import 'package:isport/utils/app_constants.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodels.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPaddings.pageHorizontal),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                
                // Logo veya başlık
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.work_history_outlined,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                
                const SizedBox(height: AppPaddings.pageVertical),
                
                Text(
                  'iSport',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                
                const SizedBox(height: AppPaddings.item),
                
                Text(
                  'Kariyer Fırsatları Burada',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // Giriş formu
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _buildInputDecoration(
                          labelText: 'E-posta',
                          hintText: 'ornek@email.com',
                          icon: Icons.email_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'E-posta adresinizi girin';
                          }
                          if (!value.contains('@')) {
                            return 'Geçerli bir e-posta adresi girin';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: AppPaddings.card),
                      
                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: _buildInputDecoration(
                          labelText: 'Şifre',
                          hintText: 'Şifrenizi girin',
                          icon: Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textLight,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Şifrenizi girin';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: AppPaddings.pageVertical),
                      
                      // Giriş butonu
                      Consumer<AuthViewModel>(
                        builder: (context, authViewModel, child) {
                          return SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: authViewModel.isLoading
                                  ? null
                                  : () => _handleLogin(authViewModel),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                              ),
                              child: authViewModel.isLoading
                                  ? const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    )
                                  : const Text(
                                      'Giriş Yap',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: AppPaddings.card),
                      
                      // Hata mesajı
                      Consumer<AuthViewModel>(
                        builder: (context, authViewModel, child) {
                          if (authViewModel.errorMessage != null) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Text(
                                authViewModel.errorMessage!,
                                style: TextStyle(
                                  color: Colors.red[800],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Test verileri için bilgi
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Test için:',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'E-posta: ridvan.dasdelen@gmail.com\nŞifre: 123a',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(icon, color: AppColors.textLight),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: AppColors.cardBackground,
      labelStyle: const TextStyle(color: AppColors.textLight),
      hintStyle: const TextStyle(color: AppColors.textLight),
    );
  }

  void _handleLogin(AuthViewModel authViewModel) async {
    // Hata mesajını temizle
    authViewModel.clearError();
    
    if (_formKey.currentState?.validate() ?? false) {
      final success = await authViewModel.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (success) {
        // Giriş başarılı - AuthWrapper otomatik olarak HomeScreen'e yönlendirecek
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Giriş başarılı!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
} 