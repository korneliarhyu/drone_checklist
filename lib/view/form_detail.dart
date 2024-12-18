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
  Map<String, dynamic>? _formData;
  String? _formName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFormData(widget.formId);
  }

  void _saveForm() {
    // Handle form saving logic here
    print("Form saved!");
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

  // Future<void> _loadFormData(int formId) async {
  //   try {
  //     var form = await DatabaseHelper.getFormById(formId);
  //     //debug form data
  //     //print("Form data: $form");
  //
  //     if (form == null) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //       print("Form data not found!");
  //       return;
  //     }
  //
  //     var template = await DatabaseHelper.getTemplateById(form['templateId']);
  //
  //     if (template == null) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //       print("Template data not found!");
  //       return;
  //     }
  //
  //     //debug template data
  //     //print("Template data: ${template['templateFormData']}");
  //
  //     Map<String, dynamic> templateData =
  //         jsonDecode(template['templateFormData']);
  //     Map<String, dynamic> formData =
  //         form['formData'] != null ? jsonDecode(form['formData']) : {};
  //
  //     Map<String, dynamic> displayedForm = {};
  //     templateData['questions'].forEach((key, question) {
  //       displayedForm[key] = {
  //         ...question,
  //         'answer': formData[key] ?? '',
  //       };
  //     });
  //
  //     setState(() {
  //       // Decode the JSON stored in the formData column
  //       _formName = form['formName'];
  //       //debug merged form
  //       //print("Merged Form: $displayedForm");
  //       _formData = displayedForm;
  //       _isLoading = false;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //     print("Error loading form or template data: $e");
  //   }
  // }

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
                          ..._buildQuestions(_formData!),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _saveForm,
                            child: const Text('Save Changes'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  List<Widget> _buildQuestions(Map<String, dynamic> questions) {
    List<Widget> questionWidgets = [];
    print("Building questions from: $questions");

    questions.forEach((key, question) {
      // Asumsi semua pertanyaan adalah teks karena tidak ada data lain
      questionWidgets.add(ListTile(
        title: Text(key),
        subtitle: Text(question), // 'question' sebenarnya adalah jawaban
      ));
    });

    return questionWidgets;
  }

  // Existing methods for dropdown questions
  Widget _buildDropdownQuestion(String key, Map<String, dynamic> question) {
    return ListTile(
      title: Text(question['question'] ?? 'Question'),
      subtitle: DropdownButton<String>(
        value: question['answer'] != '' ? question['answer'] : null,
        items: (question['options'] as List<dynamic>?)
            ?.map<DropdownMenuItem<String>>((option) {
          return DropdownMenuItem<String>(
            value: option as String?,
            child: Text(option.toString()),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _formData![key]['answer'] = value;
          });
        },
        isExpanded: true,
      ),
    );
  }

  // Existing methods for checklist questions
  Widget _buildCheckboxQuestion(String key, Map<String, dynamic> question) {
    if (!(question['options'] is List)) {
      print("Error: Options for $key are not in list format: ${question['options']}");
      return Text("Error: invalid options format");
    }
    List<String> options = List<String>.from(question['options']);
    List<String> currentAnswers = List<String>.from(question['answer'] ?? []);

    return ListTile(
      title: Text(question['prompt'] ?? 'Question'),
      subtitle: Column(
        children: options.map((option) {
          return CheckboxListTile(
            title: Text(option),
            value: currentAnswers.contains(option),
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  if (!currentAnswers.contains(option)) {
                    currentAnswers.add(option);
                  }
                } else {
                  currentAnswers.remove(option);
                }
                _formData![key]['answer'] = currentAnswers;
              });
            },
            controlAffinity: ListTileControlAffinity.leading, // Lokasi checkbox
          );
        }).toList(),
      ),
    );
  }

  // Existing methods for multiple-choice questions
  Widget _buildMultipleChoiceQuestion(
      String key, Map<String, dynamic> question) {
    List<String> selectedOption = List<String>.from(question['answer'] ?? []);
    List<dynamic> options = question['options'] ?? [];

    return ListTile(
      title: Text(question['question'] ?? 'Question'),
      subtitle: Column(
        children: options.map<Widget>((option) {
          return CheckboxListTile(
            value: selectedOption.contains(option),
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  selectedOption.add(option as String);
                } else {
                  selectedOption.remove(option);
                }
                _formData![key]['answer'] = selectedOption;
              });
            },
            title: Text(option.toString()),
          );
        }).toList(),
      ),
    );
  }

  // Existing methods for text input questions
  Widget _buildTextQuestion(String key, Map<String, dynamic> question) {
    TextEditingController controller =
        TextEditingController(text: question['answer']?.toString() ?? '');
    return ListTile(
      title: Text(question['question'] ?? ''),
      subtitle: TextField(
        controller: controller,
        onChanged: (value) {
          _formData![key]['answer'] = value;
        },
        decoration: const InputDecoration(
          hintText: 'Enter your answer',
        ),
      ),
    );
  }
}
