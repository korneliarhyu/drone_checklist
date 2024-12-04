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
      if (form != null) {
        setState(() {
          // Decode the JSON stored in the formData column
          _formName = form['formName'];
          _formData = jsonDecode(form['formData']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        print("Form not found");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
                ),
    );
  }

  // Use your existing method to build questions
  List<Widget> _buildQuestions(Map<String, dynamic> questions) {
    List<Widget> questionWidgets = [];
    questions.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        switch (value['type']) {
          case 'dropdown':
            questionWidgets.add(_buildDropdownQuestion(value));
            break;
          case 'multiple':
            questionWidgets.add(_buildMultipleChoiceQuestion(value));
            break;
          case 'text':
            questionWidgets.add(_buildTextQuestion(value));
            break;
        }
      } else if (value is String) {
        // Handle simple text questions
        questionWidgets.add(
          ListTile(
            title: Text(key),
            subtitle: Text(value),
          ),
        );
      }
    });
    return questionWidgets;
  }


  // Existing methods for dropdown questions
  Widget _buildDropdownQuestion(Map<String, dynamic> question) {
    return ListTile(
      title: Text(question['question']),
      subtitle: DropdownButton<String>(
        items: question['options'].map<DropdownMenuItem<String>>((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: (value) {},
        isExpanded: true,
      ),
    );
  }

  // Existing methods for multiple-choice questions
  Widget _buildMultipleChoiceQuestion(Map<String, dynamic> question) {
    return ListTile(
      title: Text(question['question']),
      subtitle: Column(
        children: question['options'].map<Widget>((option) {
          return CheckboxListTile(
            value: false,
            onChanged: (bool? value) {},
            title: Text(option),
          );
        }).toList(),
      ),
    );
  }

  // Existing methods for text input questions
  Widget _buildTextQuestion(Map<String, dynamic> question) {
    return ListTile(
      title: Text(question['question']),
      subtitle: TextField(
        decoration: const InputDecoration(
          hintText: 'Enter your answer',
        ),
      ),
    );
  }
}
