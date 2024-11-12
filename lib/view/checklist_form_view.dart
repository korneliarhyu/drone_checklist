import 'package:flutter/material.dart';
import 'checklist_form_create.dart'; 

class ChecklistFormView extends StatefulWidget {
  @override
  _ChecklistFormViewState createState() => _ChecklistFormViewState();
}

class _ChecklistFormViewState extends State<ChecklistFormView> {
  List<String> _formList = [];

  bool _isLoading = false;

  void _addForm(String formName) {
    print('Adding form: $formName'); // Debugging
    setState(() {
      _formList.add(formName);
    });
  }

  void _navigateToCreateForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateForm()),
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

void main() => runApp(MaterialApp(
  home: ChecklistFormView(),
));
