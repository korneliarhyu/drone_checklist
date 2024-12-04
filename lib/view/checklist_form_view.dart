import 'package:drone_checklist/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:drone_checklist/view/checklist_form_create.dart';
import 'package:drone_checklist/model/template_question.dart';
import 'package:drone_checklist/view/template_list_view.dart';
import 'package:drone_checklist/view/select_template.dart';

int currTemplate = 1;

class ChecklistFormView extends StatefulWidget {
  //const ButtonSection({super.key});

  //final Questions templateQuestions;

  //parameter yang di main itu di set disini
  // const ChecklistFormView({
  //   super.key, required this.templateQuestions
  // });

  @override
  _ChecklistFormViewState createState() => _ChecklistFormViewState();
}

class _ChecklistFormViewState extends State<ChecklistFormView> {
  List<Map<String, dynamic>> _formList = [];

  void _callData() async {
    var listData = await DatabaseHelper.getAllChecklist();

    _formList = listData.map((element){
      return{
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

  void _navigateToTemplatesList() async{
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => TemplateListView(),
        ),
    );
  }

  void _insertDummyTemplate() async {
    try {
      // variable templateId akan menyimpan templateId dari dummy.
      int templateId = await DatabaseHelper.insertDummyTemplate();
      print('Template successfully inserted with ID: $templateId');
    } catch (e) {
      print('Error inserting template: $e');
    }
  }

  void _sync() async {
    List<int> selectedForms = _formList
        .where((form) => form['isChecked'] == true)
        .map((form) => form['formId'] as int)
        .toList();

    //debug ambil id yang dipilih
    print("Syncing ID(s): $selectedForms");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checklist Form View')),
      floatingActionButton: Stack(
        children: [
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
              heroTag: "insertTemp",
              onPressed: _insertDummyTemplate,
              child: const Icon(Icons.access_time_sharp),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 209,
            child: FloatingActionButton(
              heroTag: "sync",
              onPressed: _sync,
              child: const Icon(Icons.cloud_upload),
            ),
          ),
        ]
      ),


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
                  title: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      _formList[index]['formName'],
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          // edit()
                        },
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.indigo,
                        ),
                      ),

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
                          onChanged: (bool? value){
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
