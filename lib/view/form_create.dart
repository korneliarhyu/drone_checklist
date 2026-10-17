import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:drone_checklist/theme/app_theme.dart';
import 'package:drone_checklist/model/form_model.dart';
import 'package:drone_checklist/database/database_helper.dart';
import 'package:drone_checklist/helper/utils.dart';
import 'form_view.dart';
import 'package:drone_checklist/widgets/success_dialog.dart';

class FormCreate extends StatefulWidget {
  final int templateId;

  const FormCreate({
    super.key,
    required this.templateId,
  });

  @override
  State<FormCreate> createState() => _FormCreateState();
}

class _FormCreateState extends State<FormCreate> {
  static const List<String> _sections = [
    'assessment',
    'pre',
    'post',
  ];

  static const List<String> _titles = [
    'Assessment',
    'Pre-Flight',
    'Post-Flight',
  ];

  static const List<String> _descriptions = [
    'Evaluate your drone before the flight.',
    'Complete the pre-flight checklist.',
    'Record your post-flight observations.',
  ];

  static const Color _errorColor = Color(0xFFC94444);

  final _formKey = GlobalKey<FormState>();

  final Map<String, TextEditingController> _questionControllers = {};

  final Map<String, String?> _dropdownValues = {};
  final Map<String, String> _multipleValues = {};
  final Map<String, String> _textboxValues = {};
  final Map<String, Set<String>> _checkboxValues = {};

  // Membuat dua variable kosong bertype Map _templateData dan _formData untuk menghindari error non-nullable.
  Map<String, dynamic>? _templateData = {};
  Map<String, dynamic> _formData = {};
  final Map<String, String> _questionName = {};
  final Map<String, String> _questionType = {};
  final Map<String, List<String>> _questionOptions = {};

  bool _isLoading = true;
  bool _isSaving = false;
  bool _showErrors = false;
  String? _loadError;

