import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/job_service.dart';
import '../../models/job_models.dart';
import '../../models/user_model.dart';
import '../../services/logger_service.dart';

class AddJobScreen extends StatefulWidget {
  final UserModel user;
  final JobDetailModel? editJob; // Null ise yeni ilan, dolu ise güncelleme

  const AddJobScreen({
    super.key,
    required this.user,
    this.editJob,
  });

  @override
  State<AddJobScreen> createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final JobService _jobService = JobService();
  
  // Form kontrolcüleri
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _salaryMinController = TextEditingController();
  final TextEditingController _salaryMaxController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _longController = TextEditingController();

  // Seçimler
  int _selectedCategoryId = 40; // Örnek kategori ID
  WorkType _selectedWorkType = WorkType.fullTime;
  SalaryType? _selectedSalaryType;
  bool _isHighlighted = false;
  List<BenefitType> _selectedBenefits = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.editJob != null) {
      // Güncelleme modu - mevcut değerleri doldur
      final job = widget.editJob!;
      _titleController.text = job.jobTitle;
      _descController.text = job.jobDesc;
      _selectedWorkType = WorkType.fromId(1); // API'den gelen workType'a göre ayarla
      _selectedSalaryType = job.salaryMin.isNotEmpty ? SalaryType.monthly : null;
      _salaryMinController.text = job.salaryMin;
      _salaryMaxController.text = job.salaryMax;
      _isHighlighted = job.isHighlighted;
      _selectedBenefits = BenefitType.fromIds(job.benefits.map((e) => int.tryParse(e) ?? 0).toList());
    } else {
      // Yeni ilan modu - şirket lokasyonu varsayılan olarak ekle
      final company = widget.user.company;
      if (company != null) {
        _latController.text = '38.4192'; // Varsayılan
        _longController.text = '27.1287'; // Varsayılan
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.editJob != null ? 'İş İlanı Güncelle' : 'Yeni İş İlanı',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black54),
      ),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İş İlanı Başlığı
            _buildSection(
              title: 'Temel Bilgiler',
              child: Column(
                children: [
                  _buildTextFormField(
                    controller: _titleController,
                    label: 'İş İlanı Başlığı',
                    hintText: 'Örn: PHP Yazılım Uzmanı',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'İş başlığı gereklidir';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _descController,
                    label: 'İş Açıklaması',
                    hintText: 'İş tanımı, gereksinimler, şartlar...',
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'İş açıklaması gereklidir';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Çalışma Tipi ve Maaş
            _buildSection(
              title: 'Çalışma Koşulları',
              child: Column(
                children: [
                  _buildDropdown<WorkType>(
                    label: 'Çalışma Tipi',
                    value: _selectedWorkType,
                    items: WorkType.values.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedWorkType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown<SalaryType?>(
                    label: 'Maaş Tipi (Opsiyonel)',
                    value: _selectedSalaryType,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Seçiniz'),
                      ),
                      ...SalaryType.values.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSalaryType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _salaryMinController,
                          label: 'Min Maaş (Opsiyonel)',
                          hintText: '25000',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _salaryMaxController,
                          label: 'Max Maaş (Opsiyonel)',
                          hintText: '35000',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Lokasyon
            _buildSection(
              title: 'Lokasyon',
              child: Row(
                children: [
                  Expanded(
                    child: _buildTextFormField(
                      controller: _latController,
                      label: 'Enlem',
                      hintText: '38.4192',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enlem gereklidir';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextFormField(
                      controller: _longController,
                      label: 'Boylam',
                      hintText: '27.1287',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Boylam gereklidir';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Yan Haklar
            _buildSection(
              title: 'Yan Haklar (Opsiyonel)',
              child: Column(
                children: BenefitType.values.map((benefit) => CheckboxListTile(
                  title: Text(benefit.displayName),
                  value: _selectedBenefits.contains(benefit),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedBenefits.add(benefit);
                      } else {
                        _selectedBenefits.remove(benefit);
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                )).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Öne Çıkarma
            _buildSection(
              title: 'Ek Özellikler',
              child: SwitchListTile(
                title: const Text('Öne Çıkar'),
                subtitle: const Text('İlanınızın öne çıkmasını sağlar'),
                value: _isHighlighted,
                onChanged: (bool value) {
                  setState(() {
                    _isHighlighted = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 30),

            // Kaydet Butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.editJob != null ? 'İlanı Güncelle' : 'İlanı Yayınla',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade600),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue.shade600),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken') ?? '';

      if (userToken.isEmpty) {
        _showSnackBar('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
        return;
      }

      final company = widget.user.company!;
      final salaryMin = _salaryMinController.text.isNotEmpty ? int.tryParse(_salaryMinController.text) : null;
      final salaryMax = _salaryMaxController.text.isNotEmpty ? int.tryParse(_salaryMaxController.text) : null;
      final lat = double.tryParse(_latController.text) ?? 0.0;
      final long = double.tryParse(_longController.text) ?? 0.0;

      if (widget.editJob != null) {
        // Güncelleme
        final request = UpdateJobRequest(
          userToken: userToken,
          jobID: widget.editJob!.jobID,
          jobTitle: _titleController.text,
          jobDesc: _descController.text,
          catID: _selectedCategoryId,
          jobCity: company.compCityNo,
          jobDistrict: company.compDistrictNo,
          jobLat: lat,
          jobLong: long,
          isHighlighted: _isHighlighted ? 1 : 0,
          salaryType: _selectedSalaryType?.id,
          salaryMin: salaryMin,
          salaryMax: salaryMax,
          workType: _selectedWorkType.id,
          benefits: _selectedBenefits.map((b) => b.id).toList(),
          isActive: 1,
        );

        final response = await _jobService.updateJob(company.compID, request);
        
        if (response.isSuccessful) {
          _showSnackBar('İş ilanı başarıyla güncellendi!');
          Navigator.pop(context, true);
        } else {
          _showSnackBar(response.displayMessage ?? 'İş ilanı güncellenemedi');
        }
      } else {
        // Yeni ekleme
        final request = AddJobRequest(
          userToken: userToken,
          jobTitle: _titleController.text,
          jobDesc: _descController.text,
          catID: _selectedCategoryId,
          jobCity: company.compCityNo,
          jobDistrict: company.compDistrictNo,
          jobLat: lat,
          jobLong: long,
          isHighlighted: _isHighlighted ? 1 : 0,
          salaryType: _selectedSalaryType?.id,
          salaryMin: salaryMin,
          salaryMax: salaryMax,
          workType: _selectedWorkType.id,
          benefits: _selectedBenefits.map((b) => b.id).toList(),
        );

        final response = await _jobService.addJob(company.compID, request);
        
        if (response.isSuccessful) {
          _showSnackBar('İş ilanı başarıyla eklendi!');
          Navigator.pop(context, true);
        } else {
          _showSnackBar(response.displayMessage ?? 'İş ilanı eklenemedi');
        }
      }
    } catch (e) {
      logger.debug('İş ilanı kaydetme hatası: $e');
      _showSnackBar('Bir hata oluştu. Lütfen tekrar deneyin.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _latController.dispose();
    _longController.dispose();
    super.dispose();
  }
} 