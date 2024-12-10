import 'package:drone_checklist/database/database_helper.dart';

class TemplatelistController {

  // Method to retrieve templates from the database
  Future<List<Map<String, dynamic>>> getTemplates() async {
    final db = await DatabaseHelper.db();
    // Assuming the 'template' table stores data in this format
    final List<Map<String, dynamic>> templates = await db.query('template');
    return templates;
  }


}
