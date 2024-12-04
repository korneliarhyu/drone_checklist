import 'package:drone_checklist/database/database_helper.dart';
import 'package:drone_checklist/view/template_detail.dart';
import 'package:flutter/material.dart';

class TemplateListView extends StatelessWidget {
  const TemplateListView({super.key});

  Future<List<Map<String, dynamic>>> _fetchTemplates() async {
    return await DatabaseHelper.getAllDummyTemplates();
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
          // fetch seluruh template (getAllTemplates)
          future: _fetchTemplates(),
          builder: (context, snapshot) {
            // snapshot digunakan untuk mengecek kondisi secara async (data akan bekerja di background)

            if (snapshot.connectionState == ConnectionState.waiting) {
              // loading data = anggaplah template masih otw di kurir.
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              // case kalau error = template hilang
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (snapshot.data != null && snapshot.data!.isEmpty) {
              // data tidak null, tetapi isinya kosong = templatenya ada, tapi datanya kosong.
              return const Center(child: Text("No templates available."));
            } else {
              // tempaltenya ada dan sampai ke aplikasi. kemudian unboxing untuk lihat data di dalamnya.
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var dummy_template = snapshot.data![index];
                  return Card(
                    margin: const EdgeInsets.all(15),
                    child: ListTile(
                      title: Text(
                        dummy_template['templateName'],
                        style: const TextStyle(fontSize: 20),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TemplateDetail(
                              dummyTemplateId: dummy_template['templateId']),
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
