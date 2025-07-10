/// Şirket iş ilanı modeli
class CompanyJob {
  final int jobID;
  final String jobTitle;
  final String jobDesc;
  final String catName;
  final String cityName;
  final String districtName;
  final String salaryMin;
  final String salaryMax;
  final String salaryType;
  final String workType;
  final bool isHighlighted;
  final bool isActive;
  final String showDate;
  final String createDate;
  final List<String> benefits;

  CompanyJob({
    required this.jobID,
    required this.jobTitle,
    required this.jobDesc,
    required this.catName,
    required this.cityName,
    required this.districtName,
    required this.salaryMin,
    required this.salaryMax,
    required this.salaryType,
    required this.workType,
    required this.isHighlighted,
    required this.isActive,
    required this.showDate,
    required this.createDate,
    required this.benefits,
  });

  factory CompanyJob.fromJson(Map<String, dynamic> json) {
    return CompanyJob(
      jobID: json['jobID'] ?? 0,
      jobTitle: json['jobTitle'] ?? '',
      jobDesc: json['jobDesc'] ?? '',
      catName: json['catName'] ?? '',
      cityName: json['cityName'] ?? '',
      districtName: json['districtName'] ?? '',
      salaryMin: json['salaryMin'] ?? '',
      salaryMax: json['salaryMax'] ?? '',
      salaryType: json['salaryType'] ?? '',
      workType: json['workType'] ?? '',
      isHighlighted: json['isHighlighted'] ?? false,
      isActive: json['isActive'] ?? false,
      showDate: json['showDate'] ?? '',
      createDate: json['createDate'] ?? '',
      benefits: json['benefits'] != null 
        ? List<String>.from(json['benefits'])
        : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobID': jobID,
      'jobTitle': jobTitle,
      'jobDesc': jobDesc,
      'catName': catName,
      'cityName': cityName,
      'districtName': districtName,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'salaryType': salaryType,
      'workType': workType,
      'isHighlighted': isHighlighted,
      'isActive': isActive,
      'showDate': showDate,
      'createDate': createDate,
      'benefits': benefits,
    };
  }

  String get formattedSalary {
    if (salaryMin.isNotEmpty && salaryMax.isNotEmpty) {
      return '$salaryMin - $salaryMax ₺ $salaryType';
    } else if (salaryMin.isNotEmpty) {
      return '$salaryMin ₺ $salaryType';
    } else if (salaryMax.isNotEmpty) {
      return '$salaryMax ₺\'ya kadar $salaryType';
    }
    return 'Maaş belirtilmemiş';
  }

  String get location {
    return '$cityName, $districtName';
  }

  String get benefitsText {
    if (benefits.isEmpty) return 'Belirtilmemiş';
    return benefits.join(', ');
  }
}

/// Şirket iş ilanları listesi verisi
class CompanyJobsData {
  final List<CompanyJob> jobs;

  CompanyJobsData({required this.jobs});

  factory CompanyJobsData.fromJson(Map<String, dynamic> json) {
    var jobList = json['jobs'] as List? ?? [];
    List<CompanyJob> jobs = jobList.map((i) => CompanyJob.fromJson(i)).toList();
    
    return CompanyJobsData(jobs: jobs);
  }
}

/// Şirket iş ilanları API yanıtı
class CompanyJobsResponse {
  final bool error;
  final bool success;
  final CompanyJobsData? data;
  final String? message410;

  CompanyJobsResponse({
    required this.error,
    required this.success,
    this.data,
    this.message410,
  });

  factory CompanyJobsResponse.fromJson(Map<String, dynamic> json) {
    return CompanyJobsResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? CompanyJobsData.fromJson(json['data']) : null,
      message410: json['410'],
    );
  }
} 