import 'package:drone_checklist/database/database_helper.dart';
import 'package:drone_checklist/view/form_fill.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:drone_checklist/view/template_view.dart';
import 'package:drone_checklist/view/template_downloaded.dart';
import 'package:drone_checklist/services/api_service.dart';

class FormView extends StatefulWidget {
  const FormView({super.key});

  @override
  _FormViewState createState() => _FormViewState();
}

class _FormViewState extends State<FormView> {
  List<Map<String, dynamic>> _formList = [];

  // bool selectedForm = false;
  int? selectedFormIndex;

  // bool confirm = false;

  void _callData() async {
    var listData = await DatabaseHelper.getAllForms();

    _formList = listData.map((element) {
      return {
        'formId': element['formId'],
        'formName': element['formName'],
        'isChecked': false,
        'syncStatus': element['syncStatus'],
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
        builder: (context) => const TemplateDownloaded(),
      ),
    );
    _callData();
  }

  void _navigateToTemplatesList() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TemplateView(),
      ),
    );
  }

  void _sync() async {
    int? selectedForm = selectedFormIndex;

    //debug ambil id yang dipilih
    print("Syncing ID(s): $selectedForm");

    // Check apakah ada form yang dipilih
    if (selectedForm == null) {
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
    } else {
      bool confirm = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirm Sync"),
              content:
                  const Text("Are you sure you want to sync selected form?"),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("No"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Yes"),
                ),
              ],
            );
          });

      if (confirm) {
        try {
          var getForm = await DatabaseHelper.getFormById(selectedForm);
          if (getForm == null) {
            print("Valid form data not found or missing templateId for: $selectedForm");
            return;
          }

          var dio = Dio();

          dio.interceptors.add(LogInterceptor(
            requestHeader: true,
            requestBody: true,
            responseBody: true,
            responseHeader: true,
          ));

          var apiService = ApiService(dio);

          FormData sync = FormData.fromMap({
            "submissionName": getForm['formName'].toString(),
            "templateId": getForm['serverTemplateId'].toString(),
            "submittedBy": "User",
            "submittedDate":DateTime.now().toString(),
            "formData": getForm['formData'].toString(),
          });

          final response = await dio.post(
            "http://103.102.152.249/webdrone/class/database/syncData.php",
            data: sync
          );

          print("response result : $response");

          //update syncStatus in DB
          await DatabaseHelper.updateSyncStatus(selectedForm, 1);

          //update UI
          setState(() {
            _formList.firstWhere((form) => form['formId'] == selectedForm)['syncStatus'] =1;
            selectedFormIndex = null;
          });

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
      body: Padding(
        padding: const EdgeInsets.only(bottom: 85),
        child: _formList.isEmpty
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
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 8,
                    backgroundColor: _formList[index]['syncStatus'] == 1
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.description, color: Colors.blue),
                ],
              ),
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
                  builder: (context) => FormFill(
                    formId: _formList[index]['formId'], // Pass the selected form ID
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
                    // karena _formList adalah growableList, jadi kita akan akses listnya dulu untuk dapetin form ke berapa yang kita pilih(berdasarkan indexnya).
                    // kemudian kita akses ['formId']nya (formId ini yang kita butuhkan untuk proses syncData).
                    value: selectedFormIndex == _formList[index]['formId'],
                    onChanged: _formList[index]['syncStatus'] == 1
                        ? null //disabling checkbox for synced forms
                        : (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedFormIndex = _formList[index]['formId']; // Pilih form ini
                            } else {
                              selectedFormIndex = null;
                            }
                          });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      )
    );
  }
}