  int _currentStep = 0;
  String get _currentSection => _sections[_currentStep];
  double get _progress => (_currentStep + 1) / 3;

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
    for (final section in _sections) {
      final questions = data[section];

      if (questions is! Map) continue;

      for (final entry in questions.entries) {
        final key = '$section-${entry.key}';

        final question = Map<String, dynamic>.from(
          entry.value as Map,
        );

        final type = question['type']?.toString() ?? '';

        _questionName[key] = question['question']?.toString() ?? '';
        _questionType[key] = type;

        final rawOptions = question['option'];

        _questionOptions[key] = rawOptions is List
            ? rawOptions.map((option) => option.toString()).toList()
            : <String>[];


        switch (type) {
          case 'text':
          case 'longtext':
            _questionControllers.putIfAbsent(
              key, () => TextEditingController());
            _textboxValues.putIfAbsent(key, () => '');
            break;

          case 'dropdown':
            _dropdownValues.putIfAbsent(key, () => null);
            break;

          case 'multiple':
            _multipleValues.putIfAbsent(key, () => '');
            break;

          case 'checklist':
            _checkboxValues.putIfAbsent(key, () => <String>{});
            break;
        }
      }
    }
  }

  Future<void> _saveForm() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });
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

    for (var section in ['pre', 'post']) {
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
    }

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

      // ANIMATE SUCCESS CHECKLIST
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const SuccessDialog(
          title: 'Success',
          message: 'Form saved successfully!',
          buttonText: 'OK',
        ),
      );

      // BACK TO MAIN MENU
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const FormView(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showAlert(context, 'Form Not Saved!', 'Failed saving form!',
        AlertType.failed, () {},
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }

    // try {
    //   await DatabaseHelper.createForm(formModel);
    // } catch (e) {
    //   showAlert(context, "Form Not Saved!", "Failed saving form!",
    //       AlertType.failed, () {});
    // }
    // print(jsonEncode(formModel.formData));
  }


  List<Widget> _buildFormFields() {
    final rawQuestions = _formData[_currentSection];

    if (rawQuestions is! Map || rawQuestions.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text('No questions in this section.'),
          ),
        ),
      ];
    }

    return rawQuestions.entries.map<Widget>((entry) {
      final questionId = '$_currentSection-${entry.key}';
      final question = Map<String, dynamic>.from(
        entry.value as Map,
      );

      return _buildQuestionField(
        questionId,
        question,
        _questionControllers[questionId],
      );
    }).toList();
  }


  Widget _buildProgressHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.softGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _currentStep == 0
                        ? Icons.fact_check_outlined
                        : _currentStep == 1
                        ? Icons.flight_takeoff
                        : Icons.flight_land,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titles[_currentStep],
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _descriptions[_currentStep],
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_currentStep + 1}/3',
                  style: const TextStyle(
                    color: AppColors.forest,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 7,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.forest,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: List.generate(_titles.length, (index) {
                final reached = index <= _currentStep;

                return Expanded(
                  child: Text(
                    _titles[index],
                    textAlign: index == 0
                        ? TextAlign.start
                        : index == 2
                        ? TextAlign.end
                        : TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: reached
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: reached
                          ? AppColors.forest
                          : AppColors.charcoal,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionField(
      String uniqueQuestionId,
      Map<String, dynamic> question,
      TextEditingController? controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question['question']),
          if (question['type'] == 'text')
            TextFormField(
              controller: controller,
              decoration: const InputDecoration(labelText: "Answer"),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //validasi muncul setelah tombol continue di tekan
                if (_showErrors && _isQuestionRequired(question) && (_checkboxValues[uniqueQuestionId]?.isEmpty ?? true))
                  const Text(
                    'Please select at least one option',
                    style: TextStyle(
                      color: _errorColor,
                      fontSize: 12,
                    ),
                  ),
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
              ],
            ),

          if (question['type'] == 'dropdown')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showErrors && _isQuestionRequired(question) && (_dropdownValues[uniqueQuestionId]?.isEmpty ?? true))
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Please select an option',
                      style: TextStyle(
                        color: _errorColor,
                        fontSize: 12,
                      ),
                    ),
                  ),

                DropdownButtonFormField<String>(
                      initialValue: _dropdownValues[uniqueQuestionId],
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
                      decoration: const InputDecoration(labelText: 'Select one'),
                    ),
              ],
            ),

          if (question['type'] == 'multiple')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showErrors && _isQuestionRequired(question) && (_multipleValues[uniqueQuestionId]?.isEmpty ?? true))
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Please select an option',
                      style: TextStyle(
                        color: _errorColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                RadioGroup<String>(
                  groupValue: _multipleValues[uniqueQuestionId],
                  onChanged: (String? value) {
                    setState(() {
                      _multipleValues[uniqueQuestionId] = value ?? "";
                    });
                  },
                  child: Column(
                    children: question['option'].map<Widget>((option) {
                      return RadioListTile<String>(
                        title: Text(option),
                        value: option,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),

          if (question['type'] == 'longtext')
            TextFormField(
              controller: controller,
              maxLines: 5,
              minLines: 3,
              decoration: const InputDecoration(
                hintText: 'Write your answer...',
              ),
              onChanged: (value) {
                _textboxValues[uniqueQuestionId] = value;
              },
            ),
        ],
      ),
    );
  }

  bool _isQuestionRequired(Map<String, dynamic> question) {
    final value = question['required'];
    return value == true ||
        value?.toString().toLowerCase() == 'true';
  }

  bool _validateCurrentStep() {
    setState(() {
      _showErrors = true;
    });

    final formValid = _formKey.currentState?.validate() ?? true;
    var customValid = true;

    final rawQuestions = _formData[_currentSection];

    if (rawQuestions is Map) {
      for (final entry in rawQuestions.entries) {
        final question = Map<String, dynamic>.from(
          entry.value as Map,
        );

        if (!_isQuestionRequired(question)) continue;

        final key = '$_currentSection-${entry.key}';
        final type = question['type']?.toString() ?? '';

        if (type == 'dropdown' &&
            (_dropdownValues[key]?.isEmpty ?? true)) {
          customValid = false;
        }

        if (type == 'multiple' &&
            (_multipleValues[key]?.isEmpty ?? true)) {
          customValid = false;
        }

        if (type == 'checklist' &&
            (_checkboxValues[key]?.isEmpty ?? true)) {
          customValid = false;
        }
      }
    }

    return formValid && customValid;
  }


  @override
  Widget build(BuildContext context) {
    final templateName =
        _templateData?['templateName']?.toString() ??
            'Drone Flight Checklist';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(templateName),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressHeader(),
                      const SizedBox(height: 24),
                      Text(
                        _titles[_currentStep],
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                          color: AppColors.forest,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _descriptions[_currentStep],
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: _buildFormFields(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () {
                            setState(() {
                              _currentStep--;
                              _showErrors = false;
                            });
                          },
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : () async {
                          if (!_validateCurrentStep()) {
                            return;
                          }

                          if (_currentStep <
                              _sections.length - 1) {
                            setState(() {
                              _currentStep++;
                              _showErrors = false;
                            });
                          } else {
                            await _saveForm();
                          }
                        },
                        child: _isSaving
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          _currentStep == _sections.length - 1 ? 'Submit' : 'Continue',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
