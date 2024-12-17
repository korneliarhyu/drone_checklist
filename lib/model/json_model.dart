class Template {
  final int id;
  final String templateName;
  // final Map<String, dynamic> templateData;

  Template({
    required this.id,
    required this.templateName,
    //required this.templateData
  });

  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      id: json['id'],
      templateName: json['templateName'],
      // templateData: json['templateData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'templateName': templateName,
      // 'templateData': templateData,
    };
  }
}
