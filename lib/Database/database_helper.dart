import 'package:drone_flight_checklist/model/checklist_form_model.dart';
import 'package:sqflite/sqflite.dart' as sqlite;

class DatabaseHelper {
  static Future<void> createTables(sqlite.Database database) async {
    //aktifkan foreign key
    await database.execute("PRAGMA foreign_keys = ON");

    //membuat table template
    await database.execute('''CREATE TABLE template(
      templateID INTEGER PRIMARY KEY AUTOINCREMENT,
      templateName TEXT,
      formType TEXT,
      updatedBy TEXT,
      updatedDate TIMPESTAMP DEFAULT CURRENT_TIMESTAMP,
      templateFormData TEXT
    )
    ''');

    //membuat table form
    await database.execute('''CREATE TABLE form (
      formID INTEGER PRIMARY KEY AUTOINCREMENT,
      templateID INTEGER,
      formName TEXT,
      updatedBy TEXT,
      updatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      formData TEXT,
      FOREIGN KEY (templateID) REFERENCES template(templateID) ON DELETE CASCADE
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

  static Future<int> createChecklistForm(ChecklistFormModel model) async {
  final db = await DatabaseHelper.db();

  // Creating the data map for insertion
  final data = {
    'templateId': model.templateId,
    'formName': model.formName,
    'checklistFormData': model.checklistFormData
  };

  // Inserting into 'form' table, not 'data'
  final id = await db.insert(
    'form', // Correct table name
    data,
    conflictAlgorithm: sqlite.ConflictAlgorithm.replace
  );

  return id;
}


  static Future<List<Map<String, dynamic>>> getAllData() async{
    final db = await DatabaseHelper.db();
    return db.query(
      "data", 
      orderBy: "formID"
    );
  }

  static Future<List<Map<String, dynamic>>> getSingleData(int id) async {
    final db = await DatabaseHelper.db();

    return db.query(
      "data",
      where: "formID = ?",
      whereArgs: [id],
      limit: 1
    );
  }

  static Future<int> updateForm(int formID, int templateID, String formName, String formData) async {
    final db = await DatabaseHelper.db();

    final data = {
      'formID' : formID,
      'templateID' : templateID,
      'formName' : formName,
      'formData' : formData
    };

    final result = await db.update(
      "data", 
      data,
      where: "id = ?",
      whereArgs: [formID]
    );

    return result;
  }

  static Future<void> deleteData(int id) async {
    final db = await DatabaseHelper.db();

    try{
      await db.delete(
        "data", 
        where: "formID = ?",
        whereArgs:[id]
      );
    } catch (e) {
      print("Delete Failed for $e");
    }
  }
}
