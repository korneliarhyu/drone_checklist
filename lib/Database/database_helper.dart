import 'package:drone_flight_checklist/model/checklist_form_model.dart';
import 'package:sqflite/sqflite.dart' as sqlite;

class DatabaseHelper {
  static Future<void> createTables(sqlite.Database database) async {
    //aktifkan foreign key
    await database.execute("PRAGMA foreign_keys = ON");

    //membuat table template
    await database.execute('''CREATE TABLE template(
      templateId INTEGER PRIMARY KEY AUTOINCREMENT,
      templateName TEXT,
      formType TEXT,
      updatedBy TEXT,
      updatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      templateFormData TEXT
    )
    ''');

    //membuat table form
    await database.execute('''CREATE TABLE form (
      formId INTEGER PRIMARY KEY AUTOINCREMENT,
      templateId INTEGER,
      formName TEXT,
      updatedBy TEXT,
      updatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      checklistFormData TEXT,
      FOREIGN KEY (templateId) REFERENCES template(templateId) ON DELETE CASCADE
      )
    ''');
  }

  //jika database ada maka buka
  static Future<sqlite.Database> db() async {
    return sqlite.openDatabase(
      "drone_checklist_database", version: 1,
      //jika tidak ada maka buat database baru
      onCreate: (sqlite.Database database, int version) async {
        await createTables(database);
      },
      onOpen: (db) async {
        await db.execute("PRAGMA foreign_keys = ON");
      },
    );
  }

//hallooo

  static Future<int> createChecklistForm(ChecklistFormModel model) async {
  final db = await DatabaseHelper.db();

  // Creating the data map for insertion
  final form = {
    'templateId': model.templateId,
    'formName': model.formName,
    'checklistFormData': model.checklistFormData
  };

  final formId = await db.insert(
    'form',
    form,
    conflictAlgorithm: sqlite.ConflictAlgorithm.replace
  );

  return formId;
}


  static Future<List<Map<String, dynamic>>> getAllData() async{
    final db = await DatabaseHelper.db();
    return db.query(
      "form", 
      orderBy: "formId"
    );
  }

  static Future<List<Map<String, dynamic>>> getSingleData(int formId) async {
    final db = await DatabaseHelper.db();

    return db.query(
      "form",
      where: "formId = ?",
      whereArgs: [formId],
      limit: 1
    );
  }

  static Future<int> updateForm(int formId, int templateId, String formName, String checklistFormData) async {
    final db = await DatabaseHelper.db();

    final form = {
      // 'formId' : formId,
      'templateId' : templateId,
      'formName' : formName,
      'checklistFormData' : checklistFormData
    };

    final result = await db.update(
      "form", 
      form,
      where: "formId = ?",
      whereArgs: [formId]
    );

    return result;
  }

  static Future<void> deleteData(int formId) async {
    final db = await DatabaseHelper.db();

    try{
      await db.delete(
        "form", 
        where: "formId = ?",
        whereArgs:[formId]
      );
    } catch (e) {
      print("Delete Failed for $e");
    }
  }

  static Future<int> createTemplate({
  required String templateName,
  required String formType,
  required String updatedBy,
  required String templateFormData,
  }) async {
  final db = await DatabaseHelper.db();

  // Creating the data map for insertion
  final template = {
    'templateName': templateName,
    'formType': formType,
    'updatedBy': updatedBy,
    'templateFormData': templateFormData,
  };

  // Inserting the data into the 'template' table
  final templateId = await db.insert(
    'template',
    template,
    conflictAlgorithm: sqlite.ConflictAlgorithm.replace,
  );

  return templateId;
}

//   static Future<void> addTemplateExample() async {
//   final templateId = await DatabaseHelper.createTemplate(
//     templateName: 'Sample Template', 
//     formType: 'Checklist', 
//     updatedBy: 'Admin', 
//     templateFormData: 
//       '{"Name": "text", "Weather": "text", "Condition": "Text"}', 
//   );
// }

}
