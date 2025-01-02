import 'package:drone_checklist/database/database_helper.dart';
import 'package:drone_checklist/helper/utils.dart';
import 'package:drone_checklist/view/form_detail.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:drone_checklist/view/template_view.dart';
import 'package:drone_checklist/view/template_select.dart';
import 'package:drone_checklist/services/api_service.dart';

int currTemplate = 1;

class FormView extends StatefulWidget {
  @override
  _FormViewState createState() => _FormViewState();
}

class _FormViewState extends State<FormView> {
  List<Map<String, dynamic>> _formList = [];

  void _callData() async {
    var listData = await DatabaseHelper.getAllForms();

    _formList = listData.map((element) {
      return {
        'formId': element['formId'],
        'formName': element['formName'],
        'isChecked': false,
      };
    }).toList();

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
    var dio = Dio();
    var apiService = ApiService(dio);

    List<int> selectedForms = _formList
        .where((form) => form['isChecked'] == true)
        .map((form) => form['formId'] as int)
        .toList();

    //debug ambil id yang dipilih
    print("Syncing ID(s): $selectedForms");

    // Check apakah ada form yang dipilih
    if (selectedForms.isEmpty) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("No Form Selected"),
              content: const Text("Please select at least one form to sync."),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          });
      return;
    }

    bool confirm = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Confirm Sync"),
            content:
                const Text("Are you sure you want to sync selected forms?"),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Yes"),
              ),
            ],
          );
        });

    if (confirm) {
      try {
        var response =
            await apiService.syncData({'selectedFormIds': selectedForms});
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Sync Successful'),
              content: Text('Sync response: ${response.toString()}'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } catch (e) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Sync Failed'),
              content: Text('Error: $e'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } else {
      // Jika user memilih "No"
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Sync Cancelled'),
            content: const Text('Sync process was cancelled.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('List Form')),
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
                  leading: const Icon(Icons.description, color: Colors.blue),
                  title: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      _formList[index]['formName'],
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
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
