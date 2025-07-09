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

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().clearError();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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

    final isCompany = _tabController.index == 1;

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Yeni Hesap Oluştur'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Bireysel'),
            Tab(text: 'Kurumsal'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildForm(isCompany: false),
            _buildForm(isCompany: true),
          ],
        ),
      ),
    );
  }

  Widget _buildForm({required bool isCompany}) {
    final authViewModel = context.watch<AuthViewModel>();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPaddings.pageHorizontal,
        vertical: AppPaddings.pageVertical,
      ),
      child: Column(
        children: [
          // Bireysel Alanlar
          TextFormField(
            controller: _firstnameController,
            decoration: _buildInputDecoration(labelText: 'Ad'),
            validator: (v) => v!.isEmpty ? 'Ad alanı zorunludur' : null,
          ),
          const SizedBox(height: AppPaddings.card),
          TextFormField(
            controller: _lastnameController,
            decoration: _buildInputDecoration(labelText: 'Soyad'),
            validator: (v) => v!.isEmpty ? 'Soyad alanı zorunludur' : null,
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
            validator: (v) => v!.isEmpty ? 'Telefon numarası zorunludur' : null,
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
             validator: (v) => v!.isEmpty ? 'Şifre alanı zorunludur' : null,
          ),
          
          // Kurumsal Alanlar
          if (isCompany) ...[
             const SizedBox(height: AppPaddings.pageVertical),
             const Divider(),
             const SizedBox(height: AppPaddings.card),
             Text('Firma Bilgileri', style: Theme.of(context).textTheme.titleLarge),
             const SizedBox(height: AppPaddings.card),
             TextFormField(
              controller: _compNameController,
              decoration: _buildInputDecoration(labelText: 'Firma Adı'),
              validator: (v) => isCompany && v!.isEmpty ? 'Firma adı zorunludur' : null,
            ),
            const SizedBox(height: AppPaddings.card),
            TextFormField(
              controller: _compAddressController,
              decoration: _buildInputDecoration(labelText: 'Firma Adresi'),
              validator: (v) => isCompany && v!.isEmpty ? 'Firma adresi zorunludur' : null,
            ),
             const SizedBox(height: AppPaddings.card),
            TextFormField(
              controller: _compTaxNumberController,
              keyboardType: TextInputType.number,
              decoration: _buildInputDecoration(labelText: 'TC / Vergi Numarası'),
              validator: (v) => isCompany && v!.isEmpty ? 'TC/Vergi No zorunludur' : null,
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
                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                  : const Text('Kayıt Ol', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
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

  Widget _buildCheckbox({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return FormField<bool>(
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              value: value,
              onChanged: onChanged,
              title: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textBody),
                  children: [
                    TextSpan(
                      text: title,
                      style: const TextStyle(color: AppColors.primary, decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()..onTap = () {
                        // TODO: İlgili sözleşme sayfasına yönlendir.
                        print('$title tıklandı.');
                      },
                    ),
                    TextSpan(text: subtitle),
                  ],
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        );
      },
    );
  }

} 