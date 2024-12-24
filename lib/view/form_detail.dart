import 'dart:convert';
import 'package:drone_checklist/database/database_helper.dart';
import 'package:flutter/material.dart';

class FormDetail extends StatefulWidget {
  final int formId;

  const FormDetail({Key? key, required this.formId}) : super(key: key);

  @override
  _FormDetailState createState() => _FormDetailState();
}

class _FormDetailState extends State<FormDetail> {
  Map<String, TextEditingController> _questionControllers = {};
  Map<String, List<String>> _selectedOptions = {};

  List<Map<String, dynamic>>? _formData;
  String? _formName;
  bool _isLoading = true;

  @override
  void dispose() {
    // Dispose all controllers
    _questionControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadFormData(widget.formId);
  }

  void _saveForm(formData, isChecked) {
    // Handle form saving logic here

    // loop data untuk mengecek 1-1 typenya mana yang dichecklist atau engga(untuk ngecek type yang mana yang isChecked).
    // iterasi -> looping -> ngebaca datanya 1-1. dan akan kembali ke atas sampai seluruh data terbaca.
    //loop ini akan mengecek satu-satu mulai dari pre, jika pre isChecked, maka akan masuk ke dalam if.
    for (var section in ['assessment', 'pre', 'post']) {
      if (formData[section] != null) {
        formData[section].forEach((questionId, questionData){
          if(questionData['type'] == 'checklist' && isChecked){
            print("Question '$questionId' is checked: Updating flightNum");
            questionData['flightNum'] = ''; //cara set flightNum biar increment?
          } else{
            print("Updating question '$questionId'");
          }

          if(_questionControllers.containsKey(questionId)){
            questionData['answer'] = _questionControllers[questionId]?.text;
          }
        });

      } else {
        // update biasa

      }
    }

    try{
      String encodeForm = jsonEncode(formData);
      DatabaseHelper.updateForm(
        widget.formId,
        encodeForm,
      );
    } catch (e, stackTrace) {
      print("Error saving form: $e");
      print("StackTrace: $stackTrace");
    }



    print("Form saved! $formData");
  }

  Future<void> _loadFormData(int formId) async {
    try {
      var form = await DatabaseHelper.getFormById(formId);
      if (form == null) {
        setState(() => _isLoading = false);
        print("Form data not found!: $formId");
        return;
      }

      print("Form data retrieved: $form");

      // Decode the formData and ensure it's properly cast as List<Map<String, dynamic>>
      List<Map<String, dynamic>>? formData = form['formData'] != null
          ? List<Map<String, dynamic>>.from(jsonDecode(form['formData']))
          : [];

      print("Decoded form data: $formData");
      setState(() {
        _formName = form['formName'];
        _formData = formData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error loading form data: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Form Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _formData == null
          ? const Center(child: Text('No form data available'))
          : Builder(
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Text(
                  _formName ?? 'Untitled Form',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ..._buildFormFields(),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: (){
                    _saveForm(_formData, false);
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildFormFields() {
    List<Widget> fields = [];
    if (_formData != null) {
      // define order sections
      List<String> sectionOrder = ['assessment', 'pre', 'post'];

      for (var section in _formData!) {
        fields.add(Text(
          section['type'].toString().toUpperCase(),
          style: Theme.of(context).textTheme.headlineLarge,
        ));
        if (section['type'] == 'assessment') {
          for (var answer in section['answer']) {
            String questionId = answer['questionName'];
            TextEditingController controller = _questionControllers.putIfAbsent(
                questionId, () => TextEditingController(text: answer['answer'])
            );
            fields.add(_buildQuestionField(answer, questionId, controller));
          }
        } else {
          for (var answerInfo in section['answer']) {
            for (var data in answerInfo['data']) {
              String questionId = data['questionName'];
              TextEditingController controller = _questionControllers.putIfAbsent(
                  questionId, () => TextEditingController(text: data['answer'])
              );
              fields.add(_buildQuestionField(data, questionId, controller));
            }
          }
        }
      }
    }
    return fields;
  }


  Widget _buildQuestionField(Map<String, dynamic> question, String questionId, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question['questionName']),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(labelText: 'Answer'),
            onChanged: (value) {
              // Update the state or perform other operations when the text changes
            },
          ),
          // You can add other widgets based on 'question' details, such as Dropdown, Checkbox, etc.
        ],
      ),
    );
  }
}