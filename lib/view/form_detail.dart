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

  Map<String, dynamic>? _formData;
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
          encodeForm
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form saved succesfully!')),
      );
    } catch (e){
      print("Error saving form: $e");
      ScaffoldMessenger.of((context).showSnackBar(
        SnackBar(content: (content: Text('Error saving form: $e')),
        );
      ))
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

      var formData =
          form['formData'] != null ? jsonDecode(form['formData']) : {};
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
      ['assessment', 'pre', 'post'].forEach((section) {
        if (_formData![section] != null) {
          _formData![section].forEach((questionId, questionData) {
            TextEditingController controller = TextEditingController();
            _questionControllers[questionId] = controller;
            fields.add(_buildQuestionField(questionData, questionId, controller));
          });
        }
      });
    }
    return fields;
  }

  Widget _buildQuestionField(Map<String, dynamic> question, String questionId, TextEditingController controller) {
    var controller = _questionControllers.putIfAbsent(questionId, () => TextEditingController());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question['question']),
          if (question['type'] == 'text' || question['type'] == 'longtext')
            TextFormField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Answer'),
              validator: (value) {
                if (question['required'] && (value == null || value.isEmpty)) {
                  return 'This field cannot be empty';
                }
                return null;
              },
            ),
          if (question['type'] == 'checklist')
            ...question['option'].map<Widget>((option) {
              return CheckboxListTile(
                title: Text(option),
                value: false,
                onChanged: (bool? value) {},
              );
            }).toList(),
          if (question['type'] == 'dropdown')
            DropdownButtonFormField<String>(
              value: null,
              items: question['option'].map<DropdownMenuItem<String>>((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {},
              decoration: InputDecoration(labelText: 'Select one'),
            ),
          if (question['type'] == 'multiple')
            ...question['option'].map<Widget>((option) {
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: controller.text,
                onChanged: (String? value) {
                  setState(() {
                    controller.text = value!;
                  });
                },
              );
            }).toList(),
        ],
      ),
    );
  }
}
