class Template {
  final int id;
  final String templateName;

  Template({required this.id, required this.templateName});

  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      id: json['id'],
      templateName: json['templateName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'templateName': templateName,
    };
  }
}
