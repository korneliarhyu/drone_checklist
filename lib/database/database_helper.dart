import 'package:drone_checklist/model/checklist_form_model.dart';
import 'package:sqflite/sqflite.dart' as sqlite;
import 'dart:convert';

class DatabaseHelper {
  static Future<void> createTables(sqlite.Database database) async {
    //aktifkan foreign key
    await database.execute("PRAGMA foreign_keys = ON");

    //membuat table template
    await database.execute('''CREATE TABLE template(
      templateId INTEGER PRIMARY KEY AUTOINCREMENT,
      templateName TEXT,
      formType TEXT,
      updatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      templateFormData TEXT,
      deletedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    ''');

    //membuat table form
    await database.execute('''CREATE TABLE form (
      formId INTEGER PRIMARY KEY AUTOINCREMENT,
      templateId INTEGER,
      formName TEXT,
      updatedBy TEXT,
      updatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      formData TEXT,
      deletedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      
      )
    ''');
    // foreign key sementara dihilangkan karena belum ada templateId.
    // FOREIGN KEY (templateId) REFERENCES template(templateId) ON DELETE CASCADE
     
  }

  // static Future<List<ChecklistFormModel>> getAllForms() async {
  //   final db = await DatabaseHelper.db();
  //   final maps = await db.query('form', orderBy: "formId");
  //
  //   return List.generate(maps.length, (i) {
  //     final formMap = {
  //       ...maps[i],
  //       'formData': jsonDecode(maps[i]['formData'] as String),
  //     };
  //     return ChecklistFormModel.fromJson(formMap);
  //   });
  // }


  //jika database ada maka buka
  static Future<sqlite.Database> db() async {
    return sqlite.openDatabase(
      "drone_checklist", version: 1,
      //jika tidak ada maka buat database baru
      onCreate: (sqlite.Database database, int version) async {
        await createTables(database);
      },
      onOpen: (db) async {
        await db.execute("PRAGMA foreign_keys = ON");
      },
    );
  }

  static Future<int> createChecklistForm(ChecklistFormModel model) async {
    final db = await DatabaseHelper.db();

    final form = {
      'templateId': model.templateId,
      'formName': model.formName,
      'formData': jsonEncode(model.formData)
    };

    
    final formId = await db.insert('form', form);

    final listForm=await db.query("form");

    for (var element in listForm) {
      print(element);
    }
    print(formId);

    return formId;
  }

  static Future<List<Map<String, dynamic>>> getAllChecklist() async{
    //testing path db
    // String path=await DatabaseHelper.getDBPath();
    // print(path);

    final db = await DatabaseHelper.db();
    return db.query(
      "form",
      orderBy: "formId"
    );
  }

  static Future<List<Map<String, dynamic>>> getAllTemplates() async{
    //testing path db
    // String path=await DatabaseHelper.getDBPath();
    // print(path);

    final db = await DatabaseHelper.db();
    List<Map<String, dynamic>> templates = await db.query('template');
    return templates;
  }

  static Future<Map<String, dynamic>?> getTemplateById(int id) async {
    final db = await DatabaseHelper.db();
    List<Map> results = await db.query(
      'template',
      where: 'templateId = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return Map<String, dynamic>.from(results.first);
    }
    return null;

  }

  static Future<int> updateForm(
      int formId, int templateId, String formName, String formData) async {
    final db = await DatabaseHelper.db();

    final form = {
      // 'formId' : formId,
      'templateId': templateId,
      'formName': formName,
      'formData': formData
    };

    final result =
        await db.update("form", form, where: "formId = ?", whereArgs: [formId]);

    return result;
  }

  static Future<void> deleteForm(int formId) async {
    final db = await DatabaseHelper.db();

    try {
      await db.delete(
          'form',
          where: "formId = ?",
          whereArgs: [formId]);
    } catch (e) {
      print("Delete Failed: $e");
    }
  }



//   String stringTemplate = """{
//       "question1": {
//   "question": "Question no.1",
//   "type": "multiple",
//   "option": ["multiple1", "multiple2", "multiple3"],
//   "required": true
//   },
//   "question2": {
//   "question": "Question no.2",
//   "type": "checklist",
//   "option": ["checklist1", "checklist2", "checklist3"],
//   "required": true
//   },
//   "question3": {
//   "question": "Question no.3",
//   "type": "dropdown",
//   "option": ["dropdown1", "dropdown2", "dropdown3"],
//   "required": true
//   },
//   "question4": {
//   "question": "Question no.4",
//   "type": "text",
//   "option": [],
//   "required": true
//   }
// }""";
//
//   //insert template data
//   void insertDummyTemplate() async{
//     final db = await DatabaseHelper.db();
//
//     await db.rawInsert('INSERT INTO template (templateId, templateName, formType, updatedBy, updatedDate, templateFormData) VALUES (?,?,?,?,?,?)',
//       ['1', 'test1', 'postFlight', 'feli', DateTime.now().toString(), stringTemplate],
//     );
//
//   }
//
//   Future<Map<String, dynamic>> getRandomTemplate() async{
//
//     final db = await DatabaseHelper.db();
//     List<Map<String, dynamic>> loRtn = await db.rawQuery('SELECT TOP 1 templateFormData FROM template');
//
//     return loRtn.first;
//   }
}
