import 'package:flutter/material.dart';
import 'package:isport/utils/app_constants.dart';
import 'package:isport/views/home_screen.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodels.dart';
import 'register_screen.dart';
import 'package:isport/views/forgot_password_screen.dart';

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
    final textTheme = Theme.of(context).textTheme;


    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Image.asset(
            'assets/Adsız tasarım (10).png',
            fit: BoxFit.fitHeight,
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            alignment: Alignment.center,
            repeat: ImageRepeat.repeat,
          ),

          // Giriş İçeriği
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppPaddings.pageHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 160),

                    // Başlık
                    Text(
                      "İşPort'a\nHoş Geldiniz",
                      style: textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textTitle,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: AppPaddings.item),

                    Text(
                      'Kariyerinizde zirveye giden yol.',
                      style: textTheme.titleMedium?.copyWith(
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

                          // Şifremi Unuttum Butonu
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ForgotPasswordScreen()),
                                );
                              },
                              child: const Text(
                                'Şifremi Unuttum',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                          ),

                          const SizedBox(height: AppPaddings.card),

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
                                    disabledBackgroundColor:
                                        AppColors.primary.withOpacity(0.5),
                                  ),
                                  child: authViewModel.isLoading
                                      ? const CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.white),
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

                          // Kayıt ol butonu
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterScreen()),
                              );
                            },
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(color: AppColors.textLight),
                                children: [
                                  TextSpan(text: 'Hesabın yok mu? '),
                                  TextSpan(
                                    text: 'Kayıt Ol',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                                    border: Border.all(
                                        color: Colors.red[200]!),
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
                  ],
                ),
              ),
            ),
          ),
        ],
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

      if (success && mounted) {
        // Kullanıcı tipine göre yönlendirme yap
        final user = authViewModel.currentUser;
        if (user != null && user.isComp) {
          // Kurumsal kullanıcı - Corporate Main Screen'e yönlendir
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          // İş arayan kullanıcı - Main Screen'e yönlendir
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    }
  }
} 