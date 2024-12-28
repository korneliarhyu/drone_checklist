import 'dart:convert';
import 'package:drone_checklist/database/database_helper.dart';
import 'package:drone_checklist/helper/utils.dart';
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
  String? _formName;
  bool _isLoading = true;

  // make condition for checked in pre/post form
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

  void _updateForm(isCheckPre, isCheckPost) async {
    try {
      _formData?.forEach((section) {
        if (section['type'] == 'pre' && isCheckPre) {
          _newFlight(section);
        }
        else if (section['type'] == 'post' && isCheckPost) {
          _newFlight(section);
        }
        else {
          _updateData(section);
        }
      });
      String encodeFormData = jsonEncode(_formData);
      await DatabaseHelper.updateForm(widget.formId, encodeFormData);

      showAlert(context, "Success Update", "Your update has been success",
          AlertType.success);
    } catch (e) {
      showAlert(context, "Failed Update", "Your update has been cancelled",
          AlertType.failed);
    }
  }

  // nambah flightNum
  void _newFlight(Map<String, dynamic> section) {
    int newFlightNum =
        section['answer'].length + 1; // supaya flightNum selalu increase + 1
    List<Map<String, dynamic>> newData =
    (section['answer'].last['data'] as List<dynamic>)
        .map<Map<String, dynamic>>((data) {
      List<String> options =
      data['option'] != null ? List<String>.from(data['option']) : [];

      return {
        'questionName': data['questionName'],
        'answer': _questionControllers[data['questionName']]?.text ?? '',
        'dataChaged':
        DateTime.now().toString().split('.').first.replaceAll('-', '/'),
        'qType': data['qType'],
        'options': options
      };
    }).toList();

    section['answer'].add({
      'flightNum': newFlightNum,
      'data': newData
    });
  }

  //update biasa tanpa nambah flight baru
  void _updateData(Map<String, dynamic> section) {
    List<dynamic> answers = section['answer'] as List;

    for (var answer in answers) {
      if (answer['data'] != null) {
        //cek data di json ada atau tidak kalo ngga ada berarti type assessment
        List<dynamic> dataEntries = answer['data'] as List;

        for (var data in dataEntries) {
          String questionName = data['questionName'];
          TextEditingController? controller =
          _questionControllers[questionName];

          if (controller != null) {
            data['answer'] = controller.text;
            data['dataChanged'] =
                DateTime.now().toString().split('.').first.replaceAll('-', '/');
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
      print("Form data retrieved: $form");
      if (form == null) {
        setState(() => _isLoading = false);
        print("Form data not found!: $formId");
        showAlert(
            context, "Error 1", "Failed to load form data", AlertType.failed);
        return;
      }

      // Decode the formData and ensure it's properly cast as List<Map<String, dynamic>>
      List<Map<String, dynamic>>? formData = form['formData'] != null
          ? List<Map<String, dynamic>>.from(jsonDecode(form['formData']))
          : [];

      // initiate buat pertanyaan type checklist agar bisa diambil jawaban dan dipassing ke text controller karna value checkbox itu tipe boolean dan bukan string
      _formData = formData;
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
              ;
            });
          }
        });
      });

      String formName = form['formName'];
      print("Form name fetched: $form['formName");
      setState(() {
        _formName = formName;
        _isLoading = false;
      });

    } catch (e) {
      setState(() => _isLoading = false);
      print("Error loading form data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Building with formName: $_formName");
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
                ..._buildFormFields(),
                SwitchListTile(
                  title: const Text('Add new flight to Post?'),
                  value: isCheckPost,
                  onChanged: (bool value) {
                    setState(() {
                      isCheckPost = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Add new flight to Pre?'),
                  value: isCheckPre,
                  onChanged: (bool value) {
                    setState(() {
                      isCheckPre = value;
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
      // define order sections (not done)
      List<String> sectionOrder = ['assessment', 'pre', 'post'];

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
    List<dynamic> options = List<String>.from(question['option']); // tampung options dropdown & multiple

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
              //_checkboxValues[questionId] = menyimpan jawaban dari user.
              // Set<String>() = mengambil jawaban yang tersimpan di database

              // assign value _checkboxValues[questionId] jika isChecked ada perubahan;
              // kalau tidak ada perubahan, value isChecked akan tetap sama: Set<String>()
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

          // code maullll
          if (question['qType'] == 'multiple')
            ...question['option'].map<Widget>((option) {
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: _multipleValues[questionId] ?? question['answer'],
                onChanged: (String? newValue) {
                  setState(() {
                    _multipleValues[questionId] = newValue!;
                    print('Updated groupValue: ${_multipleValues[questionId]}');
                    _questionControllers[questionId]?.text = newValue ?? '';
                  });
                },
              );
            }).toList(),
        ],
      ),
    );
  }
}
