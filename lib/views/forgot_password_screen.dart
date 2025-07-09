import 'package:flutter/material.dart';
import 'package:isport/utils/app_constants.dart';
import 'package:isport/viewmodels/auth_viewmodels.dart';
import 'package:provider/provider.dart';

enum ForgotPasswordStep { email, code, reset }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  ForgotPasswordStep _currentStep = ForgotPasswordStep.email;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().clearError();
    });
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleSendCode(AuthViewModel authViewModel) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    final success = await authViewModel.forgotPassword(_emailController.text.trim());
    if (success) {
      setState(() => _currentStep = ForgotPasswordStep.code);
      _nextPage();
    }
  }
  
  void _handleCheckCode(AuthViewModel authViewModel) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await authViewModel.checkCode(_codeController.text.trim());
     if (success) {
      setState(() => _currentStep = ForgotPasswordStep.reset);
      _nextPage();
    }
  }

  void _handleResetPassword(AuthViewModel authViewModel) async {
     if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await authViewModel.resetPassword(_passwordController.text);
    if (success) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifreniz başarıyla güncellendi. Şimdi giriş yapabilirsiniz.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  String _getTitle() {
    switch (_currentStep) {
      case ForgotPasswordStep.email:
        return 'Şifremi Unuttum';
      case ForgotPasswordStep.code:
        return 'Kodu Doğrula';
      case ForgotPasswordStep.reset:
        return 'Yeni Şifre Belirle';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildEmailStep(authViewModel),
                  _buildCodeStep(authViewModel),
                  _buildResetStep(authViewModel),
                ],
              ),
            ),
            if (authViewModel.errorMessage != null)
              _buildErrorWidget(authViewModel.errorMessage!),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailStep(AuthViewModel authViewModel) {
    return _buildStepContainer(
      title: 'E-posta Adresinizi Girin',
      subtitle: 'Şifre sıfırlama talimatlarını göndereceğimiz e-posta adresinizi girin.',
      formFields: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _buildInputDecoration(labelText: 'E-posta'),
          validator: (v) {
            if (v == null || v.isEmpty) return 'E-posta zorunludur';
            if (!v.contains('@')) return 'Geçerli bir e-posta girin';
            return null;
          },
        ),
      ],
      button: _buildActionButton(
        text: 'Doğrulama Kodu Gönder',
        isLoading: authViewModel.isLoading,
        onPressed: () => _handleSendCode(authViewModel),
      ),
    );
  }

  Widget _buildCodeStep(AuthViewModel authViewModel) {
    return _buildStepContainer(
      title: 'Doğrulama Kodunu Girin',
      subtitle: 'E-posta adresinize gönderilen 6 haneli doğrulama kodunu girin.',
      formFields: [
        TextFormField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: const TextStyle(fontSize: 24, letterSpacing: 12),
          decoration: _buildInputDecoration(labelText: 'Doğrulama Kodu').copyWith(
            counterText: '',
          ),
          validator: (v) => v!.length < 6 ? '6 haneli kodu girin' : null,
        ),
      ],
       button: _buildActionButton(
        text: 'Kodu Doğrula',
        isLoading: authViewModel.isLoading,
        onPressed: () => _handleCheckCode(authViewModel),
      ),
    );
  }
  
  Widget _buildResetStep(AuthViewModel authViewModel) {
    return _buildStepContainer(
      title: 'Yeni Şifrenizi Belirleyin',
      subtitle: 'Güçlü bir şifre oluşturun.',
      formFields: [
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: _buildInputDecoration(labelText: 'Yeni Şifre').copyWith(
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (v) => v!.isEmpty ? 'Şifre boş olamaz' : null,
        ),
        const SizedBox(height: AppPaddings.card),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: _buildInputDecoration(labelText: 'Yeni Şifre (Tekrar)').copyWith(
             suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
          validator: (v) {
            if (v != _passwordController.text) return 'Şifreler eşleşmiyor';
            return null;
          },
        ),
      ],
      button: _buildActionButton(
        text: 'Şifreyi Güncelle',
        isLoading: authViewModel.isLoading,
        onPressed: () => _handleResetPassword(authViewModel),
      ),
    );
  }

  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required List<Widget> formFields,
    required Widget button,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppPaddings.pageHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppPaddings.pageVertical),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppPaddings.item),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
          ),
          const SizedBox(height: AppPaddings.pageVertical * 2),
          ...formFields,
          const SizedBox(height: AppPaddings.pageVertical),
          button,
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required String text,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
        ),
        child: isLoading
            ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
            : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String labelText}) {
    return InputDecoration(
      labelText: labelText,
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
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      width: double.infinity,
      color: Colors.red[100],
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.w500),
      ),
    );
  }
} 