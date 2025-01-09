import 'dart:convert';
import 'package:drone_checklist/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class FormFill extends StatefulWidget {
  final int formId;
  const FormFill({Key? key, required this.formId}) : super(key: key);

  @override
  _FormFillState createState() => _FormFillState();
}

class _FormFillState extends State<FormFill> {
  Map<String, TextEditingController> _questionControllers = {};
  final Map<String, String> _dropdownValues = {}; //dropdown
  final Map<String, String> _multipleValues = {}; //radio
  final Map<String, String> _textboxValues = {}; //text and longtext
  final Map<String, Set<String>> _checkboxValues = {}; //checklist
  Map<String, List<String>> _selectedOptions = {};

  List<Map<String, dynamic>>? _formData;
  Map<String, dynamic>? _formName = {};
  bool _isLoading = true;
  bool isCheckPre = false;
  bool isCheckPost = false;

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

  void _updateForm(bool isCheckPre, bool isCheckPost) async {
    try {
      List<Map<String, dynamic>> updatedSections = [];

      _formData?.forEach((section) {
        bool isNewFlight = (section['type'] == 'pre' && isCheckPre) ||
            (section['type'] == 'post' && isCheckPost);

        if (isNewFlight) {
          _newFlight(section);
        } else {
          _updateData(section);
        }
        updatedSections.add(section);
      });

      String encodeUpdatedFormData = jsonEncode(updatedSections);
      String encodeFormData = jsonEncode(_formData);

      await DatabaseHelper.updateForm(
          widget.formId, encodeFormData, encodeUpdatedFormData);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Form updated successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error updating form: $e')));
    }
  }

  void _newFlight(Map<String, dynamic> section) {
    int newFlightNum = 1;
    if (section['answer'].isNotEmpty) {
      newFlightNum = section['answer']
              .map<int>((a) => a['flightNum'] as int)
              .reduce((int a, int b) => math.max(a, b)) + 1;
    }
    List<Map<String, dynamic>> newData =
        (section['answer'].last['data'] as List<dynamic>)
            .map<Map<String, dynamic>>((data) {
      return {
        'questionName': data['questionName'],
        'answer': _questionControllers[data['questionName']]?.text ?? '',
        'dataChanged':
            DateTime.now().toString().split('.').first.replaceAll('-', '/'),
        'qType': data['qType'],
        'option': List<String>.from(data['option'] ?? [])
      };
    }).toList();

    section['answer'].add({'flightNum': newFlightNum, 'data': newData});
  }

  void _updateData(Map<String, dynamic> section) {
    for (var flight in section['answer']) {
      if (flight['data'] != null) {
        for (var data in flight['data']) {
          String questionName = data['questionName'];
          TextEditingController? controller =
              _questionControllers[questionName];
          if (controller != null) {
            data['answer'] = controller.text;
            data['dataChanged'] =
                DateTime.now().toString().split('.').first.replaceAll('-', '/');
          }
        }
      } else {
        String questionName = flight['questionName'];
        TextEditingController? controller = _questionControllers[questionName];
        if (controller != null) {
          flight['answer'] = controller.text;
          flight['dataChanged'] = DateTime.now().toString();
        }
      }
    }
  }

