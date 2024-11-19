import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:drone_flight_checklist/model/template_question.dart';
import 'package:drone_flight_checklist/model/checklist_form_model.dart';
import 'package:drone_flight_checklist/Database/database_helper.dart';

class CreateForm extends StatefulWidget {
  final Questions templateQuestions;

  const CreateForm({super.key, required this.templateQuestions});

  @override
  _CreateFormState createState() => _CreateFormState();
}

class _CreateFormState extends State<CreateForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _questionControllers = {};
  final Map<String, String> _dropdownValues = {}; // Track dropdown values separately

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each question
    for (var entry in widget.templateQuestions.questions.entries) {
      _questionControllers[entry.key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _questionControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _saveForm() {
    if (_formKey.currentState?.validate() ?? false) {
      Map<String, dynamic> formData = {};
      _questionControllers.forEach((key, controller) {
        formData[key] = controller.text;
      });

      // Handle dropdown values
      formData.addAll(_dropdownValues);

    final formModel = ChecklistFormModel(
      formId: null,

      //ini masih hardcode, benerin nanti
      templateId: 1,
      formName: "testForm",
      updatedBy: "feli1",
      //

      updatedDate: DateTime.now(), // Assuming this is what you want
      formData: formData,
    );

    try {
      DatabaseHelper.createChecklistForm(formModel);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form Saved!'))
      );
      Navigator.pop(context, "TestForm"); // Return the form name
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving form: $e'))
      );
    }

      print(jsonEncode(formData));
    }
  }

  Widget _buildFormFields() {
    List<Widget> fields = [];

    for (var entry in widget.templateQuestions.questions.entries) {
      var question = entry.value;
      var key = entry.key;

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
        case 'multiple':
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
                  }).toList(),
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
                    decoration: InputDecoration(
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
      }
    }

    return Column(children: fields);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fill Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildFormFields(),
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
