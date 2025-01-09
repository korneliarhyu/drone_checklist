import 'dart:convert';
import 'package:drone_checklist/helper/utils.dart';
import 'package:flutter/material.dart';
import 'package:drone_checklist/model/form_model.dart';
import 'package:drone_checklist/Database/database_helper.dart';

class FormCreate extends StatefulWidget {
  final int templateId;

  const FormCreate({
    Key? key,
    required this.templateId,
  }) : super(key: key);

  @override
  _FormCreateState createState() => _FormCreateState();
}

class _FormCreateState extends State<FormCreate> {
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
  Map<String, String> _questionType = {};
  Map<String, List<String>> _questionOptions = {};

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
          _questionType[uniqueQuestionId] = questionData['type'];
          _questionOptions[uniqueQuestionId] =
              List<String>.from(questionData['option'] ?? []);
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
      ..._checkboxValues.map((key, value) => MapEntry(key, value.join(', '))),
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
      String? questionType = _questionType["$section-$questionId"];

      var answerEntry = {
        "questionName": questionName,
        "answer": value,
        "option": _questionOptions["$section-$questionId"] ?? [],
        "qType": questionType,
        "dataChanged":
            DateTime.now().toString().split('.').first.replaceAll('-', '/')
      };
      sectionData[section]?.add(answerEntry);
    });

    ['pre', 'post'].forEach((section) {
      if (sectionData.containsKey(section)) {
        Map<int, List<Map<String, dynamic>>> flightData = {};
        sectionData[section]?.forEach((entry) {
          int flightNum = 1;
          flightData.putIfAbsent(flightNum, () => []).add(entry);
        });

        structuredData.add({
          "type": section, // ambil tipe question
          "answer": flightData.entries
              .map((e) => {"flightNum": e.key, "data": e.value})
              .toList() // ambil jawaban dari setiap pertanyaan untuk disimpan di tipe JSON
        });
      }
    });

    if (sectionData.containsKey('assessment')) {
      structuredData
          .add({"type": "assessment", "answer": sectionData['assessment']});
    }

    final formModel = FormModel(
      formId: null,
      templateId: widget.templateId,
      serverTemplateId: _templateData?['serverTemplateId'],
      formName: _templateData?['templateName'],
      updatedDate: DateTime.now(),
      formData: structuredData,
      updatedFormData: structuredData,
    );

    try {
      await DatabaseHelper.createForm(formModel);
    } catch (e) {
      showAlert(context, "Form Not Saved!", "Failed save the form!!",
          AlertType.failed);
    }
    print(jsonEncode(formModel.formData));
  }

  List<Widget> _buildFormFields() {
    List<Widget> fields = [];

    if (_formData != null) {
      ['assessment', 'pre', 'post'].forEach((section) {
        fields.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),

          //styling
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              // Memunculkan judul per-section
              section.toUpperCase(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold
              ),
            ),
          )

        ));
        if (_formData[section] != null) {
          _formData[section].forEach((questionId, questionData) {
            // memberikan unique Key ke masing-masing question di setiap section
            // section = assessment, pre, post.
            String uniqueQuestionId = '$section-$questionId';

            // Text Editing Controller ini bikin nilai text ngga hilang saat click field lainnya.
            TextEditingController? controller =
                _questionControllers[uniqueQuestionId];
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
              onChanged: (value) {
                setState(() {
                  _textboxValues[uniqueQuestionId] = value;
                });
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
              padding: const EdgeInsets.all(16.0),
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
