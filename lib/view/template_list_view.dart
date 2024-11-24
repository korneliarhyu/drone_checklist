import 'package:flutter/material.dart';

class TemplateListView extends StatelessWidget {
  const TemplateListView({super.key});

  @override
  Widget build(BuildContext context) {

    const String appTitle = 'Flutter layout demo';
    return MaterialApp(
      title: appTitle,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(appTitle),
          leading: IconButton(
              onPressed: (){
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back))
        ),
        body:
        // _templateList.isEmpty
        //     ? const Center(
        //   child: Text(
        //     "No Form Available Yet :(",
        //     style: TextStyle(fontSize: 18),
        //   ),
        // ):
        ListView.builder(
          itemCount: 2,
          itemBuilder: (context, index) => Card(
            margin: const EdgeInsets.all(15),
            child: ListTile(
              title: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  "template 1",
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              trailing: const Row(
                mainAxisSize: MainAxisSize.min
              ),
            ),
          ),
        ),
      ),
    );
  }
}