import 'dart:convert';
import 'package:flutter/material.dart';

class TemplateDetail extends StatefulWidget {
  final int templateId;

  const TemplateDetail({Key? key, required this.templateId}) : super(key: key);

  @override
  _TemplateDetailState createState() => _TemplateDetailState();
}

class _TemplateDetailState extends State<TemplateDetail> {
  // menggunakan late supaya program menunggu sampai database benar-benar siap untuk fetch template form.
  late Map<String, dynamic> _templateData;

  @override
  void initState() {
    super.initState();
    _loadTemplateData();
  }


  void _loadTemplateData() {
    //masih static, belum fetch dari database
    String fetchedData = '''
      {"templateId":1,"title":"Drone Pre-Flight Checklist","questions":{"question1":{"question":"Is the drone's firmware updated?","type":"dropdown","options":["Yes","No","Not Applicable"],"required":true},"question2":{"question":"Inspect propellers for damage","type":"multiple","options":["No damage","Minor damage","Major damage","Needs replacement"],"required":true},"question3":{"question":"Battery charge level","type":"text","options":[],"required":true}}}
    ''';
    setState(() {
      //membaca data dari json ke UI menggunakan jsonDecode, kebalikan dari jsonEncode
      _templateData = jsonDecode(fetchedData);
    });
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
          ..._buildQuestions(_templateData['questions']),
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


// old code

// class _TemplateDetailState extends State<TemplateDetail> {
//   Map<String, dynamic>? _templateData;
//
//   void _loadTemplateData() async {
//     var templateData = await DatabaseHelper.getTemplateById(widget.templateId);
//     setState(() {
//       _templateData = templateData;
//     });
//   }
//
//   void _downloadTemplates() async {}
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     _loadTemplateData();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Template Detail")),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
//       floatingActionButton: Padding(
//         padding: const EdgeInsets.only(
//             bottom: 16.0), // Adjust bottom padding as needed
//         child: FloatingActionButton.extended(
//           onPressed: _downloadTemplates,
//           icon: const Icon(Icons.download_rounded),
//           label: const Text("Download Template"),
//         ),
//       ),
//       body: _templateData == null
//           ? const Center(
//               child: Text(
//                 "No Template Available Yet :(",
//                 style: TextStyle(fontSize: 18),
//               ),
//             )
//           : ListView(
//               children: [
//                 ListTile(
//                   title: Text(_templateData!['templateName'],
//                       style: TextStyle(fontSize: 18)),
//                   subtitle:
//                       Text("Template ID: ${_templateData!['templateId']}"),
//                 ),
//                 Divider(),
//                 ListTile(
//                   title: Text("Form Data:"),
//                   subtitle: Text(_templateData!['templateFormData']),
//                 )
//               ],
//             ),
//     );
//   }
// }