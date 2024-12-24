import 'package:drone_checklist/model/form_model.dart';
import 'package:sqflite/sqflite.dart' as sqlite;
import 'dart:convert';

class DatabaseHelper {
  static Future<void> createTables(sqlite.Database database) async {
    //aktifkan foreign key
    await database.execute("PRAGMA foreign_keys = ON");

    //membuat table template
    await database.execute('''CREATE TABLE template(
      templateId INTEGER PRIMARY KEY AUTOINCREMENT,
      serverTemplateId INTEGER,
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
      serverTemplateId INTEGER,
      templateId INTEGER,
      formName TEXT,
      updatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      formData TEXT,
      deletedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP      
      )
    ''');

    await database.execute('''CREATE TABLE dummy_template(
      templateId INTEGER PRIMARY KEY AUTOINCREMENT,
      templateName TEXT,
      formType TEXT,
      updatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      templateFormData TEXT,
      deletedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    ''');
  }

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

  static Future<int> createForm(FormModel model) async {
    final db = await DatabaseHelper.db();

    final form = {
      'templateId': model.templateId,
      'serverTemplateId': model.serverTemplateId,
      'formName': model.formName,
      'formData': jsonEncode(model.formData),
      'deletedAt': null
    };

    final formId = await db.insert('form', form);
    final listForm = await db.query("form");
    for (var element in listForm) {
      print(element);
    }
    print(formId);
    return formId;
  }

  static Future<int> updateForm(
      int formId, String formData) async {
    final db = await DatabaseHelper.db();

    final form = {
      // 'formId' : formId,
      // 'formName': formName,
      'formData': formData
    };

    final result =
        await db.update("form", form, where: "formId = ?", whereArgs: [formId]);

    return result;
  }

  static Future<void> deleteForm(int formId) async {
    final db = await DatabaseHelper.db();

    try {
      await db.delete('form', where: "formId = ?", whereArgs: [formId]);
    } catch (e) {
      print("Delete Failed: $e");
    }
  }

  static Future<void> deleteTemplate(int templateId) async {
    final db = await DatabaseHelper.db();

    try {
      await db
          .delete('template', where: "templateId = ?", whereArgs: [templateId]);
    } catch (e) {
      print("Delete Failed: $e");
    }
  }

  static Future<int> insertTemplate(Map<String, dynamic> templateData) async {
    final db = await DatabaseHelper.db();
    return await db.insert("template", templateData);
  }

  static Future<List<Map<String, dynamic>>> getAllChecklist() async {
    final db = await DatabaseHelper.db();

    return db.query("form", orderBy: "formId");


    // template dummy hanya dapat diinsert 1-1.
    // template 1
    var templateJson = jsonEncode({
      "questions": {
        "question1": {
          "question": "Is the drone's firmware updated?",
          "type": "dropdown",
          "options": ["Yes", "No", "Not Applicable"],
          "required": true
        },
        "question2": {
          "question": "Inspect propellers for damage",
          "type": "multiple",
          "options": [
            "No damage",
            "Minor damage",
            "Major damage",
            "Needs replacement"
          ],
          "required": true
        },
        "question3": {
          "question": "Battery charge level",
          "type": "text",
          "options": [],
          "required": true
        }
      }
    });

    final template = {
      'templateId': 2,
      'templateName': 'Drone Checklist',
      'formType': 'Pre-Flight',
      'updatedDate': '2024-11-24',
      'templateFormData': templateJson,
      'deletedAt': null
    };

    //return await db.insert('dummy_template', template);

  }

  static Future<List<Map<String, dynamic>>> getAllTemplates() async {
    final db = await DatabaseHelper.db();
    List<Map<String, dynamic>> templates = await db.query('template');
    return templates;
  }

  static Future<Map<String, dynamic>?> getFormById(int id) async {
    final db = await DatabaseHelper.db();
    List<Map> results = await db.query(
      'form',
      where: 'formId = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return Map<String, dynamic>.from(results.first);
    }
    return null;
  }

  static Future<Map<String, dynamic>> getTemplateById(int id) async {
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
    return <String, dynamic>{};
  }
}
