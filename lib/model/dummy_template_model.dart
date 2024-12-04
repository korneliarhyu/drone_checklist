class DummyTemplateModel {
  final int templateId;
  final String templateName;
  final String formType;
  final DateTime updatedDate;
  final Map<String, dynamic> templateFormData;
  final DateTime deletedAt;

  DummyTemplateModel({
    required this.templateId,
    required this.templateName,
    required this.formType,
    required this.updatedDate,
    required this.templateFormData,
    required this.deletedAt,
  });
}
