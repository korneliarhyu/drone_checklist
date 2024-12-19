import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drone_checklist/database/database_helper.dart';
import 'package:drone_checklist/services/api_service.dart';
import 'package:drone_checklist/view/form_detail.dart';
import 'package:flutter/material.dart';
import 'package:drone_checklist/view/template_view.dart';
import 'package:drone_checklist/view/template_select.dart';

int currTemplate = 1;

class FormCreate extends StatefulWidget {
  //parameter yang di main itu di set disini
  // const ChecklistFormView({
  //   super.key, required this.templateQuestions
  // });

  @override
  _FormCreateState createState() => _FormCreateState();
}

class _FormCreateState extends State<FormCreate> {
  List<Map<String, dynamic>> _formList = [];

  void _callData() async {
    var listData = await DatabaseHelper.getAllChecklist();

    _formList = listData.map((element) {
      return {
        'formId': element['formId'],
        'formName': element['formName'],
        'isChecked': false,
      };
    }).toList();
    //debug fetching data from database
    //print("Fetched data: $_formList");

    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    _callData();
    super.initState();
  }

  void _navigateToCreateForm() async {
    // final api_service = new ApiService();
    // api_service.getQuestions();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectForm(),
        // CreateForm(
        //     //templateQuestions: widget.templateQuestions,
        //     templateId: currTemplate),
      ),
    );
    _callData();
  }

  void _navigateToTemplatesList() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateView(),
      ),
    );
  }

  void _sync() async {
    List<int> selectedForms = _formList
        .where((form) => form['isChecked'] == true)
        .map((form) => form['formId'] as int)
        .toList();

    //debug ambil id yang dipilih
    print("Syncing ID(s): $selectedForms");
    
    if(selectedForms.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No forms selected to sync!')),
      );
      return;
    }
    
    try{
      List<Map<String, dynamic>?> formToSync = await Future.wait(
        selectedForms.map((formId) => DatabaseHelper.getFormById(formId)),
      );

      List<Map<String, dynamic>?> syncData = formToSync.map((form){
        return {
          "submissionName": form?['formName'],
          "templateId": form?['templateId'],
          "submittedBy": "User", //hardcode dulu ya
          "submittedDate": DateTime.now().toIso8601String(),
        "formData": form?['formData'],
        };
      }).toList();

      //panggil apiapi
      final dio = Dio();
      final apiService = ApiService(dio);

      List<Map<String, dynamic>> newSyncData = syncData.where((map) => map != null).cast<Map<String, dynamic>>().toList();

      //sync process
      for(var data in newSyncData){
        print(const JsonEncoder.withIndent('  ').convert(data));
        final response = await apiService.syncData(data);
        print("Sync Succesful: $response");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Syncing Succesful!')),
      );
    } catch (e){
      print("Sync Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync Error: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checklist Form View')),
      floatingActionButton: Stack(children: [
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: "createForm",
            onPressed: _navigateToCreateForm,
            child: const Icon(Icons.add),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 80,
          child: FloatingActionButton(
            heroTag: "templateList",
            onPressed: _navigateToTemplatesList,
            child: const Icon(Icons.list),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 145,
          child: FloatingActionButton(
            heroTag: "sync",
            onPressed: _sync,
            child: const Icon(Icons.cloud_upload),
          ),
        ),
      ]),
      body: _formList.isEmpty
          ? const Center(
              child: Text(
                "No Form Available Yet :(",
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: _formList.length,
              itemBuilder: (context, index) => Card(
                margin: const EdgeInsets.all(15),
                child: ListTile(
                  leading:const Icon(Icons.description, color: Colors.blue),
                  title: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      _formList[index]['formName'],
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FormDetail(
                        formId: _formList[index]
                            ['formId'], // Pass the selected form ID
                      ),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () async {
                          int formId = _formList[index]['formId'];
                          await DatabaseHelper.deleteForm(formId);
                          setState(() {
                            _formList.removeAt(index);
                          });
                        },
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.redAccent,
                        ),
                      ),
                      Checkbox(
                        value: _formList[index]['isChecked'] ?? false,
                        onChanged: (bool? value) {
                          setState(() {
                            _formList[index]['isChecked'] = value ?? false;
                          });
                          //debug changestate
                          // print('Checkbox formId: ${_formList[index]['formId']} set to $value');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