  void _loadFormData(int formId) async {
    try {
      var form = await DatabaseHelper.getFormById(formId);
      if (form == null) {
        print("Form data not found!: $formId");
        setState(() => _isLoading = false);
        return;
      }
      print("Form data retrieved: $form");
      List<Map<String, dynamic>> formData = form['updatedFormData'] != null
          ? List<Map<String, dynamic>>.from(jsonDecode(form['updatedFormData']))
          : [];

      print("Parsed form data: $formData");
      // initiate buat pertanyaan type checklist agar bisa diambil jawaban dan dipassing ke text controller karna value checkbox itu tipe boolean dan bukan string
      // _formData = formData;
      _formData?.forEach((section) {
        section['answer'].forEach((answer) {
          if (answer['data'] != null) {
            answer['data'].forEach((data) {
              if (data['qType'] == 'checklist') {
                String questionId = data['questionName'];
                List<String> selectedOptions = data['answer']
                    .split(', ')
                    .map((item) => item.trim())
                    .toList();
                _checkboxValues[questionId] = Set<String>.from(selectedOptions);
                _questionControllers[questionId] =
                    TextEditingController(text: data['answer']);
              } else {
                _questionControllers[data['questionName']] =
                    TextEditingController(text: data['answer']);
              }
            });
          }
        });
      });
      setState(() {
        _formData = formData;
        _formName = form;
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
        title: Text("Fill Form"),
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
                            _formName?['formName'] ?? 'Untitled Form',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ..._buildFormFields(),
                          SwitchListTile(
                            title: const Text('Add new flight for Pre?'),
                            value: isCheckPre,
                            onChanged: (bool value) {
                              setState(() {
                                isCheckPre = value;
                              });
                            },
                          ),
                          SwitchListTile(
                            title: const Text('Add new flight for Post?'),
                            value: isCheckPost,
                            onChanged: (bool value) {
                              setState(() {
                                isCheckPost = value;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              _updateForm(isCheckPre, isCheckPost);
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
      for (var section in _formData!) {
        fields.add(Text(
          section['type'].toString().toUpperCase(),
          style: Theme.of(context).textTheme.headlineLarge,
        ));
        if (section['type'] == 'assessment') {
          for (var answer in section['answer']) {
            String questionId = answer['questionName'];
            TextEditingController controller = _questionControllers.putIfAbsent(
                questionId,
                () => TextEditingController(text: answer['answer']));
            fields.add(_buildQuestionField(answer, questionId, controller));
          }
        } else {
          for (var answerInfo in section['answer']) {
            for (var data in answerInfo['data']) {
              String questionId = data['questionName'];
              TextEditingController controller =
                  _questionControllers.putIfAbsent(questionId,
                      () => TextEditingController(text: data['answer']));
              fields.add(_buildQuestionField(data, questionId, controller));
            }
          }
        }
      }
    }
    return fields;
  }

  Widget _buildQuestionField(Map<String, dynamic> question, String questionId,
      TextEditingController controller) {
    List<dynamic> options = List<String>.from(question['option'] ??
        []); //buat ambil option dropdown & multiple (Checklist ga pake ini karena harus di trim)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question['questionName']),
          if (question['qType'] == 'text' || question['qType'] == 'longtext')
            TextFormField(
                controller: controller,
                decoration: InputDecoration(labelText: 'Answer')),
          if (question['qType'] == 'checklist')
            ...question['option'].map<Widget>((option) {
              bool isChecked = (_checkboxValues[questionId] ??= Set<String>())
                  .contains(option);
              return CheckboxListTile(
                title: Text(option),
                value: isChecked,
                onChanged: (bool? isSelected) {
                  setState(() {
                    if (isSelected ?? false) {
                      _checkboxValues[questionId]?.add(option);
                    } else {
                      _checkboxValues[questionId]?.remove(option);
                    }
                    // Update the controller text to match the current selection state
                    _questionControllers[questionId]?.text =
                        _checkboxValues[questionId]?.join(', ') ?? '';
                  });
                },
              );
            }).toList(),
          if (question['qType'] == 'dropdown')
            DropdownButtonFormField<String>(
              value: controller.text.isEmpty ? null : controller.text,
              onChanged: (String? newValue) {
                setState(() {
                  controller.text = newValue ?? '';
                });
              },
              items: options.map<DropdownMenuItem<String>>((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              decoration: InputDecoration(labelText: 'Select one'),
            ),
          if (question['qType'] == 'multiple')
            ...question['option'].map<Widget>((option) {
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: _multipleValues[questionId] ?? question['answer'],
                onChanged: (String? value) {
                  setState(() {
                    _multipleValues[questionId] = value!;
                    _questionControllers[questionId]?.text = value ?? '';
                  });
                },
              );
            }).toList(),
        ],
      ),
    );
  }
}
