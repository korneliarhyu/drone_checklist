import 'dart:convert';
import 'package:drone_checklist/helper/utils.dart';
import 'package:flutter/material.dart';
import 'package:drone_checklist/model/form_model.dart';
import 'package:drone_checklist/Database/database_helper.dart';
import 'form_view.dart';

class CreateForm extends StatefulWidget {
  final int templateId;

  const CreateForm({
    Key? key,
    required this.templateId,
  }) : super(key: key);

  @override
  _CreateFormState createState() => _CreateFormState();
}

class _CreateFormState extends State<CreateForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _questionControllers = {};
  final Map<String, String> _dropdownValues = {};
  final Map<String, String> _multipleValues = {};
  final Map<String, String> _textboxValues = {};
  final Map<String, Set<String>> _checkboxValues = {};

  // Membuat dua variable kosong bertype Map _templateData dan _formData untuk menghindari error non-nullable.
  Map<String, dynamic>? _templateData = {};
  Map<String, dynamic> _formData = {};
  Map<String, String> _questionName = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getTemplate(widget.templateId);
  }

  Future<void> _getTemplate(int templateId) async {
    try {
      final response = await DatabaseHelper.getTemplateById(templateId);

      // Decode: convert dari String ke JSON
      final Map<String, dynamic> data =
          jsonDecode(response['templateFormData']);
      _initFormData(data);

      print("Fetched Template: $response");
      print("Fetched Form: $data");

      setState(() {
        _formData = data;
        _templateData = response;
        _isLoading = false;
      });
    } catch (e) {
      print("Error Fetching Template: $e");
      setState(() {
        _isLoading = false;
        _templateData = {};
        _formData = {};
      });
    }
  }

  void _initFormData(Map<String, dynamic> data) {
    ['assessment', 'pre', 'post'].forEach((section) {
      if (data[section] != null) {
        data[section].forEach((questionId, questionData) {
          String uniqueQuestionId = '$section-$questionId';
          if (!_questionControllers.containsKey(uniqueQuestionId)) {
            _questionControllers[uniqueQuestionId] = TextEditingController();
          }
          _questionName[uniqueQuestionId] = questionData['question'];
        });
      }
    });
  }

  void _saveForm() async {
    List<Map<String, dynamic>> structuredData = [];

    Map<String, List<Map<String, dynamic>>> sectionData = {};
    Map<String, dynamic> allAnswers = {
      ..._textboxValues,
      ..._multipleValues,
      ..._dropdownValues,
      ..._checkboxValues
          .map((key, value) => MapEntry(key, jsonEncode(value.toList()))),
    }; // Mapping seluruh jawaban di satu value untuk mempermudah ambil data.

    // indexing seluruh jawaban dan pertanyaan buat struktur si json
    allAnswers.forEach((key, value) {
      var parts = key.split('-');
      var section = parts[0];
      var questionId = parts[1];

      //safety check untuk cek initialisasi
      sectionData.putIfAbsent(section, () => []);

      String? questionName =
          _questionName["$section-$questionId"]; //ambil nama question

      var answerEntry = {
        "questionName": questionName,
        "answer": value,
        "dataChanged": DateTime.now().toString()
      };
      sectionData[section]?.add(answerEntry);
    });

    sectionData.forEach((section, answer) {
      structuredData.add({
        "type": section, // ambil tipe question
        "answer":
            answer // ambil jawaban dari setiap pertanyaan untuk disimpan di tipe JSON
      });
    });

    final formModel = FormModel(
      formId: null,
      templateId: widget.templateId,
      formName: _templateData?['templateName'],
      updatedDate: DateTime.now(),
      formData: structuredData,
    );

    try {
      await DatabaseHelper.createForm(formModel);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => FormCreate()),
      );
    } catch (e) {
      print("Error save: $e");
    }
    print(jsonEncode(formModel.formData));
  }

  List<Widget> _buildFormFields() {
    List<Widget> fields = [];

    if (_formData != null) {
      ['assessment', 'pre', 'post'].forEach((section) {
        fields.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          // Memunculkan judul per-section
          child: Text(section.toUpperCase(),
              style: Theme.of(context).textTheme.headlineSmall),
        ));
        if (_formData[section] != null) {
          _formData[section].forEach((questionId, questionData) {
            // memberikan unique Key ke masing-masing question di setiap section
            // section = assessment, pre, post.
            String uniqueQuestionId = '$section-$questionId';
            TextEditingController controller = TextEditingController();
            if (controller != null) {
              fields.add(_buildQuestionField(
                  uniqueQuestionId, questionData, controller));
            }
          });
        }
      });
    }
    return fields;
  }

  Widget _buildQuestionField(String uniqueQuestionId,
      Map<String, dynamic> question, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question['question']),
          if (question['type'] == 'text' || question['type'] == 'longtext')
            TextFormField(
              controller: controller,
              decoration: InputDecoration(labelText: "Answer"),
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
                value: _checkboxValues[uniqueQuestionId]?.contains(option) ??
                    false,
                onChanged: (bool? isSelected) {
                  setState(() {
                    // perbarui dengan nilai baru
                    if (isSelected ?? false) {
                      if (!_checkboxValues.containsKey(uniqueQuestionId)) {
                        _checkboxValues[uniqueQuestionId] = {option};
                      } else {
                        _checkboxValues[uniqueQuestionId]?.add(option);
                      }
                    } else {
                      _checkboxValues[uniqueQuestionId]?.remove(option);
                    }
                  });
                },
              );
            }).toList(),
          if (question['type'] == 'dropdown')
            DropdownButtonFormField<String>(
              value: _dropdownValues[uniqueQuestionId],
              onChanged: (String? newValue) {
                setState(() {
                  _dropdownValues[uniqueQuestionId] = newValue ?? "";
                });
              },
              items: question['option'].map<DropdownMenuItem<String>>((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              decoration: InputDecoration(labelText: 'Select one'),
            ),
          if (question['type'] == 'multiple')
            ...question['option'].map<Widget>((option) {
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: _multipleValues[uniqueQuestionId],
                onChanged: (String? value) {
                  setState(() {
                    _multipleValues[uniqueQuestionId] = value ?? "";
                  });
                },
              );
            }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_templateData?['templateName']}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: _buildFormFields() +
                      [
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              showAlert(context, "Success",
                                  "Success submit form!", AlertType.success);

                              _saveForm();
                            }
                          },
                          child: const Text('Submit Form'),
                        )
                      ],
                ),
              ),
            ),
    );
  }
}
