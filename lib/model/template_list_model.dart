class TemplatelistModel {
  final int templateId;
  final String templateName;
  final String formType;
  final String updatedBy;
  final DateTime updatedDate;
  final Map<String, dynamic> templateFormData;

  TemplatelistModel({
    required this.templateId,
    required this.templateName,
    required this.formType,
    required this.updatedBy,
    required this.updatedDate,
    required this.templateFormData,
  });
}
