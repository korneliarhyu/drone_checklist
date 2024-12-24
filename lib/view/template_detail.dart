import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drone_checklist/database/database_helper.dart';
import 'package:drone_checklist/services/api_service.dart';
import 'package:flutter/material.dart';

class TemplateDetail extends StatefulWidget {
  final int templateId;

  const TemplateDetail({
    Key? key,
    required this.templateId
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

  // Fungsi ini untuk memuat data template dari database berdasarkan ID.
  Future<void> _loadTemplateData(int templateId) async {
    try{
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
        //menampung return API ke state _templateData;
        _templateData = templateData;
        _isLoading = false;
      });
    } catch (e){
      print("Error fetching template: $e");
      setState(() {
        _isLoading = false;
        _templateData = {};
      });
    }
  }

  Future<bool> _downloadTemplate(int templateId) async {
    try{
      await _loadTemplateData(templateId);

      if (_templateData.isEmpty) {
        print("Template data is empty or missing");
        return false;
      } else {
        String serializeForm = json.encode({
          'assesment': _templateData['assessment'],
          'pre': _templateData['pre'],
          'post': _templateData['post']
        });

        Map<String, dynamic> templateData = {
          'templateName': _templateData['templateName'],
          'formType': _templateData['formType'],
          'updatedDate': DateTime.now().toString(),
          'templateFormData': _templateData['templateFormData'],
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
        title: Text(_templateData['title']),
      ),
      body: _templateData.isEmpty
          ? const Center(child: Text('No template data available'))
          : ListView(
        children: [
          ListTile(
            title: Text(_templateData['title']),
            subtitle: Text("Template ID: ${_templateData['templateId']}"),
          ),
          //menggunakan spread Operator untuk memasukkan semua widget pertanyaan ke dalam ListView
          ..._buildQuestions(_templateData['questions']),
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

  List<Widget> _buildQuestions(Map<String, dynamic> questions) {
    List<Widget> questionWidgets = [];
    questions.forEach((key, value) {
      var question = value as Map<String, dynamic>;
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
      }
    });
    return questionWidgets;
  }

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
}