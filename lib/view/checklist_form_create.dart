import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:drone_checklist/model/checklist_form_model.dart';
import 'package:drone_checklist/Database/database_helper.dart';
import 'checklist_form_view.dart';


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

  Map<String, dynamic>? templateData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getTemplate(widget.templateId);
  }

  Future<void> _getTemplate(int templateId) async{
    var fetchedTemp = await DatabaseHelper.getTemplateById(templateId);
    setState(() {
      if(fetchedTemp != null && fetchedTemp['templateFormData'] != null){
        templateData = jsonDecode(fetchedTemp['templateFormData']);
      } else{
        templateData = null;
      }
      print("Fetched Template: $fetchedTemp");

      isLoading = false;
    });
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

    final formModel = ChecklistFormModel(
      formId: null,
      templateId: widget.templateId,
      //formname masih hardcode
      formName: "meow",
      // updatedBy: "User",
      updatedDate: DateTime.now(),
      formData: formData,
      deletedAt: null,
    );

    try {
      DatabaseHelper.createChecklistForm(formModel);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form Saved!'))
      );
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ChecklistFormView()
          ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving form: $e'))
      );
    }
      //debug data jsonnya dapet / ngga
      //print(jsonEncode(formData));
    }
  }

  List<Widget> _buildFormFields(Map<String, dynamic> questions) {
    List<Widget> fields = [];

    questions.forEach((key, value) {
      var question = value as Map<String, dynamic>;
      switch (question['type']) {
        case 'text':
          fields.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextFormField(
                controller: _questionControllers[key],
                decoration: InputDecoration(labelText: question['question']),
                validator: (value) {
                  if (question['required'] && (value == null || value.isEmpty)) {
                    return '${question['question']} is required';
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
                  Text(question['question']),
                  ...question['options'].map((opt) {
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
                  Text(question['question']),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: "Select an option"),
                    value: _dropdownValues[key],
                    onChanged: (String? newValue) {
                      setState(() {
                        _dropdownValues[key] = newValue ?? '';
                      });
                    },
                    items: (question['options'] as List<dynamic>).map((option) => DropdownMenuItem<String>(
                        value: option,
                        child: Text(option.toString()),
                      ))
                    .toList(),
                    validator: (value) {
                      if (question['required'] && (value == null || value.isEmpty)) {
                        return '${question['question']} is required';
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
                  Text(question['question']),
                  ...question['options'].map((opt) {
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
    });

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
        : templateData == null || templateData!['questions'] == null
          ? const Center(
            child: Text("Template doesn't exist!",
            style: TextStyle(fontSize:18),
            ),
        )
      : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ..._buildFormFields(templateData?['questions']),
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
