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
      updatedDate TIMPESTAMP DEFAULT CURRENT_TIMESTAMP,
      formData TEXT,
      FOREIGN KEY (templateID) REFERENCES template(templateID) ON DELETE CASCADE
      )
    ''');
  }

  //jika database ada maka buka
  static Future<sqlite.Database> db() async {
    return sqlite.openDatabase("drone_checklist_database", version: 1,
        //jika tidak ada maka buat database baru
        onCreate: (sqlite.Database database, int version) async {
      await createTables(database);
    });
  }
  


}
