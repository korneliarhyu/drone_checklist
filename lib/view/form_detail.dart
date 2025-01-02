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
      List<Map<String, dynamic>> updatedSections = [];//buat list untuk handle order dari section jsonnya, section type pre, ke type post, ke type assessment

      _formData?.forEach((section) {
        if (section['type'] == 'pre' && isCheckPre) {
          _newFlight(section);
        } else if (section['type'] == 'post' && isCheckPost) {
          _newFlight(section);
        } else {
          _updateData(section);
        }

        //ambil entry terakhir/terbaru pas update formnya
        List<dynamic> updatedAnswers = [];
        if (section['type'] == 'assessment') {
          //handle untuk tipe assessment karena struktur jsonnya beda sendiri dari 2 tipe lain
          section['answer'].forEach((answer) {
            updatedAnswers.add({
              'answer': answer['answer'],
              'dataChanged': answer['dataChanged'],
              'option': List<String>.from(answer['option'] ?? []),
              'qType': answer['qType'],
              'questionName': answer['questionName']
            });
          });
        } else {
          //handle default/biasa buat tipe pre dan post
          Map<String, dynamic> lastEntry = Map<String, dynamic>.from(section['answer'].last);
          updatedAnswers = [lastEntry];
        }

        updatedSections.add({
          "type": section['type'],
          "answer": updatedAnswers
        });
      });

      String encodeUpdatedFormData = jsonEncode(updatedSections); //disini aku pake nama variable updatedSections bisa diganti ke updatedformData, ganti di line 81 sama 75
      String encodeFormData = jsonEncode(_formData);

      // Update the database with both formData and updatedFormData
      await DatabaseHelper.updateForm(widget.formId, encodeFormData, encodeUpdatedFormData);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Form updated successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating form: $e')));
    }
  }


  //Add new flight entry to json
  void _newFlight(Map<String, dynamic> section) {
    int newFlightNum = section['answer'].length + 1;
    List<Map<String, dynamic>> newData = (section['answer'].last['data'] as List<dynamic>).map<Map<String, dynamic>>((data) {
      List<String> options = data['option'] != null ? List<String>.from(data['option']) : [];

      return {
        'questionName': data['questionName'],
        'answer': _questionControllers[data['questionName']]?.text ?? '',
        'dataChanged': DateTime.now().toString().split('.').first.replaceAll('-', '/'),
        'qType': data['qType'],
        'option': options
      };
    }).toList();

    section['answer'].add({
      'flightNum': newFlightNum,
      'data': newData
    });
  }



  //update normal (tidak nambah entry baru)
  void _updateData(Map<String, dynamic> section) {
    List<dynamic> answers = section['answer'] as List;
    for (var answer in answers) {
      if (answer['data'] != null) { //cek data di json ada atau tidak kalo ngga ada berarti type assessment langsung ke line 107
        List<dynamic> dataEntries = answer['data'] as List;
        for (var data in dataEntries) {
          String questionName = data['questionName'];
          TextEditingController? controller = _questionControllers[questionName];
          if (controller != null) {
            data['answer'] = controller.text;
            data['dataChanged'] = DateTime.now().toString().split('.').first.replaceAll('-', '/');
            if (data.containsKey('option') && data['option'] != null) {
              List<String> options = List<String>.from(data['option']);
              data['option'] = options;
            }
          }
        }
      } else {
        String questionName = answer['questionName'];
        TextEditingController? controller = _questionControllers[questionName];
        if (controller != null) {
          answer['answer'] = controller.text;
          answer['dataChanged'] = DateTime.now().toString();
          if (answer.containsKey('option') && answer['option'] != null) {
            List<String> options = List<String>.from(answer['option']);
            answer['option'] = options;
          }
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
      List<Map<String, dynamic>> formData = form['updatedformData'] != null
          ? List<Map<String, dynamic>>.from(jsonDecode(form['updatedformData']))
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
                List<String> selectedOptions = data['answer'].split(', ').map((item) => item.trim()).toList();
                _checkboxValues[questionId] = Set<String>.from(selectedOptions);
                _questionControllers[questionId] = TextEditingController(text: data['answer']);
              } else {
                _questionControllers[data['questionName']] = TextEditingController(text: data['answer']);
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
        title: Text(_formName?['formName'] ?? 'Untitled Form'),
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
                      print("isCheckPre changed to: $value");
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Add new flight for Post?'),
                  value: isCheckPost,
                  onChanged: (bool value) {
                    setState(() {
                      isCheckPost = value;
                      print("isCheckPost changed to: $value");
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
        print("Building fields for section: ${section['type']}");
        fields.add(Text(
          section['type'].toString().toUpperCase(),
          style: Theme.of(context).textTheme.headlineLarge,
        ));
        if (section['type'] == 'assessment') {
          for (var answer in section['answer']) {
            String questionId = answer['questionName'];
            TextEditingController controller = _questionControllers.putIfAbsent(
                questionId, () => TextEditingController(text: answer['answer'])
            );
            fields.add(_buildQuestionField(answer, questionId, controller));
          }
        } else {
          for (var answerInfo in section['answer']) {
            for (var data in answerInfo['data']) {
              String questionId = data['questionName'];
              TextEditingController controller = _questionControllers.putIfAbsent(
                  questionId, () => TextEditingController(text: data['answer'])
              );
              fields.add(_buildQuestionField(data, questionId, controller));
            }
          }
        }
      }
      print("Number of fields added: ${fields.length}");
    }
    return fields;
  }


  Widget _buildQuestionField(Map<String, dynamic> question, String questionId, TextEditingController controller) {
    List<dynamic> options = List<String>.from(question['option'] ?? []); //buat ambil option dropdown & multiple (Checklist ga pake ini karena harus di trim)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question['questionName']),
          if (question['qType'] == 'text' || question['qType'] == 'longtext')
            TextFormField(
                controller: controller,
                decoration: InputDecoration(labelText: 'Answer')
            ),
          if (question['qType'] == 'checklist')
            ...question['option'].map<Widget>((option) {
              bool isChecked = (_checkboxValues[questionId] ??= Set<String>()).contains(option);
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
                    _questionControllers[questionId]?.text = _checkboxValues[questionId]?.join(', ') ?? '';
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