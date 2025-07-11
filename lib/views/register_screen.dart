import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:isport/models/auth_models.dart';
import 'package:isport/utils/app_constants.dart';
import 'package:isport/viewmodels/auth_viewmodels.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentTab = 0;

  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _policyChecked = false;
  bool _kvkkChecked = false;

  // Form Controllers
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _compNameController = TextEditingController();
  final _compAddressController = TextEditingController();
  final _compTaxNumberController = TextEditingController();
  final _compTaxPlaceController = TextEditingController();
  
  // TODO: Bunlar için dropdown veya arama özelliği olan bir widget eklenebilir.
  final int? _compCityId = 35; 
  final int? _compDistrictId = 1448;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().clearError();
    });
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _compNameController.dispose();
    _compAddressController.dispose();
    _compTaxNumberController.dispose();
    _compTaxPlaceController.dispose();
    super.dispose();
  }

  void _handleRegister(AuthViewModel authViewModel) async {
    authViewModel.clearError();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_policyChecked || !_kvkkChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kullanım koşullarını ve KVKK metnini onaylayın.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isCompany = _currentTab == 1;

    final request = RegisterRequest(
      userFirstname: _firstnameController.text.trim(),
      userLastname: _lastnameController.text.trim(),
      userEmail: _emailController.text.trim(),
      userPhone: _phoneController.text.trim(),
      userPassword: _passwordController.text,
      isComp: isCompany ? 1 : 0,
      compName: isCompany ? _compNameController.text.trim() : null,
      compAddress: isCompany ? _compAddressController.text.trim() : null,
      compCity: isCompany ? _compCityId : null,
      compDistrict: isCompany ? _compDistrictId : null,
      compTaxNumber: isCompany ? _compTaxNumberController.text.trim() : null,
      compTaxPlace: isCompany ? _compTaxPlaceController.text.trim() : null,
      policy: _policyChecked,
      kvkk: _kvkkChecked,
      platform: Platform.isIOS ? 'ios' : 'android',
      version: '1.0.0', // Bu değer dinamik olarak alınabilir
    );
    
    final response = await authViewModel.register(request);

    if (mounted && response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.successMessage ?? 'Kayıt başarılı!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Geri login ekranına dön
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.textBody),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppPaddings.pageHorizontal)
              .copyWith(bottom: AppPaddings.pageVertical),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                "Yeni bir hesap oluştur",
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textTitle,
                ),
              ),
              const SizedBox(height: AppPaddings.item),
              Text(
                "Kariyerinize ilk adımı atın.",
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: AppPaddings.pageVertical),

              _buildAccountTypeSwitcher(),

              const SizedBox(height: AppPaddings.pageVertical),
              
              _buildFormFields(isCompany: _currentTab == 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTypeSwitcher() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ToggleButtons(
        renderBorder: false,
        isSelected: [_currentTab == 0, _currentTab == 1],
        onPressed: (index) => setState(() => _currentTab = index),
        borderRadius: BorderRadius.circular(10),
        selectedColor: Colors.white,
        fillColor: AppColors.primary,
        color: AppColors.textBody,
        splashColor: AppColors.primary.withOpacity(0.2),
        borderColor: Colors.transparent,
        selectedBorderColor: Colors.transparent,
        constraints: BoxConstraints.expand(
            width: (MediaQuery.of(context).size.width / 2) - AppPaddings.pageHorizontal - 2),
        children: const [
          Text("Bireysel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text("Kurumsal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFormFields({required bool isCompany}) {
    final authViewModel = context.watch<AuthViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bireysel Alanlar
        TextFormField(
          controller: _firstnameController,
          decoration: _buildInputDecoration(labelText: 'Ad'),
          validator: (v) => (v?.isEmpty ?? true) ? 'Ad alanı zorunludur' : null,
        ),
        const SizedBox(height: AppPaddings.card),
        TextFormField(
          controller: _lastnameController,
          decoration: _buildInputDecoration(labelText: 'Soyad'),
          validator: (v) => (v?.isEmpty ?? true) ? 'Soyad alanı zorunludur' : null,
        ),
        const SizedBox(height: AppPaddings.card),
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
        const SizedBox(height: AppPaddings.card),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: _buildInputDecoration(labelText: 'Telefon Numarası'),
          validator: (v) => (v?.isEmpty ?? true) ? 'Telefon numarası zorunludur' : null,
        ),
        const SizedBox(height: AppPaddings.card),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: _buildInputDecoration(labelText: 'Şifre').copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textLight,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (v) => (v?.isEmpty ?? true) ? 'Şifre alanı zorunludur' : null,
        ),

        // Kurumsal Alanlar
        if (isCompany) ...[
          const SizedBox(height: AppPaddings.pageVertical),
          const Divider(),
          const SizedBox(height: AppPaddings.card),
          Text(
            'Firma Bilgileri',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppPaddings.card),
          TextFormField(
            controller: _compNameController,
            decoration: _buildInputDecoration(labelText: 'Firma Adı'),
            validator: (v) => isCompany && (v?.isEmpty ?? true) ? 'Firma adı zorunludur' : null,
          ),
          const SizedBox(height: AppPaddings.card),
          TextFormField(
            controller: _compAddressController,
            decoration: _buildInputDecoration(labelText: 'Firma Adresi'),
            validator: (v) => isCompany && (v?.isEmpty ?? true) ? 'Firma adresi zorunludur' : null,
          ),
          const SizedBox(height: AppPaddings.card),
          TextFormField(
            controller: _compTaxNumberController,
            keyboardType: TextInputType.number,
            decoration: _buildInputDecoration(labelText: 'TC / Vergi Numarası'),
            validator: (v) => isCompany && (v?.isEmpty ?? true) ? 'TC/Vergi No zorunludur' : null,
          ),
          const SizedBox(height: AppPaddings.card),
          TextFormField(
            controller: _compTaxPlaceController,
            decoration: _buildInputDecoration(labelText: 'Vergi Dairesi'),
          ),
        ],

        const SizedBox(height: AppPaddings.pageVertical),

        // Sözleşmeler
        _buildCheckbox(
          title: 'Kullanım Koşullarını ve Gizlilik Politikasını',
          subtitle: ' okudum, anladım ve kabul ediyorum.',
          value: _policyChecked,
          onChanged: (val) => setState(() => _policyChecked = val!),
        ),
        const SizedBox(height: AppPaddings.item),
        _buildCheckbox(
          title: 'KVKK Aydınlatma Metni\'ni',
          subtitle: ' okudum ve anladım.',
          value: _kvkkChecked,
          onChanged: (val) => setState(() => _kvkkChecked = val!),
        ),

        const SizedBox(height: AppPaddings.pageVertical),

        // Hata Mesajı
        if (authViewModel.errorMessage != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Text(
              authViewModel.errorMessage!,
              style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppPaddings.card),
        ],

        // Kayıt Butonu
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: authViewModel.isLoading ? null : () => _handleRegister(authViewModel),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
            ),
            child: authViewModel.isLoading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                : const Text('Kayıt Ol',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
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

  Widget _buildCheckbox({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 24.0,
            width: 24.0,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppPaddings.item),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textBody),
                  children: [
                    TextSpan(
                      text: title,
                      style: const TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.bold),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          // TODO: İlgili sözleşme sayfasına yönlendir.
                          print('$title tıklandı.');
                        },
                    ),
                    TextSpan(text: subtitle),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 