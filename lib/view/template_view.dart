import 'dart:convert';
import 'package:drone_checklist/view/template_detail.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:drone_checklist/model/json_model.dart';
import 'package:drone_checklist/services/api_service.dart';

class TemplateView extends StatelessWidget {
  const TemplateView({super.key});

  // pakai API
  Future<List<Template>> _getAllTemplate() async {
    try {
      final dio = Dio();
      final client = ApiService(dio);

      String responseData = await client.getAllTemplate();

      if (responseData.isNotEmpty) {
        var jsonData = jsonDecode(responseData);
        List<Template> templates =
            List.from(jsonData.map((model) => Template.fromJson(model)));
        return templates;
      } else {
        throw Exception("No data received from the server");
      }
    } catch (e, s) {
      print("Error fetching templates: $e");
      print("stacktrace: $s");
      rethrow;
    }
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
        //Menggunakan API gunakan List<Template>
        body: FutureBuilder<List<Template>>(
          future: _getAllTemplate(),
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
                      // menggunakan Database
                      //title: Text(template['templateName'],

                      // menggunakan API
                      title: Text(template.templateName,
                          style: const TextStyle(fontSize: 20)),
                      onTap: () {
                        // onTap hanya bisa menggunakan database / belum ada API nya
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TemplateDetail(
                                      templateId: template.id,
                                      //templateData: template.templateData
                                    )));
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
