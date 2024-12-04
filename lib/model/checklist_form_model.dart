class ChecklistFormModel {
  final int? formId;
  final int templateId;
  final String formName;
  final DateTime updatedDate;
  final Map<String, dynamic> formData;
  final DateTime? deletedAt;

  ChecklistFormModel({
    required this.formId,
    required this.templateId,
    required this.formName,
    required this.updatedDate,
    required this.formData,
    this.deletedAt,
  });

  // Convert model to JSON/Map for database
  Map<String, dynamic> toJson() {
    return {
      'formId': formId,
      'templateId': templateId,
      'formName': formName,
      'updatedDate': updatedDate.toIso8601String(),
      'formData': formData,
      'deletedAt' : deletedAt,
    };
  }

  // Create model from JSON/Map
  factory ChecklistFormModel.fromJson(Map<String, dynamic> json) {
    return ChecklistFormModel(
      formId: json['formId'],
      templateId: json['templateId'],
      formName: json['formName'],
      updatedDate: DateTime.parse(json['updatedDate']),
      formData: Map<String, dynamic>.from(json['formData']),
      deletedAt: DateTime.parse(json['deletedAt']),
    );
  }
}
