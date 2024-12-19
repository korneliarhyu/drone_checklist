import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:drone_checklist/model/checklist_form_model.dart';
import 'package:drone_checklist/Database/database_helper.dart';
import 'checklist_form_view.dart';

class FormDetail extends StatefulWidget {
  final int formId;
  final String formName;
  final int templateId;

  const FormDetail({
    Key? key,
    required this.formId,
    required this.formName,
    required this.templateId,
  }) : super(key: key);

  @override
  _FormDetailState createState() => _FormDetailState();
}

class _FormDetailState extends State<FormDetail> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _questionControllers = {};
  final Map<String, String> _dropdownValues = {};
  final Map<String, String> _multipleValues = {};
  final Map<String, String> _textboxValues = {};

  Map<String, dynamic>? _formData;
  Map<String, dynamic>? _templateData;

  String? _formName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFormData(widget.formId);
  }

  void _updateForm() {
    if(_formKey.currentState?.validate() ?? false){
      Map<String, dynamic> formData = {};
      Map<String, dynamic> templateData = {};

      _questionControllers.forEach((key, controller){
        formData[key] = _questionControllers.values;
      });

      formData.addAll(_textboxValues);
      formData.addAll(_multipleValues);
      formData.addAll(_dropdownValues);

      final formModel = ChecklistFormModel(
        formId: widget.formId, //take the chosen formId
        templateId: widget.templateId, //take the form's templateId
        formName: widget.formName, //take the form's name
        formData: formData, //the form's data
        templateData: templateData, // get the template's data
        updatedDate: DateTime.now(), //the template's data
      )
    }
    print("Form saved!");
  }

  Future<void> _loadFormData(int formId) async {
    try {
      var form = await DatabaseHelper.getFormById(formId);
      //debug form data
      //print("Form data: $form");

      if (form == null) {
        setState(() {
          _isLoading = false;
        });
        print("Form data not found!");
        return;
      }

      var template = await DatabaseHelper.getTemplateById(form['templateId']);

      if (template == null) {
        setState(() {
          _isLoading = false;
        });
        print("Template data not found!");
        return;
      }

      //debug template data
      //print("Template data: ${template['templateFormData']}");

      Map<String, dynamic> templateData = Map<String, dynamic>.from(jsonDecode(template['templateFormData']));
      Map<String, dynamic> formData = form['formData'] != null
          ? Map<String, dynamic>.from(jsonDecode(form['formData']))
          : {};

      Map<String, dynamic> displayedForm = {};
      templateData['questions'].forEach((key, question){
        displayedForm[key] = {
          ...question,
          'answer': formData[key] ?? '',
        };
      });

      setState(() {
        // Decode the JSON stored in the formData column
        _formName = form['formName'];
        //debug merged form
        //print("Merged Form: $displayedForm");
        _formData = displayedForm;
        _templateData = templateData;
        _isLoading = false;
      });

      } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error loading form or template data: $e");
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
              : Padding(
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
          )
    );
  }

  // Use your existing method to build questions
  List<Widget> _buildQuestions(Map<String, dynamic> questions) {
    //print("Building questions: $questions");
    List<Widget> questionWidgets = [];

    questions.forEach((key, question) {
      //debug form field
      //print("Processing: $key -> $question");

      if (question is Map) {
        final questionMap = Map<String, dynamic>.from(question);

        switch (questionMap['type']) {
          case 'dropdown':
            questionWidgets.add(_buildDropdownQuestion(key, questionMap));
            break;
          case 'multiple':
            questionWidgets.add(_buildMultipleChoiceQuestion(key, questionMap));
            break;
          case 'text':
            questionWidgets.add(_buildTextQuestion(key, questionMap));
            break;
          default:
            print("Unknown question type: ${questionMap['type']}");
        }
      // } else if (question is String) {
      //   // Handle simple text questions
      //   questionWidgets.add(
      //     ListTile(
      //       title: Text(key),
      //       subtitle: Text(question),
      //     ),
      //   );
      // } else{
      //   print("Invalid question format for: $key -> $question");
      }
    });
    return questionWidgets;
  }


  // Existing methods for dropdown questions
  Widget _buildDropdownQuestion(String key, Map<String, dynamic> question) {
    List<dynamic> options = question['options'] is List ? question['options'] : [];

    return ListTile(
      title: Text(question['question'] ?? 'Question'),
      subtitle: DropdownButton<String>(
        value: question['answer'] != '' ? question['answer'] : null,
        items: options.map<DropdownMenuItem<String>>((option) {
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

  // Existing methods for multiple-choice questions
  Widget _buildMultipleChoiceQuestion(String key, Map<String, dynamic> question) {
    List<String> selectedOption = List<String>.from(question['answer'] ?? []);
    List<dynamic> options = question['options'] is List ? question['options'] : [];

    return ListTile(
      title: Text(question['question'] ?? 'Question'),
      subtitle: Column(
        children: options.map<Widget>((option) {
          return CheckboxListTile(
            value: selectedOption.contains(option),
            onChanged: (bool? value) {
              setState((){
                if (value == true){
                  selectedOption.add(option as String);
                }else {
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
    TextEditingController controller = TextEditingController(text: question['answer']?.toString() ?? '');
    return ListTile(
      title: Text(question['question'] ?? ''),
      subtitle: TextField(
        controller: controller,
        onChanged: (value){
          _formData![key]['answer'] = value;
        },
        decoration: const InputDecoration(
          hintText: 'Enter your answer',
        ),
      ),
    );
  }
}
