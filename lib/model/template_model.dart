// Model adalah representasi/perwujudan sebuah tabel dari Struktur Database yang sudah dibuat.

class TemplateModel {
  // templateId = primary key dari table template->auto increment,gabisa untuk menyimpan templateId dari server
  final int templateId;

  // bikin column baru (id) untuk simpan templateId dari server, karena kalau primary (templateId), gabisa.
  // dari server templateId=7, masuk ke SQLite kita templateId=1.
  final int serverTemplateId;

  final String templateName;
  final String formType;
  final DateTime updatedDate;
  final Map<String, dynamic> templateFormData;
  final DateTime deletedAt;

  TemplateModel({
    required this.templateId,
    required this.serverTemplateId,
    required this.templateName,
    required this.formType,
    required this.updatedDate,
    required this.templateFormData,
    required this.deletedAt,
  });
}
