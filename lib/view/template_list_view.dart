import 'package:drone_checklist/database/database_helper.dart';
import 'package:drone_checklist/view/template_detail.dart';
import 'package:flutter/material.dart';

class TemplateListView extends StatelessWidget {
  const TemplateListView({super.key});

  Future<List<Map<String, dynamic>>> _fetchTemplates() async {
    return await DatabaseHelper.getAllTemplates();
  }

  @override
  Widget build(BuildContext context) {
    const String appTitle = 'Template List';
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
              // loading data
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              // case kalau error
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (snapshot.data != null && snapshot.data!.isEmpty) {
              // data tidak null, tetapi isinya kosong
              return const Center(child: Text("No templates available."));
            } else {
              // datanya ada
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var template = snapshot.data![index];
                  return Card(
                    margin: const EdgeInsets.all(15),
                    child: ListTile(
                      title: Text(
                        template['templateName'],
                        style: const TextStyle(fontSize: 20),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TemplateDetail(
                              templateId: template['templateId']),
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
