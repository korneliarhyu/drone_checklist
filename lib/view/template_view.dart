import 'package:drone_checklist/database/database_helper.dart';
import 'package:drone_checklist/view/template_detail.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:drone_checklist/model/json_model.dart';
import 'package:drone_checklist/services/api_service.dart';

class TemplateListView extends StatelessWidget {
  const TemplateListView({super.key});

  Future<List<Template>> _fetchTemplates() async {
    final dio = Dio();
    final client = ApiService(dio);
    return await client.getAllTemplate();
  }

  // masih pakai database
  // Future<List<Map<String, dynamic>>> _fetchTemplates() async {
  //   return await DatabaseHelper.getAllDummyTemplates();
  // }

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
        body: FutureBuilder<List<Template>>(
          future: _fetchTemplates(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (snapshot.hasData) {
              if (snapshot.data!.isEmpty) {
                return const Center(child: Text("No templates available."));
              }
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var template = snapshot.data![index];
                  return Card(
                    margin: const EdgeInsets.all(15),
                    child: ListTile(
                      title: Text(template.templateName,
                          style: const TextStyle(fontSize: 20)),
                      onTap: () {
                        // Handle navigation or further actions
                      },
                    ),
                  );
                },
              );
            } else {
              return const Center(child: Text("No data available"));
            }
          },
        ),
      ),
    );
  }
}
