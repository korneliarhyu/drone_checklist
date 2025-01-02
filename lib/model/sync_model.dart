class SyncModel {
  final String submissionName;
  final int templateId;
  final String submittedBy;
  final DateTime submittedDate;
  final String formData;

  SyncModel({
    required this.submissionName,
    required this.templateId,
    required this.submittedBy,
    required this.submittedDate,
    required this.formData,
  });

  factory SyncModel.fromJson(Map<String, dynamic> json) {
    return SyncModel(
      submissionName: json['submissionName'],
      templateId: json['templateId'],
      submittedBy: json['submittedBy'],
      submittedDate: DateTime.parse(json['submittedDate']),
      formData: json['formData'],
    );
  }
}
