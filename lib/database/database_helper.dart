import 'package:drone_checklist/model/form_model.dart';
import 'package:drone_checklist/model/template_model.dart';
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
      updatedFormData TEXT,
      syncStatus INTEGER DEFAULT 0,
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

  static Future<void> updateSyncStatus(int formId, int syncStatus) async {
    final db = await DatabaseHelper.db();

    await db.update(
        'form', {'syncStatus': syncStatus},
        where: 'formId = ?', whereArgs: [formId]);
  }

  static Future<int> createForm(FormModel model) async {
    final db = await DatabaseHelper.db();

    final form = {
      'templateId': model.templateId,
      'serverTemplateId': model.serverTemplateId,
      'formName': model.formName,
      'formData': jsonEncode(model.formData),
      'updatedFormData': jsonEncode(model.updatedFormData),
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
      int formId, String formData, String updatedFormData) async {
    final db = await DatabaseHelper.db();

    final form = {
      // 'formId' : formId,
      // 'formName': formName,
      'formData': formData,
      'updatedFormData': updatedFormData
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

  static Future<int> insertTemplate(TemplateModel model) async {
    final db = await DatabaseHelper.db();
    //return await db.insert("template", templateData);

    final template = {
      'serverTemplateId' : model.serverTemplateId,
      'templateName' : model.templateName,
      'formType' : model.formType,
      'templateFormData' : jsonEncode(model.templateFormData),
      'deletedAt' : null
    };

    final templateId = await db.insert('template', template);
    final listTemplate = await db.query("template");
    for (var element in listTemplate) {
      print(element);
    }

    return templateId;
  }

  static Future<List<Map<String, dynamic>>> getAllForms() async{
    final db = await DatabaseHelper.db();
    return db.query("form", orderBy: "formId");
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
