import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isport/models/user_model.dart';
import 'package:isport/utils/app_constants.dart';
import 'package:isport/viewmodels/profile_viewmodel.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _firstnameController;
  late TextEditingController _lastnameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthdayController;
  
  int _gender = 1; // 1: Erkek, 2: Kadın, 3: Diğer
  File? _imageFile;
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _firstnameController = TextEditingController(text: widget.user.userFirstname);
    _lastnameController = TextEditingController(text: widget.user.userLastname);
    _emailController = TextEditingController(text: widget.user.userEmail);
    _phoneController = TextEditingController(text: widget.user.userPhone);
    _birthdayController = TextEditingController(text: widget.user.userBirthday);
    
    // API'den gelen cinsiyet string'ini int'e çevir
    switch (widget.user.userGender.toLowerCase()) {
      case 'erkek':
        _gender = 1;
        break;
      case 'kadın':
        _gender = 2;
        break;
      default:
        _gender = 3;
    }
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 50);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        // Convert to base64
        final bytes = await _imageFile!.readAsBytes();
        _imageBase64 = 'data:image/png;base64,${base64Encode(bytes)}';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resim seçilemedi: $e')),
      );
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden Seç'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpdate() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final profileViewModel = context.read<ProfileViewModel>();
    final request = UpdateUserRequest(
      userToken: widget.user.userToken, // Bu token viewModel'de yenilenecek
      userFirstname: _firstnameController.text,
      userLastname: _lastnameController.text,
      userEmail: _emailController.text,
      userPhone: _phoneController.text,
      userBirthday: _birthdayController.text,
      userGender: _gender,
      profilePhoto: _imageBase64,
    );

    final success = await profileViewModel.updateUser(request);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil başarıyla güncellendi.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
    // Hata durumu zaten viewModel tarafından yönetiliyor ve ProfileScreen'de gösterilecek.
    // Ancak burada da bir snackbar gösterilebilir.
    else if (profileViewModel.errorMessage != null) {
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
        title: const Text('Profili Düzenle'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          Consumer<ProfileViewModel>(
            builder: (context, viewModel, child) {
              return IconButton(
                icon: viewModel.isLoading ? const SizedBox.shrink() : const Icon(Icons.save_outlined),
                onPressed: viewModel.isLoading ? null : _handleUpdate,
                tooltip: 'Kaydet',
              );
            },
          ),
        ],
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
                    const SizedBox(height: AppPaddings.card),
                    Center(
                      child: GestureDetector(
                        onTap: _showImageSourceActionSheet,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.cardBorder,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (widget.user.profilePhoto.isNotEmpty
                                  ? NetworkImage(widget.user.profilePhoto)
                                  : null) as ImageProvider?,
                          child: _imageFile == null && widget.user.profilePhoto.isEmpty
                              ? const Icon(Icons.camera_alt_outlined, size: 40, color: AppColors.textLight)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppPaddings.item),
                    const Center(child: Text('Profil Fotoğrafını Değiştir')),
                    const SizedBox(height: AppPaddings.pageVertical),
                    _buildTextFormField(controller: _firstnameController, label: 'Ad'),
                    const SizedBox(height: AppPaddings.card),
                    _buildTextFormField(controller: _lastnameController, label: 'Soyad'),
                    const SizedBox(height: AppPaddings.card),
                    _buildTextFormField(
                        controller: _emailController,
                        label: 'E-posta',
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: AppPaddings.card),
                    _buildTextFormField(
                        controller: _phoneController,
                        label: 'Telefon',
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: AppPaddings.card),
                    _buildTextFormField(
                        controller: _birthdayController,
                        label: 'Doğum Günü',
                        keyboardType: TextInputType.datetime),
                    const SizedBox(height: AppPaddings.card),
                    _buildGenderDropdown(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              if (viewModel.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label alanı boş bırakılamaz.';
        }
        return null;
      },
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<int>(
      value: _gender,
      decoration: InputDecoration(
        labelText: 'Cinsiyet',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: const [
        DropdownMenuItem(value: 1, child: Text('Erkek')),
        DropdownMenuItem(value: 2, child: Text('Kadın')),
        DropdownMenuItem(value: 3, child: Text('Belirtmek İstemiyorum')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _gender = value;
          });
        }
      },
    );
  }
} 