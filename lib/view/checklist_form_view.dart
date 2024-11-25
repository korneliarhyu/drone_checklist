import 'package:drone_checklist/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:drone_checklist/view/checklist_form_create.dart';
import 'package:drone_checklist/model/template_question.dart';
import 'package:drone_checklist/view/template_list_view.dart';

class ChecklistFormView extends StatefulWidget {
  //const ButtonSection({super.key});
  final Questions templateQuestions;

  const ChecklistFormView({
    super.key, required this.templateQuestions
  });

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
      };
    }).toList();
    print("Fetched data: $_formList");

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
        builder: (context) =>
            CreateForm(templateQuestions: widget.templateQuestions),
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
            onPressed: _navigateToCreateForm,
            child: const Icon(Icons.add),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 80,
            child: FloatingActionButton(
            onPressed: _navigateToTemplatesList,
            child: const Icon(Icons.list),
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
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
