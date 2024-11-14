class ChecklistFormModel {
  final int? formId;
  final int templateId;
  final String formName;
  final String updatedBy;
  final DateTime updatedDate;
  final Map<String, dynamic> checklistFormData;

  ChecklistFormModel({
    required this.formId,
    required this.templateId,
    required this.formName,
    required this.updatedBy,
    required this.updatedDate,
    required this.checklistFormData,
  });

  // Convert model to JSON/Map for database
  Map<String, dynamic> toJson() {
    return {
      'formId': formId,
      'templateId': templateId,
      'formName': formName,
      'updatedBy': updatedBy,
      'updatedDate': updatedDate.toIso8601String(),
      'checklistFormData': checklistFormData,
    };
  }

  // Create model from JSON/Map
  factory ChecklistFormModel.fromJson(Map<String, dynamic> json) {
    return ChecklistFormModel(
      formId: json['formId'],
      templateId: json['templateId'],
      formName: json['formName'],
      updatedBy: json['updatedBy'],
      updatedDate: DateTime.parse(json['updatedDate']),
      checklistFormData: Map<String, dynamic>.from(json['checklistFormData']),
    );
  }
}
