import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:drone_checklist/model/template_model.dart';
import 'package:drone_checklist/model/form_model.dart';
import 'package:drone_checklist/Database/database_helper.dart';
import 'package:drone_checklist/view/checklist_form_view.dart';

class CreateForm extends StatefulWidget {
  //final Questions templateQuestions;
  final int templateId;

  const CreateForm({
    Key? key,
    //required this.templateQuestions,
    required this.templateId,
  }):super(key: key);

  @override
  _CreateFormState createState() => _CreateFormState();
}

class _CreateFormState extends State<CreateForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _questionControllers = {};
  final Map<String, String> _dropdownValues = {};
  final Map<String, String> _multipleValues = {};
  late Map<String, dynamic> _templateData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // for (var entry in widget.templateQuestions.questions.entries) {
    //   _questionControllers[entry.key] = TextEditingController();
    // }
    _getTemplate(widget.templateId);
  }

  Future<void> _getTemplate(int templateId) async{
    var templateData = await DatabaseHelper.getTemplateById(widget.templateId);
    if (templateData != null){
      setState(() {
        _templateData = jsonDecode(templateData['templateFormData']);
      });
    }
    else {
      print("Template not found");
    }
  }

  @override
  void dispose() {
    for (var controller in _questionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveForm() async{
    if (_formKey.currentState?.validate() ?? false) {
      Map<String, dynamic> formData = {};

      _questionControllers.forEach((key, controller) {
        formData[key] = controller.text;
      });

      formData.addAll(_multipleValues);

      formData.addAll(_dropdownValues);

    final formModel = FormModel(
      formId: null,

      //ini masih hardcode, benerin nanti
      templateId: 1,
      formName: "meow",
      // updatedBy: "User",
      updatedDate: DateTime.now(),
      formData: formData,
      deletedAt: null,
    );

    try {
      DatabaseHelper.createForm(formModel);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form Saved!'))
      );
      Navigator.pop(context, formModel);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving form: $e'))
      );
    }

      print(jsonEncode(formData));
    }
  }

  List<Widget> _buildFormFields() {
    // if(_templateData == null || templateData!['questions'] == null){
    //   return const Center(
    //     child: Text("No Template available"),
    //   );
    // }

    final questions = _templateData['questions'] as List<dynamic>;
    List<Widget> fields = [];

    for (var question in questions) {
      var key = question['id'] ?? '';
      // var question = entry.value;
      // var key = entry.key;

      switch (question.type) {
        case 'text':
          fields.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextFormField(
                controller: _questionControllers[key],
                decoration: InputDecoration(labelText: question.question),
                validator: (value) {
                  if (question.required && (value == null || value.isEmpty)) {
                    return '${question.question} is required';
                  }
                  return null;
                },
              ),
            ),
          );
          break;

        case 'checklist':
          fields.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(question.question),
                  ...question.option.map((opt) {
                    return CheckboxListTile(
                      title: Text(opt),
                      value: _questionControllers[key]?.text.contains(opt) ?? false,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _questionControllers[key]?.text += ' $opt';

                          } else {
                            _questionControllers[key]?.text =
                                _questionControllers[key]!.text.replaceAll(' $opt', '');
                          }
                        });
                      },
                    );
                  })//.toList(),
                ],
              ),
            ),
          );
          break;

        case 'dropdown':
          fields.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(question.question),
                  DropdownButtonFormField<String>(
                    value: _dropdownValues[key],
                    onChanged: (String? newValue) {
                      setState(() {
                        _dropdownValues[key] = newValue ?? '';
                      });
                    },
                    items: question.option.map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      labelText: "Select an option",
                    ),
                    validator: (value) {
                      if (question.required && (value == null || value.isEmpty)) {
                        return '${question.question} is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          );
          break;
        
        case 'multiple':
          fields.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(question.question),
                  ...question.option.map((opt) {
                    return RadioListTile<String>(
                      title: Text(opt),
                      value: opt,
                      groupValue: _multipleValues[key], 
                      onChanged: (String? value) {
                        setState(() {
                          _multipleValues[key] = value ?? '';
                        });
                      },
                    );
                  })//.toList(),
                ],
              ),
            ),
          );
          break;

      }
    }

    return fields;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fill Form'),
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : _templateData == null
          ? const Center(
            child: Text("Please Select a template!",
            style: TextStyle(fontSize:18),
            ),
        )
      : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ..._buildFormFields(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveForm,
                child: const Text('Save Form'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
