import 'package:flutter/material.dart';
import 'checklist_form_create.dart'; 
import 'package:drone_flight_checklist/model/template_question.dart'; 

class ChecklistFormView extends StatefulWidget {
  final Questions templateQuestions; // Add templateQuestions as a field

  const ChecklistFormView({super.key, required this.templateQuestions}); // Require the field

  @override
  _ChecklistFormViewState createState() => _ChecklistFormViewState();
}

class _ChecklistFormViewState extends State<ChecklistFormView> {
  final List<String> _formList = [];

  final bool _isLoading = false;

  void _addForm(String formName) {
    print('Adding form: $formName'); // Debugging
    setState(() {
      _formList.add(formName);
    });
  }

  void _navigateToCreateForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateForm(templateQuestions: widget.templateQuestions),
      ),
    );
    print('Result from CreateForm: $result'); // Debugging
    if (result != null && result is String) {
      _addForm(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checklist Form View')),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateForm, // Correctly navigating
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _formList.isEmpty
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
                              print('Edit pressed for: ${_formList[index]}');
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

void main() {
  // Create a sample templateQuestions instance
  Questions sampleQuestions = Questions(
    questions: {
      "question1": Question(
        question: "Sample Text Question",
        type: "text",
        option: [],
        required: true,
      ),
      // Add more sample questions as needed
    },
  );

  runApp(MaterialApp(
    home: ChecklistFormView(templateQuestions: sampleQuestions),
  ));
}
