/// İş ilanı detay modeli
class JobDetail {
  final int jobID;
  final String jobTitle;
  final String jobDesc;
  final String catName;
  final String cityName;
  final String districtName;
  final int compID;
  final String compName;
  final String salaryMin;
  final String salaryMax;
  final String salaryType;
  final String workType;
  final bool isHighlighted;
  final bool isActive;
  final String showDate;
  final String createDate;
  final bool isApplied;
  final bool isFavorite;
  final List<String> benefits;

  JobDetail({
    required this.jobID,
    required this.jobTitle,
    required this.jobDesc,
    required this.catName,
    required this.cityName,
    required this.districtName,
    required this.compID,
    required this.compName,
    required this.salaryMin,
    required this.salaryMax,
    required this.salaryType,
    required this.workType,
    required this.isHighlighted,
    required this.isActive,
    required this.showDate,
    required this.createDate,
    required this.isApplied,
    required this.isFavorite,
    required this.benefits,
  });

  factory JobDetail.fromJson(Map<String, dynamic> json) {
    return JobDetail(
      jobID: json['jobID'] ?? 0,
      jobTitle: json['jobTitle'] ?? '',
      jobDesc: json['jobDesc'] ?? '',
      catName: json['catName'] ?? '',
      cityName: json['cityName'] ?? '',
      districtName: json['districtName'] ?? '',
      compID: json['compID'] ?? 0,
      compName: json['compName'] ?? '',
      salaryMin: json['salaryMin'] ?? '',
      salaryMax: json['salaryMax'] ?? '',
      salaryType: json['salaryType'] ?? '',
      workType: json['workType'] ?? '',
      isHighlighted: json['isHighlighted'] ?? false,
      isActive: json['isActive'] ?? false,
      showDate: json['showDate'] ?? '',
      createDate: json['createDate'] ?? '',
      isApplied: json['isApplied'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
      benefits: json['benefits'] != null ? List<String>.from(json['benefits']) : <String>[],
    );
  }
}

/// İş ilanı detay verisi (job + similarJobs)
class JobDetailData {
  final JobDetail job;
  final List<dynamic> similarJobs; // gelecek tasarım için

  JobDetailData({required this.job, required this.similarJobs});

  factory JobDetailData.fromJson(Map<String, dynamic> json) {
    return JobDetailData(
      job: JobDetail.fromJson(json['job'] ?? {}),
      similarJobs: json['similarJobs'] ?? [],
    );
  }
}

/// İş ilanı detay yanıtı
class JobDetailResponse {
  final bool error;
  final bool success;
  final JobDetailData? data;
  final String? message410;

  JobDetailResponse({
    required this.error,
    required this.success,
    this.data,
    this.message410,
  });

  factory JobDetailResponse.fromJson(Map<String, dynamic> json) {
    return JobDetailResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? JobDetailData.fromJson(json['data']) : null,
      message410: json['410'],
    );
  }
} 