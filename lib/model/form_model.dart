class FormModel {
  final int? formId;
  final int templateId;
  final int serverTemplateId;
  final String formName;
  final DateTime updatedDate;
  final List<Map<String, dynamic>> formData;
  final List<Map<String, dynamic>>? updatedFormData;
  final int? syncStatus;
  final DateTime? deletedAt;

  FormModel({
    required this.formId,
    required this.templateId,
    required this.serverTemplateId,
    required this.formName,
    required this.updatedDate,
    required this.formData,
    this.updatedFormData,
    this.syncStatus,
    this.deletedAt,
  });

  // Convert model to JSON/Map for database
  Map<String, dynamic> toJson() {
    return {
      'formId': formId,
      'templateId': templateId,
      'serverTemplateId': serverTemplateId,
      'formName': formName,
      'updatedDate': updatedDate.toIso8601String(),
      'formData': formData,
      'updatedFormData': updatedFormData,
      'syncStatus': syncStatus,
      'deletedAt' : deletedAt,
    };
  }

  // Create model from JSON/Map
  factory FormModel.fromJson(Map<String, dynamic> json) {
    return FormModel(
      formId: json['formId'],
      templateId: json['templateId'],
      serverTemplateId: json['serverTemplateId'],
      formName: json['formName'],
      updatedDate: DateTime.parse(json['updatedDate']),
      formData: List<Map<String, dynamic>>.from(json['formData']),
      syncStatus: json['syncStatus'],
      deletedAt: DateTime.parse(json['deletedAt']),
    );
  }
}
