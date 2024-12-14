import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drone_checklist/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:drone_checklist/services/api_service.dart';

class TemplateDetail extends StatefulWidget {
  final int templateId;

  const TemplateDetail({
    Key? key,
    required this.templateId,
  }) : super(key: key);

  @override
  _TemplateDetailState createState() => _TemplateDetailState();
}

class _TemplateDetailState extends State<TemplateDetail> {
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
    try{
      final dio = Dio();
      final apiService = ApiService(dio);

      final response = await apiService.downloadTemplate(templateId);

      final Map<String, dynamic> templateData = jsonDecode(response);

      //debug
      print("Fetched template: $templateData");
      // _templateData = templateData;

      setState(() {
        _templateData = templateData;
        _isLoading = false;
      });
    } catch(e){
      print("Error fetching template: $e");
      setState(() {
        _isLoading = false;
        _templateData = {};
      });
    }
    //before
    // var templateData = await DatabaseHelper.getDummyTemplateById(templateId);
    // if (templateData != null) {
    //   setState(() {
    //     _templateData = jsonDecode(templateData['templateFormData']);
    //   });
    // } else {
    //   print("Template not found");
    // }
  }

  Future<bool> _downloadTemplate(int templateId) async {
    try{
      var dummyTemplate = await DatabaseHelper.getDummyTemplateById(templateId);
      if (dummyTemplate == null) {
        return false;
      } else {
        Map<String, dynamic> templateData = {
          'templateName': dummyTemplate['templateName'],
          'formType': dummyTemplate['formType'],
          'updatedDate': DateTime.now().toString(),
          'templateFormData': dummyTemplate['templateFormData'],
          'deletedAt': null
        };
        DatabaseHelper.insertTemplate(templateData);
        return true;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_templateData['templateName'] != null ? _templateData['templateName']! : "Form"),
      ),
      body: _isLoading
        ? const Center(child:CircularProgressIndicator())
        : _templateData.isEmpty
          ? const Center(child: Text('No template data available'))
          : ListView(
            children: [
              if(_templateData['assessment'] != null && _templateData['pre'] != null && _templateData['post'] != null)
                _buildSection('Assessment', _templateData),
                _buildSection('Pre-Check', _templateData),
                _buildSection('Post-Check', _templateData),
              // if(_templateData['pre'] != null)
              //   _buildSection('Pre-Check', _templateData['pre']),
              // if(_templateData['post'] != null)
              //   _buildSection('Post-Check', _templateData['post']),
              // ListTile(
              //   title: Text(_templateData['title']),
              //   // subtitle: Text("Template ID: ${_templateData['templateId']}"),
              // ),
              // //menggunakan spread Operator untuk memasukkan semua widget pertanyaan ke dalam ListView
              // ..._buildQuestions(_templateData['questions']),
            ],
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 16,
            right: 16,  // Atur posisi di kanan bawah
            child: FloatingActionButton.extended(
              onPressed: () {
                // Tambahkan fungsi unduh data di sini
                _downloadTemplate(widget.templateId);
                print('Download Data');
              },
              icon: Icon(Icons.download),
              label: Text("Download Template"),
              tooltip: 'Download Template',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Map<String, dynamic> section){
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
        ...section.keys.take(1).expand((entry){

          Map<String, dynamic> param = new Map<String, dynamic>();//temp
          if(title=="Assessment"){
            param = _templateData['assessment'];
          }
          else if(title=="Pre-Check"){
            param = _templateData['pre'];
          }
          else if(title=="Post-Check"){
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
            value: option,
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
            onChanged: (bool? value) {},
            title: Text(option),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextQuestion(Map<String, dynamic> question) {
    return ListTile(
      title: Text(question['question']),
      subtitle: TextField(
        decoration: InputDecoration(
          hintText: 'Enter your answer',
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceQuestion(Map<String, dynamic> question){
    return ListTile(
      title: Text(question['question']),
      subtitle: Column(
          children: question['option'].map<Widget>((option){
            return RadioListTile<String>(
              value: option.toString(),
              groupValue: null,
              onChanged: (value) {},
              title: Text(option.toString()),
            );
          }).toList(),
      ),
    );
  }

  Widget _buildLongTextQuestion(Map<String, dynamic> question){
    return ListTile(
      title: Text(question['question']),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: TextField(
          maxLines: 4,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Enter your answer"
          ),
        )
      ),
    );
  }
}
