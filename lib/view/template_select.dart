import 'package:drone_checklist/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'checklist_form_create.dart';

class SelectForm extends StatelessWidget {
  const SelectForm({super.key});

  Future<List<Map<String, dynamic>>> _fetchTemplates() async {
    return await DatabaseHelper.getAllTemplates();
  }

  @override
  Widget build(BuildContext context) {
    const String appTitle = 'Select a Template';
    return MaterialApp(
      title: appTitle,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(appTitle),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchTemplates(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (snapshot.data != null && snapshot.data!.isEmpty) {
              return const Center(child: Text("No templates available."));
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var chosenTemp = snapshot.data![index];
                  return Card(
                    margin: const EdgeInsets.all(15),

                    // Menggunakan List Tile untuk layout setiap card.
                    child: ListTile(
                      leading: const Icon(Icons.description, color: Colors.blue), // Leading icon
                      title: Text(
                        chosenTemp['templateName'],
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Template ID: ${chosenTemp['templateId']}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey), // Trailing icon
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateForm(
                            templateId: chosenTemp['templateId'],
                            templateName: chosenTemp['templateName'],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
