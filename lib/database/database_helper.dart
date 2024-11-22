import 'package:drone_checklist/model/checklist_form_model.dart';
import 'package:sqflite/sqflite.dart' as sqlite;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

class DatabaseHelper {
  static Future<void> createTables(sqlite.Database database) async {
    //aktifkan foreign key
    await database.execute("PRAGMA foreign_keys = ON");
    // await database.execute("DROP TABLE IF EXISTS form");

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
      formData TEXT,
      FOREIGN KEY (templateId) REFERENCES template(templateId) ON DELETE CASCADE
      )
    ''');

     
  }

  static Future<List<ChecklistFormModel>> getAllForms() async {
    final db = await DatabaseHelper.db();
    final maps = await db.query('form', orderBy: "formId");

    return List.generate(maps.length, (i) {
      final formMap = {
        ...maps[i],
        'formData': jsonDecode(maps[i]['formData'] as String),
      };
      return ChecklistFormModel.fromJson(formMap);
    });
  }

  static Future<String> getDBPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/drone_checklist.db').path;
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

  static Future<int> createChecklistForm(ChecklistFormModel model) async {
    final db = await DatabaseHelper.db();

    final form = {
      'templateId': model.templateId,
      'formName': model.formName,
      'formData': jsonEncode(model.formData)
    };

    
    final formId = await db.insert('form', form,
        conflictAlgorithm: sqlite.ConflictAlgorithm.replace);

    final listForm=await db.query("form");

    listForm.forEach((element) {
      print(element);
    },);
    print(formId);

    return formId;
  }

  static Future<List<Map<String, dynamic>>> getAllData() async{
    //testing path db
    // String path=await DatabaseHelper.getDBPath();
    // print(path);

    final db = await DatabaseHelper.db();
    return db.query(
      "form",
      orderBy: "formId"
    );
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

  // static Future<int> createTemplate({
  //   required String templateName,
  //   required String formType,
  //   required String updatedBy,
  //   required String templateFormData,
  // }) async {
  //   final db = await DatabaseHelper.db();
  //
  //   final template = {
  //     'templateName': templateName,
  //     'formType': formType,
  //     'updatedBy': updatedBy,
  //     'templateFormData': templateFormData,
  //   };
  //
  //   // Inserting the data into the template table
  //   final templateId = await db.insert(
  //     'template',
  //     template,
  //     conflictAlgorithm: sqlite.ConflictAlgorithm.replace,
  //   );
  //
  //   return templateId;
  // }
}
