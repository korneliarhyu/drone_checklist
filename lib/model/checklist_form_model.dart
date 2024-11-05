class ChecklistFormModel {
  final int formId;
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

  // Add methods to convert to/from JSON if needed
}
