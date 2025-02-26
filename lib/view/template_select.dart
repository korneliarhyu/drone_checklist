import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drone_checklist/database/database_helper.dart';
import 'package:drone_checklist/helper/utils.dart';
import 'package:drone_checklist/model/template_model.dart';
import 'package:flutter/material.dart';
import 'package:drone_checklist/services/api_service.dart';

class TemplateSelect extends StatefulWidget {
  final int templateId;

  const TemplateSelect({
    super.key,
    required this.templateId,
  });

  @override
  _TemplateSelectState createState() => _TemplateSelectState();
}

class _TemplateSelectState extends State<TemplateSelect> {
  // menggunakan late supaya program menunggu sampai database benar-benar siap untuk fetch template form.
  late Map<String, dynamic> _templateData = {};
  late bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // memanggil sesuai templateId yang diclick
    _loadTemplateData(widget.templateId);
  }

  // Fungsi ini untuk memuat data template dari API berdasarkan ID.
  Future<void> _loadTemplateData(int templateId) async {
    try {
      final dio = Dio();
      final apiService = ApiService(dio);

      // API untuk mendapatkan detail template adalah downloadTemplate(templateId);
      final response = await apiService.downloadTemplate(templateId);

      // response API diconvert ke dalam codingan menggunakan jsonDecode.
      final Map<String, dynamic> templateData = jsonDecode(response);

      //debug
      print("Fetched template: $templateData");
      // _templateData = templateData;

      setState(() {
        // menampung return API ke state _templateData;
        _templateData = templateData;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching template: $e");
      setState(() {
        _isLoading = false;
        _templateData = {};
      });
    }
  }

  Future<bool> _downloadTemplate(int templateId) async {
    try {
      await _loadTemplateData(templateId);

      // if (_templateData.isEmpty) {
      //   print("Template data is empty or not found");
      //   return false;
      // } else {
      //   String serializeForm = json.encode({
      //     'assessment': _templateData['assessment'],
      //     'pre': _templateData['pre'],
      //     'post': _templateData['post']
      //   });
      //
      //   // Jika data tidak kosong, mapping seluruh data dari state _templateData.
      //   // Key: String, Value: dynamic.
      //   Map<String, dynamic> templateData = {
      //     // 'nama data dari model' : servis yang memiliki return dari API ['nama json'],
      //     'serverTemplateId': _templateData['id'],
      //     'templateName': _templateData['templateName'],
      //     'formType': 'assessment-pre-post',
      //     'updatedDate': DateTime.now().toString(),
      //     'templateFormData': serializeForm,
      //     'deletedAt': null,
      //   };

      if (_templateData.isEmpty) {
        print("Template data is empty or not found");
        return false;
      } else {
        // Jika data tidak kosong, mapping seluruh data dari state _templateData.
        // Key: String, Value: dynamic.
        Map<String, dynamic> templateFormData = {
          // 'nama data dari model' : servis yang memiliki return dari API ['nama json'],
          'assessment': _templateData['assessment'],
          'pre': _templateData['pre'],
          'post': _templateData['post']
        };

        final templateModel = TemplateModel(
            templateId: null,
            serverTemplateId: _templateData['id'],
            templateName: _templateData['templateName'],
            formType: 'assessment-pre-post',
            updatedDate: DateTime.now(),
            templateFormData: templateFormData,
            deletedAt: null
        );

        DatabaseHelper.insertTemplate(templateModel);

        //alert success
        showAlert(
            context, "Success", "Success download Template", AlertType.success, (){});
      }

      return true;
    } catch (e) {
      print("Error: $e");
      // alert gagal
      showAlert(
          context, "Failed", "Failed download Template", AlertType.failed, () {});
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_templateData['templateName'] != null
            ? _templateData['templateName']!
            : "Form"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templateData.isEmpty
          ? const Center(child: Text('No template data available'))
          : ListView(
        padding: const EdgeInsets.only(bottom: 85),
        children: [
          if (_templateData['assessment'] != null &&
              _templateData['pre'] != null &&
              _templateData['post'] != null)
            _buildSection('Assessment', _templateData),
          _buildSection('Pre-Check', _templateData),
          _buildSection('Post-Check', _templateData),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 16,
            right: 16, // Atur posisi di kanan bawah
            child: FloatingActionButton.extended(
              onPressed: () async {
                await _downloadTemplate(widget.templateId);
                // Refresh page
                // Navigator.of(context).pop();
                // Navigator.of(context).push(MaterialPageRoute(
                //   builder: (context) =>
                //       TemplateDetail(templateId: widget.templateId),
                // ));
              },
              icon: const Icon(Icons.download),
              label: const Text("Download Template"),
              tooltip: 'Download Template',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Map<String, dynamic> section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        //ini tadinya error
        ...section.keys.take(1).expand((entry) {
          Map<String, dynamic> param = <String, dynamic>{}; //temp
          if (title == "Assessment") {
            param = _templateData['assessment'];
          } else if (title == "Pre-Check") {
            param = _templateData['pre'];
          } else if (title == "Post-Check") {
            param = _templateData['post'];
          }
          // final questionKey = entry.key;
          // final questionData = entry.value;

          return _buildQuestions(param);
        }),
      ],
    );
  }

  List<Widget> _buildQuestions(Map<String, dynamic> questions) {
    List<Widget> questionWidgets = [];
    questions.forEach((questionKey, questionValue) {
      var question = questionValue as Map<String, dynamic>;
      switch (question['type']) {
        case 'dropdown':
          questionWidgets.add(_buildDropdownQuestion(question));
          break;
        case 'multiple':
          questionWidgets.add(_buildMultipleChoiceQuestion(question));
          break;
        case 'text':
          questionWidgets.add(_buildTextQuestion(question));
          break;
        case 'checklist':
          questionWidgets.add(_buildChecklistQuestion(question));
          break;
        case 'longtext':
          questionWidgets.add(_buildLongTextQuestion(question));
      }
    });
    return questionWidgets;
  }

  Widget _buildDropdownQuestion(Map<String, dynamic> question) {
    return ListTile(
      title: Text(question['question']),
      subtitle: DropdownButton<String>(
        items: question['option'].map<DropdownMenuItem<String>>((option) {
          return DropdownMenuItem<String>(
            value: '',
            child: Text(option),
          );
        }).toList(),
        onChanged: (value) {},
        isExpanded: true,
      ),
    );
  }

  Widget _buildChecklistQuestion(Map<String, dynamic> question) {
    return ListTile(
      title: Text(question['question']),
      subtitle: Column(
        children: question['option'].map<Widget>((option) {
          return CheckboxListTile(
            value: false,
            onChanged: null,
            title: Text(
                option,
                style: const TextStyle(
                  color: Colors.black,
                )
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextQuestion(Map<String, dynamic> question) {
    return ListTile(
      title: Text(question['question']),
      subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your answer',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Container(
                height: 1,
                color: Colors.grey,
              )
            ],
          )
      ),
    );
  }

  Widget _buildMultipleChoiceQuestion(Map<String, dynamic> question) {
    return ListTile(
      title: Text(question['question']),
      subtitle: Column(
        children: question['option'].map<Widget>((option) {
          return RadioListTile<String>(
            value: option.toString(),
            groupValue: null,
            onChanged: null,
            title: Text(
              option.toString(),
              style: const TextStyle(
                  color: Colors.black
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLongTextQuestion(Map<String, dynamic> question) {
    return ListTile(
      title: Text(question['question']),
      subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              height: 80.0,
              child: const SingleChildScrollView(
                  child: Text(
                    'Enter your answer',
                    style: TextStyle(color: Colors.grey),
                  )
              )
          )),
    );
  }
}