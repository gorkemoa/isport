/// İş ilanı listeleme isteği için model
class JobListRequest {
  final String? userToken;
  final int? catID;
  final List<int>? workTypes;
  final int? cityID;
  final int? districtID;
  final String? publishDate;
  final String? sort;
  final String? latitude;
  final String? longitude;
  final int page;

  JobListRequest({
    this.userToken,
    this.catID,
    this.workTypes,
    this.cityID,
    this.districtID,
    this.publishDate,
    this.sort,
    this.latitude,
    this.longitude,
    required this.page,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'page': page,
    };
    if (userToken != null) data['userToken'] = userToken;
    if (catID != null) data['catID'] = catID;
    if (workTypes != null) data['workTypes'] = workTypes;
    if (cityID != null) data['cityID'] = cityID;
    if (districtID != null) data['districtID'] = districtID;
    if (publishDate != null) data['publishDate'] = publishDate;
    if (sort != null) data['sort'] = sort;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    return data;
  }
}

/// İş ilanı modeli
class Job {
  final int compID;
  final int jobID;
  final String jobTitle;
  final String jobDesc;
  final String jobImage;
  final String jobCity;
  final String jobDistrict;
  final String compName;
  final String workType;
  final String showDate;
  final bool isFavorite;
  final double? distanceKM;

  Job({
    required this.compID,
    required this.jobID,
    required this.jobTitle,
    required this.jobDesc,
    required this.jobImage,
    required this.jobCity,
    required this.jobDistrict,
    required this.compName,
    required this.workType,
    required this.showDate,
    required this.isFavorite,
    this.distanceKM,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      compID: json['compID'] ?? 0,
      jobID: json['jobID'] ?? 0,
      jobTitle: json['jobTitle'] ?? '',
      jobDesc: json['jobDesc'] ?? '',
      jobImage: json['jobImage'] ?? '',
      jobCity: json['jobCity'] ?? '',
      jobDistrict: json['jobDistrict'] ?? '',
      compName: json['compName'] ?? '',
      workType: json['workType'] ?? '',
      showDate: json['showDate'] ?? '',
      isFavorite: json['isFavorite'] ?? false,
      distanceKM: json['distanceKM'] != null ? (json['distanceKM'] as num).toDouble() : null,
    );
  }

  factory Job.empty() {
    return Job(
      compID: 0,
      jobID: 0,
      jobTitle: '',
      jobDesc: '',
      jobImage: '',
      jobCity: '',
      jobDistrict: '',
      compName: '',
      workType: '',
      showDate: '',
      isFavorite: false,
      distanceKM: null,
    );
  }

  Job copyWith({
    int? compID,
    int? jobID,
    String? jobTitle,
    String? jobDesc,
    String? jobImage,
    String? jobCity,
    String? jobDistrict,
    String? compName,
    String? workType,
    String? showDate,
    bool? isFavorite,
    double? distanceKM,
  }) {
    return Job(
      compID: compID ?? this.compID,
      jobID: jobID ?? this.jobID,
      jobTitle: jobTitle ?? this.jobTitle,
      jobDesc: jobDesc ?? this.jobDesc,
      jobImage: jobImage ?? this.jobImage,
      jobCity: jobCity ?? this.jobCity,
      jobDistrict: jobDistrict ?? this.jobDistrict,
      compName: compName ?? this.compName,
      workType: workType ?? this.workType,
      showDate: showDate ?? this.showDate,
      isFavorite: isFavorite ?? this.isFavorite,
      distanceKM: distanceKM ?? this.distanceKM,
    );
  }
}

/// İş ilanları listesi verisi
class JobListData {
  final int page;
  final int pageSize;
  final int totalPages;
  final int totalItems;
  final String emptyMessage;
  final List<Job> jobs;

  JobListData({
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.totalItems,
    required this.emptyMessage,
    required this.jobs,
  });

  factory JobListData.fromJson(Map<String, dynamic> json) {
    var jobList = json['jobs'] as List;
    List<Job> jobs = jobList.map((i) => Job.fromJson(i)).toList();
    
    return JobListData(
      page: json['page'] ?? 0,
      pageSize: json['pageSize'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      totalItems: json['totalItems'] ?? 0,
      emptyMessage: json['emptyMessage'] ?? '',
      jobs: jobs,
    );
  }
}

/// İş ilanı listeleme yanıtı için model
class JobListResponse {
  final bool error;
  final bool success;
  final JobListData? data;
  final String? message410;

  JobListResponse({
    required this.error,
    required this.success,
    this.data,
    this.message410,
  });

  factory JobListResponse.fromJson(Map<String, dynamic> json) {
    return JobListResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? JobListData.fromJson(json['data']) : null,
      message410: json['410'],
    );
  }
} 