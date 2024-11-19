import 'package:drone_flight_checklist/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:drone_flight_checklist/view/checklist_form_create.dart';
import 'package:drone_flight_checklist/model/template_question.dart';

class ChecklistFormView extends StatefulWidget {
  final Questions templateQuestions; // Questions is assumed to be a Map<String, Question> type

  const ChecklistFormView({super.key, required this.templateQuestions});

  @override
  _ChecklistFormViewState createState() => _ChecklistFormViewState();
}

class _ChecklistFormViewState extends State<ChecklistFormView> {
  final List<String> _formList = [];

  void _addForm(String formName) {
    setState(() {
      _formList.add(formName);
    });
  }

  void _navigateToCreateForm() async {
    // final api_service = new ApiService();
    // api_service.getQuestions();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateForm(templateQuestions: widget.templateQuestions),
      ),
    );
    if (result != null && result is String) {
      _addForm(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checklist Form View')),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateForm,
        child: const Icon(Icons.add),
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
                      _formList[index],
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          // Add edit logic here
                        },
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.indigo,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
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
