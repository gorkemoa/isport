import 'dart:convert';

/// API'den gelen tam yanıtı temsil eder.
class CompanyDetailResponse {
  final bool error;
  final bool success;
  final CompanyDetailData? data;
  final String? message;

  CompanyDetailResponse({
    required this.error,
    required this.success,
    this.data,
    this.message,
  });

  factory CompanyDetailResponse.fromJson(Map<String, dynamic> json) {
    return CompanyDetailResponse(
      error: json['error'] ?? true,
      success: json['success'] ?? false,
      data: json['data'] != null ? CompanyDetailData.fromJson(json['data']) : null,
      message: json['410'],
    );
  }
}

/// Yanıttaki 'data' nesnesini temsil eder.
class CompanyDetailData {
  final CompanyInfo? company;
  final List<CompanyJob> jobs;

  CompanyDetailData({
    this.company,
    required this.jobs,
  });

  factory CompanyDetailData.fromJson(Map<String, dynamic> json) {
    return CompanyDetailData(
      company: json['company'] != null ? CompanyInfo.fromJson(json['company']) : null,
      jobs: (json['jobs'] as List<dynamic>?)
              ?.map((e) => CompanyJob.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 'data' içindeki 'company' nesnesini temsil eder.
class CompanyInfo {
  final int compID;
  final String compName;
  final String compDesc;
  final String compAddress;
  final String compCity;
  final String compDistrict;
  final String profilePhoto;

  CompanyInfo({
    required this.compID,
    required this.compName,
    required this.compDesc,
    required this.compAddress,
    required this.compCity,
    required this.compDistrict,
    required this.profilePhoto,
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      compID: json['compID'] ?? 0,
      compName: json['compName'] ?? '',
      compDesc: json['compDesc'] ?? '',
      compAddress: json['compAddress'] ?? '',
      compCity: json['compCity'] ?? '',
      compDistrict: json['compDistrict'] ?? '',
      profilePhoto: json['profilePhoto'] ?? '',
    );
  }
}

/// 'data' içindeki 'jobs' listesindeki her bir iş ilanını temsil eder.
class CompanyJob {
  final int jobID;
  final String jobTitle;
  final String workType;
  final String showDate;

  CompanyJob({
    required this.jobID,
    required this.jobTitle,
    required this.workType,
    required this.showDate,
  });

  factory CompanyJob.fromJson(Map<String, dynamic> json) {
    return CompanyJob(
      jobID: json['jobID'] ?? 0,
      jobTitle: json['jobTitle'] ?? '',
      workType: json['workType'] ?? '',
      showDate: json['showDate'] ?? '',
    );
  }
} 